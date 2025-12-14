import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neon_fire/models/home_models/workout_stats_model.dart';

class WorkoutStatsService {
  // 싱글톤 패턴
  static final WorkoutStatsService _instance = WorkoutStatsService._internal();
  factory WorkoutStatsService() => _instance;
  WorkoutStatsService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 캐싱
  List<WeeklyWorkoutData>? _cachedWeeklyData;
  WeeklyWorkoutSummary? _cachedWeeklySummary;
  DateTime? _cacheTime;
  DateTime? _lastWorkoutCheckTime;
  String? _cachedUserId;

  /// 마지막 확인 이후 새로운 운동이 있는지 확인
  Future<bool> _hasNewWorkoutSince(String userId, DateTime since) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('workout_sessions')
        .where(
          'startedAt',
          isGreaterThan: Timestamp.fromDate(since),
        )
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// 이번 달 운동 캘린더 데이터 가져오기
  Future<Map<DateTime, int>> getMonthlyWorkoutData(String userId) async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
          .where('startedAt', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
          .get();

      final Map<DateTime, int> workoutMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final startedAt = (data['startedAt'] as Timestamp).toDate();
        final dateOnly = DateTime(
          startedAt.year,
          startedAt.month,
          startedAt.day,
        );
        final duration = data['duration'] as int? ?? 0;

        // 같은 날의 운동을 모두 합산
        workoutMap[dateOnly] = (workoutMap[dateOnly] ?? 0) + duration;
      }

      return workoutMap;
    } catch (e) {
      print('월간 운동 데이터 조회 실패: $e');
      return {};
    }
  }

  /// 이번 주 운동 데이터 가져오기 (차트용)
  Future<List<WeeklyWorkoutData>> getWeeklyWorkoutData(String userId) async {
    try {
      print('📊 [주간차트] 캐시 체크: ${_cachedWeeklyData != null ? "있음" : "없음"}');
      
      // 캐시 확인
      if (_cachedWeeklyData != null && 
          _cachedUserId == userId && 
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < const Duration(hours: 24)) {
        
        // 새로운 운동 확인
        if (_lastWorkoutCheckTime != null) {
          final hasNewWorkout = await _hasNewWorkoutSince(userId, _lastWorkoutCheckTime!);
          if (!hasNewWorkout) {
            print('✅ [주간차트] 캐시 사용 (즉시 반환)');
            return _cachedWeeklyData!;
          } else {
            print('🆕 [주간차트] 새 운동 발견, 재계산');
          }
        }
      } else {
        print('❌ [주간차트] 캐시 무효 또는 첫 실행');
      }

      final now = DateTime.now();
      // 이번 주 월요일 계산 (weekday: 월=1, 일=7)
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      );
      final endOfWeek = startOfWeek.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );

      print('📅 주간 데이터 조회 범위: ${startOfWeek} ~ ${endOfWeek}');

      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
          )
          .where(
            'startedAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek),
          )
          .get();

      print('📊 조회된 세션 개수: ${snapshot.docs.length}');

      // 요일별로 그룹화
      final Map<int, int> dayWorkout = {
        0: 0, // 월
        1: 0, // 화
        2: 0, // 수
        3: 0, // 목
        4: 0, // 금
        5: 0, // 토
        6: 0, // 일
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final startedAt = (data['startedAt'] as Timestamp).toDate();
        final duration = data['duration'] as int? ?? 0; // 초 단위

        // 요일 계산 (월=0, 일=6)
        final dayOfWeek = (startedAt.weekday - 1) % 7;
        dayWorkout[dayOfWeek] = (dayWorkout[dayOfWeek] ?? 0) + duration;

        print(
          '  운동 기록: ${startedAt} (${['월', '화', '수', '목', '금', '토', '일'][dayOfWeek]}) - ${duration}초 = ${(duration / 60).toStringAsFixed(1)}분',
        );
      }

      // 결과 변환 (초 → 분)
      const weekDays = ['월', '화', '수', '목', '금', '토', '일'];
      final result = List.generate(
        7,
        (index) => WeeklyWorkoutData(
          day: weekDays[index],
          minutes: ((dayWorkout[index] ?? 0) / 60).round(), // 초를 분으로 변환
        ),
      );

      // 캐시 저장
      _cachedWeeklyData = result;
      _cachedUserId = userId;
      _cacheTime = DateTime.now();
      _lastWorkoutCheckTime = DateTime.now();

      print('✅ [주간차트] 데이터 결과 및 캐시 저장:');
      for (var i = 0; i < result.length; i++) {
        print('   ${result[i].day}: ${result[i].minutes}분');
      }

      return result;
    } catch (e) {
      print('❌ 주간 운동 데이터 조회 실패: $e');
      // 캐시가 있으면 반환
      if (_cachedWeeklyData != null) {
        return _cachedWeeklyData!;
      }
      // 기본값 반환
      const weekDays = ['월', '화', '수', '목', '금', '토', '일'];
      return List.generate(
        7,
        (index) => WeeklyWorkoutData(day: weekDays[index], minutes: 0),
      );
    }
  }

  /// 오늘부터 역순 N일의 워크아웃 데이터
  Future<List<WorkoutStats>> getRecentWorkoutStats(
    String userId, {
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .orderBy('startedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WorkoutStats.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('최근 운동 통계 조회 실패: $e');
      return [];
    }
  }

  /// 주간 총 운동 시간
  Future<int> getWeeklyTotalDuration(String userId) async {
    try {
      final weekData = await getWeeklyWorkoutData(userId);
      return weekData.fold<int>(0, (sum, data) => sum + data.minutes);
    } catch (e) {
      print('주간 총 운동 시간 조회 실패: $e');
      return 0;
    }
  }

  /// 월간 총 운동 시간
  Future<int> getMonthlyTotalDuration(String userId) async {
    try {
      final monthData = await getMonthlyWorkoutData(userId);
      return monthData.values.fold<int>(0, (sum, minutes) => sum + minutes);
    } catch (e) {
      print('월간 총 운동 시간 조회 실패: $e');
      return 0;
    }
  }

  /// 연속 운동일 계산
  Future<int> getConsecutiveWorkoutDays(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .orderBy('startedAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) return 0;

      int consecutiveDays = 1;
      DateTime lastWorkoutDate =
          (snapshot.docs.first.data()['startedAt'] as Timestamp).toDate();

      for (int i = 1; i < snapshot.docs.length; i++) {
        final currentWorkoutDate =
            (snapshot.docs[i].data()['startedAt'] as Timestamp).toDate();
        final dayDifference = lastWorkoutDate
            .difference(currentWorkoutDate)
            .inDays;

        if (dayDifference == 1) {
          consecutiveDays++;
          lastWorkoutDate = currentWorkoutDate;
        } else {
          break;
        }
      }

      return consecutiveDays;
    } catch (e) {
      print('연속 운동일 계산 실패: $e');
      return 0;
    }
  }

  /// 주간 운동 상세 요약 정보 가져오기
  Future<WeeklyWorkoutSummary> getWeeklyWorkoutSummary(String userId) async {
    try {
      print('📝 [주간요약] 캐시 체크: ${_cachedWeeklySummary != null ? "있음" : "없음"}');
      
      // 캐시 확인
      if (_cachedWeeklySummary != null && 
          _cachedUserId == userId && 
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < const Duration(hours: 24)) {
        
        // 새로운 운동 확인
        if (_lastWorkoutCheckTime != null) {
          final hasNewWorkout = await _hasNewWorkoutSince(userId, _lastWorkoutCheckTime!);
          if (!hasNewWorkout) {
            print('✅ [주간요약] 캐시 사용 (즉시 반환)');
            return _cachedWeeklySummary!;
          } else {
            print('🆕 [주간요약] 새 운동 발견, 재계산');
          }
        }
      } else {
        print('❌ [주간요약] 캐시 무효 또는 첫 실행');
      }

      final now = DateTime.now();
      // 이번 주 월요일 계산 (weekday: 월=1, 일=7)
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      );
      final endOfWeek = startOfWeek.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );

      print('📅 [주간 요약] 조회 범위: $startOfWeek ~ $endOfWeek');

      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
          )
          .where('startedAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
          .get();

      print('📊 [주간 요약] 조회된 세션 개수: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        return WeeklyWorkoutSummary(
          totalDuration: 0,
          totalSets: 0,
          totalVolume: 0.0,
          workoutDays: 0,
          totalExercises: 0,
          avgDuration: 0.0,
          mostActiveDay: '없음',
          maxDailyDuration: 0,
          exerciseCount: {},
          topExercises: [],
          dailyDetails: [],
        );
      }

      int totalDuration = 0;
      int totalSets = 0;
      double totalVolume = 0.0;
      Set<String> workoutDates = {};
      Map<String, int> dailyDuration = {};
      Map<String, int> exerciseCount = {};
      int totalExercises = 0;
      
      // 일별 상세 정보 저장
      Map<String, DailyWorkoutDetail> dailyDetailsMap = {};

      const weekDays = ['월', '화', '수', '목', '금', '토', '일'];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final duration = data['duration'] as int? ?? 0;
        final sets = data['totalSets'] as int? ?? 0;
        final volume = (data['totalVolume'] as num?)?.toDouble() ?? 0.0;
        final exerciseCountInSession = data['exerciseCount'] as int? ?? 0;
        final startedAt = (data['startedAt'] as Timestamp).toDate();
        final dateOnly = DateTime(
          startedAt.year,
          startedAt.month,
          startedAt.day,
        );
        final dayOfWeek = weekDays[(startedAt.weekday - 1) % 7];
        final dateKey = dateOnly.toIso8601String();

        totalDuration += duration;
        totalSets += sets;
        totalVolume += volume;
        totalExercises += exerciseCountInSession;
        workoutDates.add(dateKey);

        // 요일별 운동 시간 집계
        dailyDuration[dayOfWeek] = (dailyDuration[dayOfWeek] ?? 0) + duration;

        // 운동 종목 수집
        final exercisesSnapshot = await doc.reference
            .collection('exercises')
            .get();
        
        List<String> exerciseNames = [];
        for (var exerciseDoc in exercisesSnapshot.docs) {
          final exerciseName =
              exerciseDoc.data()['exerciseName'] as String? ?? '알 수 없음';
          exerciseCount[exerciseName] = (exerciseCount[exerciseName] ?? 0) + 1;
          if (!exerciseNames.contains(exerciseName)) {
            exerciseNames.add(exerciseName);
          }
        }

        // 일별 상세 정보 업데이트
        if (dailyDetailsMap.containsKey(dateKey)) {
          final existing = dailyDetailsMap[dateKey]!;
          dailyDetailsMap[dateKey] = DailyWorkoutDetail(
            date: existing.date,
            dayName: existing.dayName,
            duration: existing.duration + duration,
            sets: existing.sets + sets,
            volume: existing.volume + volume,
            exercises: [...existing.exercises, ...exerciseNames],
          );
        } else {
          dailyDetailsMap[dateKey] = DailyWorkoutDetail(
            date: dateOnly,
            dayName: dayOfWeek,
            duration: duration,
            sets: sets,
            volume: volume,
            exercises: exerciseNames,
          );
        }
      }

      // 가장 열심히 한 요일
      String mostActiveDay = '없음';
      int maxDuration = 0;
      dailyDuration.forEach((day, duration) {
        if (duration > maxDuration) {
          maxDuration = duration;
          mostActiveDay = day;
        }
      });

      // Top 3 운동
      final sortedExercises = exerciseCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topExercises = sortedExercises.take(3).map((e) => e.key).toList();

      final avgDuration = workoutDates.isEmpty
          ? 0.0
          : totalDuration / workoutDates.length;

      // 일별 상세 정보를 날짜순으로 정렬
      final dailyDetails = dailyDetailsMap.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final summary = WeeklyWorkoutSummary(
        totalDuration: totalDuration,
        totalSets: totalSets,
        totalVolume: totalVolume,
        workoutDays: workoutDates.length,
        totalExercises: totalExercises,
        avgDuration: avgDuration,
        mostActiveDay: mostActiveDay,
        maxDailyDuration: maxDuration,
        exerciseCount: exerciseCount,
        topExercises: topExercises,
        dailyDetails: dailyDetails,
      );

      // 캐시 저장
      _cachedWeeklySummary = summary;
      _cachedUserId = userId;
      _cacheTime = DateTime.now();
      _lastWorkoutCheckTime = DateTime.now();

      print('✅ [주간요약] 계산 완료 및 캐시 저장');
      return summary;
    } catch (e) {
      print('❌ 주간 운동 요약 조회 실패: $e');
      // 캐시가 있으면 반환
      if (_cachedWeeklySummary != null) {
        return _cachedWeeklySummary!;
      }
      return WeeklyWorkoutSummary(
        totalDuration: 0,
        totalSets: 0,
        totalVolume: 0.0,
        workoutDays: 0,
        totalExercises: 0,
        avgDuration: 0.0,
        mostActiveDay: '없음',
        maxDailyDuration: 0,
        exerciseCount: {},
        topExercises: [],
        dailyDetails: [],
      );
    }
  }
}
