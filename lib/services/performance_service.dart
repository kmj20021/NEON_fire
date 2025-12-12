// lib/services/performance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neon_fire/models/performance_models.dart';

class PerformanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 기간별 성과 요약 조회
  Future<PerformanceSummary> getPerformanceSummary(
    String userId,
    PerformancePeriod period,
  ) async {
    try {
      final now = DateTime.now();
      final periodDays = period.days;
      final startDate = now.subtract(Duration(days: periodDays));
      final previousStartDate = startDate.subtract(Duration(days: periodDays));

      // 현재 기간 데이터
      final currentSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .get();

      // 이전 기간 데이터 (비교용)
      final previousSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(previousStartDate),
          )
          .where('startedAt', isLessThan: Timestamp.fromDate(startDate))
          .get();

      int workoutCount = currentSnapshot.docs.length;
      int totalDuration = 0;
      double totalVolume = 0;

      for (var doc in currentSnapshot.docs) {
        final data = doc.data();
        totalDuration += ((data['duration'] as int?) ?? 0) ~/ 60;
        totalVolume += (data['totalVolume'] as num?)?.toDouble() ?? 0;
      }

      // 이전 기간 계산
      int prevWorkoutCount = previousSnapshot.docs.length;
      int prevDuration = 0;
      double prevVolume = 0;

      for (var doc in previousSnapshot.docs) {
        final data = doc.data();
        prevDuration += ((data['duration'] as int?) ?? 0) ~/ 60;
        prevVolume += (data['totalVolume'] as num?)?.toDouble() ?? 0;
      }

      double volumeChange = prevVolume > 0
          ? ((totalVolume - prevVolume) / prevVolume * 100)
          : 0;

      return PerformanceSummary(
        workoutCount: workoutCount,
        totalDurationMinutes: totalDuration,
        totalVolume: totalVolume,
        volumeChangePercent: volumeChange,
        workoutCountChange: workoutCount - prevWorkoutCount,
        durationChangeMinutes: totalDuration - prevDuration,
      );
    } catch (e) {
      print('성과 요약 조회 실패: $e');
      return PerformanceSummary(
        workoutCount: 0,
        totalDurationMinutes: 0,
        totalVolume: 0,
        volumeChangePercent: 0,
        workoutCountChange: 0,
        durationChangeMinutes: 0,
      );
    }
  }

  /// 근력 운동 성과 조회
  Future<List<StrengthPerformance>> getStrengthPerformance(
    String userId,
    PerformancePeriod period,
  ) async {
    try {
      final now = DateTime.now();
      final periodDays = period.days;
      final startDate = now.subtract(Duration(days: periodDays));
      final previousStartDate = startDate.subtract(Duration(days: periodDays));

      // 현재 기간
      final currentSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .get();

      // 이전 기간
      final previousSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(previousStartDate),
          )
          .where('startedAt', isLessThan: Timestamp.fromDate(startDate))
          .get();

      Map<String, Map<String, dynamic>> currentExercises = {};
      Map<String, Map<String, dynamic>> previousExercises = {};

      // 현재 기간 운동 데이터 수집
      for (var doc in currentSnapshot.docs) {
        final exercisesSnapshot = await doc.reference
            .collection('exercises')
            .get();
        for (var exerciseDoc in exercisesSnapshot.docs) {
          final data = exerciseDoc.data();
          final name = data['exerciseName'] as String? ?? '';
          final exerciseId = data['exerciseId'] as int? ?? 0;

          if (name.isEmpty) continue;

          final setsSnapshot = await exerciseDoc.reference
              .collection('sets')
              .get();
          double maxWeight = 0;
          double totalVolume = 0;
          int maxReps = 0;

          for (var setDoc in setsSnapshot.docs) {
            final setData = setDoc.data();
            final weight = (setData['weight'] as num?)?.toDouble() ?? 0;
            final reps = (setData['reps'] as int?) ?? 0;

            if (weight > maxWeight) maxWeight = weight;
            if (reps > maxReps) maxReps = reps;
            totalVolume += weight * reps;
          }

          if (!currentExercises.containsKey(name)) {
            currentExercises[name] = {
              'id': exerciseId,
              'maxWeight': maxWeight,
              'maxVolume': totalVolume,
              'maxReps': maxReps,
            };
          } else {
            if (maxWeight > (currentExercises[name]!['maxWeight'] as double)) {
              currentExercises[name]!['maxWeight'] = maxWeight;
            }
            if (totalVolume >
                (currentExercises[name]!['maxVolume'] as double)) {
              currentExercises[name]!['maxVolume'] = totalVolume;
            }
            if (maxReps > (currentExercises[name]!['maxReps'] as int)) {
              currentExercises[name]!['maxReps'] = maxReps;
            }
          }
        }
      }

      // 이전 기간 운동 데이터 수집
      for (var doc in previousSnapshot.docs) {
        final exercisesSnapshot = await doc.reference
            .collection('exercises')
            .get();
        for (var exerciseDoc in exercisesSnapshot.docs) {
          final data = exerciseDoc.data();
          final name = data['exerciseName'] as String? ?? '';

          if (name.isEmpty) continue;

          final setsSnapshot = await exerciseDoc.reference
              .collection('sets')
              .get();
          double maxWeight = 0;

          for (var setDoc in setsSnapshot.docs) {
            final setData = setDoc.data();
            final weight = (setData['weight'] as num?)?.toDouble() ?? 0;
            if (weight > maxWeight) maxWeight = weight;
          }

          if (!previousExercises.containsKey(name)) {
            previousExercises[name] = {'maxWeight': maxWeight};
          } else {
            if (maxWeight > (previousExercises[name]!['maxWeight'] as double)) {
              previousExercises[name]!['maxWeight'] = maxWeight;
            }
          }
        }
      }

      // 결과 생성
      List<StrengthPerformance> results = [];
      currentExercises.forEach((name, data) {
        final maxWeight = data['maxWeight'] as double;
        final maxReps = data['maxReps'] as int;
        final prevMaxWeight =
            previousExercises[name]?['maxWeight'] as double? ?? maxWeight;

        // 1RM 추정 (Brzycki 공식)
        final estimated1RM = maxReps > 0
            ? maxWeight * (36 / (37 - maxReps))
            : maxWeight;
        final prev1RM = prevMaxWeight * 1.0; // 이전 1RM은 최대 무게로 추정

        results.add(
          StrengthPerformance(
            exerciseName: name,
            exerciseId: data['id'] as int,
            maxWeight: maxWeight,
            previousMaxWeight: prevMaxWeight,
            maxVolume: data['maxVolume'] as double,
            maxReps: maxReps,
            estimated1RM: estimated1RM,
            previous1RM: prev1RM,
          ),
        );
      });

      // 최고 무게 기준 정렬
      results.sort((a, b) => b.maxWeight.compareTo(a.maxWeight));
      return results.take(5).toList();
    } catch (e) {
      print('근력 성과 조회 실패: $e');
      return [];
    }
  }

  /// 개인 기록 (PR) 히스토리 조회
  Future<List<PRRecord>> getPRHistory(String userId, {int limit = 10}) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('personal_records')
          .orderBy('achievedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PRRecord(
          exerciseName: data['exerciseName'] ?? '',
          exerciseId: data['exerciseId'] ?? 0,
          recordType: data['recordType'] ?? 'weight',
          value: (data['newValue'] as num?)?.toDouble() ?? 0,
          previousValue: (data['previousValue'] as num?)?.toDouble() ?? 0,
          unit: data['unit'] ?? 'kg',
          achievedAt: (data['achievedAt'] as Timestamp).toDate(),
          isNew:
              DateTime.now()
                  .difference((data['achievedAt'] as Timestamp).toDate())
                  .inDays <
              7,
        );
      }).toList();
    } catch (e) {
      print('PR 히스토리 조회 실패: $e');
      return [];
    }
  }

  /// 목표 달성 기록 조회
  Future<GoalAchievement> getGoalAchievement(String userId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

      // 이번 주 운동 횟수
      final thisWeekSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart),
          )
          .get();

      // 최근 8주 데이터로 스트릭 계산
      List<bool> weeklyHistory = [];
      int currentStreak = 0;
      int bestStreak = 0;
      int tempStreak = 0;

      for (int i = 0; i < 8; i++) {
        final weekStartDate = now.subtract(
          Duration(days: now.weekday - 1 + (i * 7)),
        );
        final weekEndDate = weekStartDate.add(const Duration(days: 7));

        final weekSnapshot = await _db
            .collection('users')
            .doc(userId)
            .collection('workout_sessions')
            .where(
              'startedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStartDate),
            )
            .where('startedAt', isLessThan: Timestamp.fromDate(weekEndDate))
            .get();

        final achieved = weekSnapshot.docs.length >= 4; // 주 4회 목표
        weeklyHistory.add(achieved);

        if (achieved) {
          tempStreak++;
          if (tempStreak > bestStreak) bestStreak = tempStreak;
          if (i == 0) currentStreak = tempStreak;
        } else {
          if (i == 0) currentStreak = 0;
          tempStreak = 0;
        }
      }

      return GoalAchievement(
        goalType: 'weekly',
        targetCount: 4,
        achievedCount: thisWeekSnapshot.docs.length,
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        weeklyHistory: weeklyHistory.reversed.toList(),
      );
    } catch (e) {
      print('목표 달성 기록 조회 실패: $e');
      return GoalAchievement(
        goalType: 'weekly',
        targetCount: 4,
        achievedCount: 0,
        currentStreak: 0,
        bestStreak: 0,
        weeklyHistory: [],
      );
    }
  }

  /// 볼륨 & 강도 요약 조회
  Future<VolumeIntensitySummary> getVolumeIntensitySummary(
    String userId,
    PerformancePeriod period,
  ) async {
    try {
      final now = DateTime.now();
      final periodDays = period.days;
      final startDate = now.subtract(Duration(days: periodDays));
      final previousStartDate = startDate.subtract(Duration(days: periodDays));

      // 현재 기간
      final currentSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .orderBy('startedAt')
          .get();

      // 이전 기간
      final previousSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(previousStartDate),
          )
          .where('startedAt', isLessThan: Timestamp.fromDate(startDate))
          .get();

      List<VolumeIntensityData> weeklyData = [];
      double currentTotalVolume = 0;
      double currentTotalWeight = 0;
      int currentWeightCount = 0;

      for (var doc in currentSnapshot.docs) {
        final data = doc.data();
        final date = (data['startedAt'] as Timestamp).toDate();
        final volume = (data['totalVolume'] as num?)?.toDouble() ?? 0;

        currentTotalVolume += volume;

        // 세트별 무게 평균 계산
        final exercisesSnapshot = await doc.reference
            .collection('exercises')
            .get();
        for (var exerciseDoc in exercisesSnapshot.docs) {
          final setsSnapshot = await exerciseDoc.reference
              .collection('sets')
              .get();
          for (var setDoc in setsSnapshot.docs) {
            final weight = (setDoc.data()['weight'] as num?)?.toDouble() ?? 0;
            if (weight > 0) {
              currentTotalWeight += weight;
              currentWeightCount++;
            }
          }
        }

        weeklyData.add(
          VolumeIntensityData(
            date: date,
            totalVolume: volume,
            avgWeight: 0,
            avgRPE: 0,
          ),
        );
      }

      double prevTotalVolume = 0;
      double prevTotalWeight = 0;
      int prevWeightCount = 0;

      for (var doc in previousSnapshot.docs) {
        final data = doc.data();
        prevTotalVolume += (data['totalVolume'] as num?)?.toDouble() ?? 0;

        final exercisesSnapshot = await doc.reference
            .collection('exercises')
            .get();
        for (var exerciseDoc in exercisesSnapshot.docs) {
          final setsSnapshot = await exerciseDoc.reference
              .collection('sets')
              .get();
          for (var setDoc in setsSnapshot.docs) {
            final weight = (setDoc.data()['weight'] as num?)?.toDouble() ?? 0;
            if (weight > 0) {
              prevTotalWeight += weight;
              prevWeightCount++;
            }
          }
        }
      }

      final currentAvgWeight = currentWeightCount > 0
          ? currentTotalWeight / currentWeightCount
          : 0;
      final prevAvgWeight = prevWeightCount > 0
          ? prevTotalWeight / prevWeightCount
          : 0;

      final volumeChange = prevTotalVolume > 0
          ? ((currentTotalVolume - prevTotalVolume) / prevTotalVolume * 100)
          : 0;
      final weightChange = prevAvgWeight > 0
          ? ((currentAvgWeight - prevAvgWeight) / prevAvgWeight * 100)
          : 0;

      return VolumeIntensitySummary(
        weeklyData: weeklyData,
        avgWeightChangePercent: weightChange.toDouble(),
        totalVolumeChangePercent: volumeChange.toDouble(),
        currentAvgWeight: currentAvgWeight.toDouble(),
        previousAvgWeight: prevAvgWeight.toDouble(),
      );
    } catch (e) {
      print('볼륨 강도 요약 조회 실패: $e');
      return VolumeIntensitySummary(
        weeklyData: [],
        avgWeightChangePercent: 0,
        totalVolumeChangePercent: 0,
        currentAvgWeight: 0,
        previousAvgWeight: 0,
      );
    }
  }

  /// 부위별 성장 지표 조회
  Future<List<BodyPartGrowth>> getBodyPartGrowth(
    String userId,
    PerformancePeriod period,
  ) async {
    try {
      final now = DateTime.now();
      final periodDays = period.days;
      final startDate = now.subtract(Duration(days: periodDays));
      final previousStartDate = startDate.subtract(Duration(days: periodDays));

      // 부위 매핑
      Map<String, List<String>> bodyPartMapping = {
        '상체': ['가슴', '등', '어깨', '팔', '이두', '삼두'],
        '하체': ['하체', '대퇴', '종아리', '둔근'],
        '코어': ['복근', '코어', '허리'],
      };

      Map<String, Map<String, dynamic>> currentData = {
        '상체': {'count': 0, 'volume': 0.0},
        '하체': {'count': 0, 'volume': 0.0},
        '코어': {'count': 0, 'volume': 0.0},
      };

      Map<String, Map<String, dynamic>> previousData = {
        '상체': {'count': 0, 'volume': 0.0},
        '하체': {'count': 0, 'volume': 0.0},
        '코어': {'count': 0, 'volume': 0.0},
      };

      // 현재 기간 데이터
      final currentSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .get();

      for (var doc in currentSnapshot.docs) {
        final exercisesSnapshot = await doc.reference
            .collection('exercises')
            .get();
        for (var exerciseDoc in exercisesSnapshot.docs) {
          final data = exerciseDoc.data();
          final muscleGroup = data['muscleGroup'] as String? ?? '';

          for (var entry in bodyPartMapping.entries) {
            if (entry.value.any((m) => muscleGroup.contains(m))) {
              currentData[entry.key]!['count'] =
                  (currentData[entry.key]!['count'] as int) + 1;

              final setsSnapshot = await exerciseDoc.reference
                  .collection('sets')
                  .get();
              for (var setDoc in setsSnapshot.docs) {
                final setData = setDoc.data();
                final weight = (setData['weight'] as num?)?.toDouble() ?? 0;
                final reps = (setData['reps'] as int?) ?? 0;
                currentData[entry.key]!['volume'] =
                    (currentData[entry.key]!['volume'] as double) +
                    (weight * reps);
              }
              break;
            }
          }
        }
      }

      // 이전 기간 데이터
      final previousSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(previousStartDate),
          )
          .where('startedAt', isLessThan: Timestamp.fromDate(startDate))
          .get();

      for (var doc in previousSnapshot.docs) {
        final exercisesSnapshot = await doc.reference
            .collection('exercises')
            .get();
        for (var exerciseDoc in exercisesSnapshot.docs) {
          final data = exerciseDoc.data();
          final muscleGroup = data['muscleGroup'] as String? ?? '';

          for (var entry in bodyPartMapping.entries) {
            if (entry.value.any((m) => muscleGroup.contains(m))) {
              previousData[entry.key]!['count'] =
                  (previousData[entry.key]!['count'] as int) + 1;

              final setsSnapshot = await exerciseDoc.reference
                  .collection('sets')
                  .get();
              for (var setDoc in setsSnapshot.docs) {
                final setData = setDoc.data();
                final weight = (setData['weight'] as num?)?.toDouble() ?? 0;
                final reps = (setData['reps'] as int?) ?? 0;
                previousData[entry.key]!['volume'] =
                    (previousData[entry.key]!['volume'] as double) +
                    (weight * reps);
              }
              break;
            }
          }
        }
      }

      List<BodyPartGrowth> results = [];

      for (var bodyPart in ['상체', '하체', '코어']) {
        final currentVolume = currentData[bodyPart]!['volume'] as double;
        final prevVolume = previousData[bodyPart]!['volume'] as double;
        final count = currentData[bodyPart]!['count'] as int;

        double volumeChange = prevVolume > 0
            ? ((currentVolume - prevVolume) / prevVolume * 100)
            : 0;

        GrowthStatus status;
        String recommendation;

        if (volumeChange > 20 && count >= 3) {
          status = GrowthStatus.excellent;
          recommendation = '훌륭합니다! 현재 페이스를 유지하세요.';
        } else if (volumeChange > 10 || count >= 2) {
          status = GrowthStatus.good;
          recommendation = '잘하고 있어요! 조금만 더 힘내세요.';
        } else if (volumeChange >= -10 && count >= 1) {
          status = GrowthStatus.maintain;
          recommendation = '운동 빈도를 조금 늘려보세요.';
        } else if (count > 0) {
          status = GrowthStatus.lacking;
          recommendation = '이 부위 운동을 더 추가해보세요.';
        } else {
          status = GrowthStatus.needsAttention;
          recommendation = '이 부위 운동이 필요합니다!';
        }

        results.add(
          BodyPartGrowth(
            bodyPart: bodyPart,
            status: status,
            workoutCount: count,
            volumeChangePercent: volumeChange,
            recommendation: recommendation,
          ),
        );
      }

      return results;
    } catch (e) {
      print('부위별 성장 지표 조회 실패: $e');
      return [];
    }
  }

  /// 일관성 점수 계산
  Future<ConsistencyScore> getConsistencyScore(
    String userId,
    PerformancePeriod period,
  ) async {
    try {
      final now = DateTime.now();
      final periodDays = period.days;
      final startDate = now.subtract(Duration(days: periodDays));

      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .orderBy('startedAt')
          .get();

      // 운동 날짜 수집
      Set<String> workoutDates = {};
      List<DateTime> workoutDateTimes = [];

      for (var doc in snapshot.docs) {
        final date = (doc.data()['startedAt'] as Timestamp).toDate();
        final dateStr = '${date.year}-${date.month}-${date.day}';
        workoutDates.add(dateStr);
        workoutDateTimes.add(date);
      }

      // 목표 운동일 계산 (주 4회 기준)
      final weeks = periodDays / 7;
      final plannedDays = (weeks * 4).round();
      final actualDays = workoutDates.length;

      // 계획 대비 실천률
      final planVsActual = plannedDays > 0
          ? (actualDays / plannedDays * 100)
          : 0;

      // 운동 간격 규칙성 계산
      double intervalRegularity = 100;
      if (workoutDateTimes.length > 1) {
        workoutDateTimes.sort();
        List<int> intervals = [];
        for (int i = 1; i < workoutDateTimes.length; i++) {
          intervals.add(
            workoutDateTimes[i].difference(workoutDateTimes[i - 1]).inDays,
          );
        }

        // 이상적인 간격은 2일
        double avgInterval =
            intervals.reduce((a, b) => a + b) / intervals.length;
        double deviation =
            intervals
                .map((i) => (i - avgInterval).abs())
                .reduce((a, b) => a + b) /
            intervals.length;
        intervalRegularity = (100 - (deviation * 10)).clamp(0, 100);
      }

      // 최종 점수 계산
      int score = ((planVsActual * 0.6) + (intervalRegularity * 0.4))
          .round()
          .clamp(0, 100);

      String message;
      if (score >= 80) {
        message = '꾸준히 잘하고 있어요! 👏';
      } else if (score >= 60) {
        message = '조금만 더 규칙적으로 운동해보세요!';
      } else if (score >= 40) {
        message = '운동 빈도를 늘려보는 건 어떨까요?';
      } else {
        message = '다시 운동 습관을 만들어봐요! 💪';
      }

      return ConsistencyScore(
        score: score,
        planVsActualPercent: planVsActual.toDouble(),
        intervalRegularity: intervalRegularity,
        totalPlannedDays: plannedDays,
        actualWorkoutDays: actualDays,
        message: message,
      );
    } catch (e) {
      print('일관성 점수 계산 실패: $e');
      return ConsistencyScore(
        score: 0,
        planVsActualPercent: 0,
        intervalRegularity: 0,
        totalPlannedDays: 0,
        actualWorkoutDays: 0,
        message: '데이터를 불러올 수 없습니다.',
      );
    }
  }

  /// 과거 나 vs 현재 나 비교
  Future<SelfComparison> getSelfComparison(
    String userId, {
    int monthsAgo = 3,
  }) async {
    try {
      final now = DateTime.now();
      final currentStart = now.subtract(const Duration(days: 30));
      final previousStart = now.subtract(Duration(days: 30 + (monthsAgo * 30)));
      final previousEnd = now.subtract(Duration(days: monthsAgo * 30));

      // 현재 기간 (최근 30일)
      final currentSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(currentStart),
          )
          .get();

      // 과거 기간 (n개월 전 30일)
      final previousSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(previousStart),
          )
          .where('startedAt', isLessThan: Timestamp.fromDate(previousEnd))
          .get();

      int currentCount = currentSnapshot.docs.length;
      int previousCount = previousSnapshot.docs.length;
      double currentVolume = 0;
      double previousVolume = 0;
      double currentMaxWeight = 0;
      double previousMaxWeight = 0;
      int currentDuration = 0;
      int previousDuration = 0;

      for (var doc in currentSnapshot.docs) {
        final data = doc.data();
        currentVolume += (data['totalVolume'] as num?)?.toDouble() ?? 0;
        currentDuration += ((data['duration'] as int?) ?? 0) ~/ 60;

        final exercisesSnapshot = await doc.reference
            .collection('exercises')
            .get();
        for (var exerciseDoc in exercisesSnapshot.docs) {
          final setsSnapshot = await exerciseDoc.reference
              .collection('sets')
              .get();
          for (var setDoc in setsSnapshot.docs) {
            final weight = (setDoc.data()['weight'] as num?)?.toDouble() ?? 0;
            if (weight > currentMaxWeight) currentMaxWeight = weight;
          }
        }
      }

      for (var doc in previousSnapshot.docs) {
        final data = doc.data();
        previousVolume += (data['totalVolume'] as num?)?.toDouble() ?? 0;
        previousDuration += ((data['duration'] as int?) ?? 0) ~/ 60;

        final exercisesSnapshot = await doc.reference
            .collection('exercises')
            .get();
        for (var exerciseDoc in exercisesSnapshot.docs) {
          final setsSnapshot = await exerciseDoc.reference
              .collection('sets')
              .get();
          for (var setDoc in setsSnapshot.docs) {
            final weight = (setDoc.data()['weight'] as num?)?.toDouble() ?? 0;
            if (weight > previousMaxWeight) previousMaxWeight = weight;
          }
        }
      }

      double freqChange = previousCount > 0
          ? ((currentCount - previousCount) / previousCount * 100)
          : 0;
      double volumeChange = previousVolume > 0
          ? ((currentVolume - previousVolume) / previousVolume * 100)
          : 0;

      return SelfComparison(
        monthsAgo: monthsAgo,
        workoutFrequencyChange: freqChange,
        maxWeightChange: currentMaxWeight - previousMaxWeight,
        totalVolumeChange: volumeChange,
        avgDurationChange: previousCount > 0 && currentCount > 0
            ? (currentDuration / currentCount) -
                  (previousDuration / previousCount)
            : 0,
        previousWorkoutCount: previousCount,
        currentWorkoutCount: currentCount,
      );
    } catch (e) {
      print('자기 비교 조회 실패: $e');
      return SelfComparison(
        monthsAgo: monthsAgo,
        workoutFrequencyChange: 0,
        maxWeightChange: 0,
        totalVolumeChange: 0,
        avgDurationChange: 0,
        previousWorkoutCount: 0,
        currentWorkoutCount: 0,
      );
    }
  }

  /// 성과 요약 코멘트 자동 생성
  Future<PerformanceComment> generatePerformanceComment(
    String userId,
    PerformancePeriod period,
  ) async {
    try {
      final summary = await getPerformanceSummary(userId, period);
      final bodyPartGrowth = await getBodyPartGrowth(userId, period);
      final consistency = await getConsistencyScore(userId, period);

      List<String> highlights = [];
      String content = '';
      String suggestion = '';

      // 하이라이트 수집
      if (summary.volumeChangePercent > 10) {
        highlights.add(
          '볼륨 ${summary.volumeChangePercent.toStringAsFixed(0)}% 증가',
        );
      }
      if (summary.workoutCountChange > 0) {
        highlights.add('운동 횟수 ${summary.workoutCountChange}회 증가');
      }

      // 가장 성장한 부위 찾기
      BodyPartGrowth? bestGrowth;
      for (var growth in bodyPartGrowth) {
        if (bestGrowth == null ||
            growth.volumeChangePercent > bestGrowth.volumeChangePercent) {
          bestGrowth = growth;
        }
      }

      if (bestGrowth != null && bestGrowth.volumeChangePercent > 0) {
        content = '${bestGrowth.bodyPart} 운동 비중이 늘면서 기록이 빠르게 성장 중이에요.';
        highlights.add('${bestGrowth.bodyPart} 성장 우수');
      } else {
        content = '꾸준히 운동하고 있어요. 조금만 더 힘내세요!';
      }

      // 제안 생성
      if (consistency.score < 60) {
        suggestion = '운동 일관성을 높이면 더 빠른 성장을 기대할 수 있어요.';
      } else if (summary.volumeChangePercent < 0) {
        suggestion = '운동 볼륨을 조금씩 늘려보세요.';
      } else {
        suggestion = '현재 페이스를 유지하면 좋은 결과가 있을 거예요!';
      }

      return PerformanceComment(
        title: '📈 ${period.label} 요약',
        content: content,
        highlights: highlights,
        suggestion: suggestion,
      );
    } catch (e) {
      print('성과 코멘트 생성 실패: $e');
      return PerformanceComment(
        title: '📈 성과 요약',
        content: '열심히 운동하고 있어요!',
        highlights: [],
        suggestion: '꾸준함이 가장 중요해요!',
      );
    }
  }
}
