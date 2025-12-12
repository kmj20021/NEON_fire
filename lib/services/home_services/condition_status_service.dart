// lib/services/home_services/condition_status_service.dart
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neon_fire/models/home_models/condition_status_model.dart';

class ConditionStatusService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 오늘의 컨디션 점수 계산
  Future<ConditionScore> calculateConditionScore(String userId) async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final fourteenDaysAgo = now.subtract(const Duration(days: 14));

      // 최근 7일 운동 세션 조회
      final recentSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
          )
          .get();

      // 7-14일 전 운동 세션 조회 (비교용)
      final previousSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fourteenDaysAgo),
          )
          .where('startedAt', isLessThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      // 휴식일 계산
      Set<String> workoutDates = {};
      double recentVolume = 0;
      int consecutiveHighIntensityDays = 0;
      Map<String, int> muscleRecoveryStatus = {};

      for (var doc in recentSnapshot.docs) {
        final data = doc.data();
        final startedAt = (data['startedAt'] as Timestamp).toDate();
        final dateStr = '${startedAt.year}-${startedAt.month}-${startedAt.day}';
        workoutDates.add(dateStr);
        recentVolume += (data['totalVolume'] as num?)?.toDouble() ?? 0;
      }

      final restDays = 7 - workoutDates.length;

      // 이전 주 평균 볼륨
      double previousVolume = 0;
      for (var doc in previousSnapshot.docs) {
        final data = doc.data();
        previousVolume += (data['totalVolume'] as num?)?.toDouble() ?? 0;
      }
      final avgVolume = previousVolume > 0 ? previousVolume : recentVolume;

      // 연속 고강도 훈련일 계산
      List<DateTime> sortedDates = [];
      for (var doc in recentSnapshot.docs) {
        final data = doc.data();
        final startedAt = (data['startedAt'] as Timestamp).toDate();
        sortedDates.add(startedAt);
      }
      sortedDates.sort((a, b) => b.compareTo(a));

      if (sortedDates.isNotEmpty) {
        consecutiveHighIntensityDays = 1;
        for (int i = 1; i < sortedDates.length; i++) {
          final diff = sortedDates[i - 1].difference(sortedDates[i]).inDays;
          if (diff <= 1) {
            consecutiveHighIntensityDays++;
          } else {
            break;
          }
        }
      }

      // 부위별 회복 상태 조회
      muscleRecoveryStatus = await _getMuscleRecoveryDays(userId);

      return ConditionScore.calculate(
        restDays: restDays,
        recentVolume: recentVolume,
        avgVolume: avgVolume,
        consecutiveHighIntensityDays: consecutiveHighIntensityDays,
        muscleRecoveryStatus: muscleRecoveryStatus,
      );
    } catch (e) {
      print('컨디션 점수 계산 실패: $e');
      return ConditionScore(
        score: 70,
        status: '양호',
        statusColor: const Color(0xFFFFC107),
        recommendation: '데이터를 불러오는 중 오류가 발생했습니다.',
        factors: [],
      );
    }
  }

  /// 부위별 마지막 운동일 조회
  Future<Map<String, int>> _getMuscleRecoveryDays(String userId) async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
          )
          .orderBy('startedAt', descending: true)
          .get();

      Map<String, DateTime> lastWorkoutByMuscle = {};

      for (var doc in snapshot.docs) {
        final exercisesSnapshot = await doc.reference
            .collection('exercises')
            .get();
        final startedAt = (doc.data()['startedAt'] as Timestamp).toDate();

        for (var exerciseDoc in exercisesSnapshot.docs) {
          final muscleName =
              exerciseDoc.data()['muscleGroup'] as String? ?? '기타';
          if (!lastWorkoutByMuscle.containsKey(muscleName)) {
            lastWorkoutByMuscle[muscleName] = startedAt;
          }
        }
      }

      Map<String, int> result = {};
      lastWorkoutByMuscle.forEach((muscle, lastDate) {
        result[muscle] = now.difference(lastDate).inDays;
      });

      return result;
    } catch (e) {
      print('부위별 회복일 조회 실패: $e');
      return {};
    }
  }

  /// 부위별 회복 상태 조회
  Future<List<MuscleRecoveryStatus>> getMuscleRecoveryStatus(
    String userId,
  ) async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
          )
          .orderBy('startedAt', descending: true)
          .get();

      Map<String, Map<String, dynamic>> muscleData = {};

      for (var doc in snapshot.docs) {
        final exercisesSnapshot = await doc.reference
            .collection('exercises')
            .get();
        final startedAt = (doc.data()['startedAt'] as Timestamp).toDate();

        for (var exerciseDoc in exercisesSnapshot.docs) {
          final data = exerciseDoc.data();
          final muscleName = data['muscleGroup'] as String? ?? '기타';
          final exerciseName = data['exerciseName'] as String? ?? '';

          if (!muscleData.containsKey(muscleName)) {
            muscleData[muscleName] = {
              'lastDate': startedAt,
              'lastExercise': exerciseName,
              'workoutCount': 1,
            };
          } else {
            muscleData[muscleName]!['workoutCount'] =
                (muscleData[muscleName]!['workoutCount'] as int) + 1;
          }
        }
      }

      List<MuscleRecoveryStatus> result = [];

      // 주요 근육 그룹 목록
      final mainMuscles = ['가슴', '등', '어깨', '하체', '팔', '복근', '코어'];

      for (var muscle in mainMuscles) {
        if (muscleData.containsKey(muscle)) {
          final data = muscleData[muscle]!;
          final lastDate = data['lastDate'] as DateTime;
          final daysSince = now.difference(lastDate).inDays;
          final workoutCount = data['workoutCount'] as int;

          RecoveryLevel level;
          if (daysSince >= 3) {
            level = RecoveryLevel.fullyRecovered;
          } else if (daysSince == 2) {
            level = RecoveryLevel.recovered;
          } else if (daysSince == 1) {
            level = RecoveryLevel.recovering;
          } else if (workoutCount >= 2) {
            level = RecoveryLevel.needsRest;
          } else {
            level = RecoveryLevel.fatigued;
          }

          result.add(
            MuscleRecoveryStatus(
              muscleName: muscle,
              daysSinceLastWorkout: daysSince,
              recoveryLevel: level,
              lastExerciseName: data['lastExercise'] as String?,
            ),
          );
        } else {
          result.add(
            MuscleRecoveryStatus(
              muscleName: muscle,
              daysSinceLastWorkout: 999,
              recoveryLevel: RecoveryLevel.fullyRecovered,
              lastExerciseName: null,
            ),
          );
        }
      }

      // 회복이 덜 된 순서로 정렬
      result.sort(
        (a, b) => a.daysSinceLastWorkout.compareTo(b.daysSinceLastWorkout),
      );

      return result;
    } catch (e) {
      print('부위별 회복 상태 조회 실패: $e');
      return [];
    }
  }

  /// 최근 7일 운동 요약
  Future<WeeklyStatusSummary> getWeeklyStatusSummary(String userId) async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final fourteenDaysAgo = now.subtract(const Duration(days: 14));

      // 이번 주
      final thisWeekSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
          )
          .get();

      // 지난 주
      final lastWeekSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fourteenDaysAgo),
          )
          .where('startedAt', isLessThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      Set<String> workoutDates = {};
      int totalDuration = 0;
      double totalVolume = 0;
      int cardioMinutes = 0;

      for (var doc in thisWeekSnapshot.docs) {
        final data = doc.data();
        final startedAt = (data['startedAt'] as Timestamp).toDate();
        workoutDates.add(
          '${startedAt.year}-${startedAt.month}-${startedAt.day}',
        );
        totalDuration += (data['duration'] as int? ?? 0) ~/ 60; // 초를 분으로
        totalVolume += (data['totalVolume'] as num?)?.toDouble() ?? 0;
      }

      // 지난 주 볼륨
      double lastWeekVolume = 0;
      for (var doc in lastWeekSnapshot.docs) {
        final data = doc.data();
        lastWeekVolume += (data['totalVolume'] as num?)?.toDouble() ?? 0;
      }

      double volumeChange = 0;
      if (lastWeekVolume > 0) {
        volumeChange = ((totalVolume - lastWeekVolume) / lastWeekVolume * 100);
      }

      return WeeklyStatusSummary(
        workoutCount: thisWeekSnapshot.docs.length,
        totalDuration: totalDuration,
        totalVolume: totalVolume,
        cardioMinutes: cardioMinutes,
        restDays: 7 - workoutDates.length,
        volumeChangePercent: volumeChange,
      );
    } catch (e) {
      print('주간 요약 조회 실패: $e');
      return WeeklyStatusSummary(
        workoutCount: 0,
        totalDuration: 0,
        totalVolume: 0,
        cardioMinutes: 0,
        restDays: 7,
        volumeChangePercent: 0,
      );
    }
  }

  /// 목표 진행률 조회
  Future<List<GoalProgress>> getGoalProgress(String userId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // 이번 주 운동 횟수
      final weekSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart),
          )
          .get();

      // 이번 달 운동 시간
      final monthSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
          .get();

      int monthlyMinutes = 0;
      for (var doc in monthSnapshot.docs) {
        monthlyMinutes += ((doc.data()['duration'] as int? ?? 0) ~/ 60);
      }

      return [
        GoalProgress(
          goalType: '주간 운동 횟수',
          current: weekSnapshot.docs.length,
          target: 4, // 기본 목표: 주 4회
          unit: '회',
        ),
        GoalProgress(
          goalType: '월간 운동 시간',
          current: monthlyMinutes,
          target: 600, // 기본 목표: 월 10시간
          unit: '분',
        ),
      ];
    } catch (e) {
      print('목표 진행률 조회 실패: $e');
      return [];
    }
  }

  /// 최근 PR(개인기록) 조회
  Future<List<PersonalRecord>> getRecentPRs(
    String userId, {
    int days = 7,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('personal_records')
          .where(
            'achievedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .orderBy('achievedAt', descending: true)
          .limit(5)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PersonalRecord(
          exerciseName: data['exerciseName'] ?? '',
          recordType: data['recordType'] ?? '무게',
          previousValue: (data['previousValue'] as num?)?.toDouble() ?? 0,
          newValue: (data['newValue'] as num?)?.toDouble() ?? 0,
          achievedAt: (data['achievedAt'] as Timestamp).toDate(),
          unit: data['unit'] ?? 'kg',
        );
      }).toList();
    } catch (e) {
      print('PR 조회 실패: $e');
      return [];
    }
  }

  /// 위험 신호 분석
  Future<List<WarningAlert>> analyzeWarnings(String userId) async {
    try {
      List<WarningAlert> warnings = [];

      final conditionScore = await calculateConditionScore(userId);
      final muscleStatus = await getMuscleRecoveryStatus(userId);
      final weeklySummary = await getWeeklyStatusSummary(userId);

      // 1. 과훈련 경고
      if (conditionScore.score < 40) {
        warnings.add(
          WarningAlert(
            type: WarningType.overtraining,
            message: '과훈련 위험',
            suggestion: '최소 1-2일 휴식을 취하세요.',
          ),
        );
      }

      // 2. 휴식 없음 경고
      if (weeklySummary.restDays == 0) {
        warnings.add(
          WarningAlert(
            type: WarningType.noRest,
            message: '최근 7일간 휴식 없음',
            suggestion: '근육 회복을 위해 휴식일을 가지세요.',
          ),
        );
      }

      // 3. 특정 부위 과부하 경고
      for (var muscle in muscleStatus) {
        if (muscle.recoveryLevel == RecoveryLevel.needsRest) {
          warnings.add(
            WarningAlert(
              type: WarningType.muscleOverload,
              message: '${muscle.muscleName} 과부하',
              suggestion: '${muscle.muscleName} 휴식을 권장합니다.',
            ),
          );
        }
      }

      // 4. 볼륨 급증 경고
      if (weeklySummary.volumeChangePercent > 50) {
        warnings.add(
          WarningAlert(
            type: WarningType.volumeSpike,
            message:
                '운동량 급증 (${weeklySummary.volumeChangePercent.toStringAsFixed(0)}% 증가)',
            suggestion: '점진적으로 운동량을 늘리세요.',
          ),
        );
      }

      return warnings;
    } catch (e) {
      print('위험 신호 분석 실패: $e');
      return [];
    }
  }

  /// 상태 기반 운동 추천
  Future<WorkoutRecommendation> getWorkoutRecommendation(String userId) async {
    try {
      final conditionScore = await calculateConditionScore(userId);
      final muscleStatus = await getMuscleRecoveryStatus(userId);

      // 회복된 근육 찾기
      List<String> recoveredMuscles = muscleStatus
          .where(
            (m) =>
                m.recoveryLevel == RecoveryLevel.fullyRecovered ||
                m.recoveryLevel == RecoveryLevel.recovered,
          )
          .map((m) => m.muscleName)
          .toList();

      if (conditionScore.score < 40) {
        return WorkoutRecommendation(
          title: '휴식 권장',
          description: '오늘은 충분한 휴식을 취하세요. 가벼운 스트레칭만 권장합니다.',
          suggestedMuscles: [],
          suggestedDuration: 0,
          intensity: '휴식',
        );
      } else if (conditionScore.score < 60) {
        return WorkoutRecommendation(
          title: '가벼운 회복 운동',
          description: '가벼운 유산소나 스트레칭을 추천합니다.',
          suggestedMuscles: [],
          suggestedDuration: 20,
          intensity: '저',
        );
      } else if (conditionScore.score < 80) {
        return WorkoutRecommendation(
          title: '중강도 운동 추천',
          description: recoveredMuscles.isNotEmpty
              ? '${recoveredMuscles.take(2).join(", ")} 운동을 추천합니다.'
              : '가벼운 전신 운동을 추천합니다.',
          suggestedMuscles: recoveredMuscles.take(2).toList(),
          suggestedDuration: 45,
          intensity: '중',
        );
      } else {
        return WorkoutRecommendation(
          title: '컨디션 최고! 고강도 운동 가능',
          description: recoveredMuscles.isNotEmpty
              ? '${recoveredMuscles.take(3).join(", ")} 운동을 추천합니다.'
              : '원하는 부위 운동을 시작하세요!',
          suggestedMuscles: recoveredMuscles.take(3).toList(),
          suggestedDuration: 60,
          intensity: '고',
        );
      }
    } catch (e) {
      print('운동 추천 실패: $e');
      return WorkoutRecommendation(
        title: '운동 시작하기',
        description: '오늘도 화이팅!',
        suggestedMuscles: [],
        suggestedDuration: 45,
        intensity: '중',
      );
    }
  }

  /// 주관적 컨디션 로그 저장
  Future<bool> saveConditionLog(
    String userId,
    ConditionFeeling feeling,
    String? comment,
  ) async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await _db
          .collection('users')
          .doc(userId)
          .collection('condition_logs')
          .doc(dateStr)
          .set({
            'date': Timestamp.fromDate(now),
            'feeling': feeling.index,
            'comment': comment,
            'createdAt': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      print('컨디션 로그 저장 실패: $e');
      return false;
    }
  }

  /// 오늘의 컨디션 로그 조회
  Future<SubjectiveConditionLog?> getTodayConditionLog(String userId) async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('condition_logs')
          .doc(dateStr)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return SubjectiveConditionLog(
          date: (data['date'] as Timestamp).toDate(),
          feeling: ConditionFeeling.values[data['feeling'] ?? 1],
          comment: data['comment'],
        );
      }
      return null;
    } catch (e) {
      print('오늘 컨디션 로그 조회 실패: $e');
      return null;
    }
  }
}
