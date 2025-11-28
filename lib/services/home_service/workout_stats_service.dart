import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neon_fire/models/home_models/workout_stats_model.dart';
// ❌ WeeklyWorkoutData와 WorkoutStats 클래스가 workout_stats_model.dart에 정의되어 있어야 함

class WorkoutStatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
          .where('startedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('startedAt', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
          .get();

      final Map<DateTime, int> workoutMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final startedAt = (data['startedAt'] as Timestamp).toDate();
        final dateOnly = DateTime(startedAt.year, startedAt.month, startedAt.day);
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
      final now = DateTime.now();
      // 이번 주 월요일 계산
      final weekStart = now.subtract(Duration(days: now.weekday % 7));
      final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where('startedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('startedAt', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
          .get();

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
        final duration = data['duration'] as int? ?? 0;

        // 요일 계산 (월=0, 일=6)
        final dayOfWeek = (startedAt.weekday - 1) % 7;
        dayWorkout[dayOfWeek] = (dayWorkout[dayOfWeek] ?? 0) + duration;
      }

      // 결과 변환
      const weekDays = ['월', '화', '수', '목', '금', '토', '일'];
      return List.generate(
        7,
        (index) => WeeklyWorkoutData(
          day: weekDays[index],
          minutes: dayWorkout[index] ?? 0,
        ),
      );
    } catch (e) {
      print('주간 운동 데이터 조회 실패: $e');
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
          . collection('workout_sessions')
          .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
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
      DateTime lastWorkoutDate = (snapshot.docs.first.data()['startedAt'] as Timestamp).toDate();

      for (int i = 1; i < snapshot.docs.length; i++) {
        final currentWorkoutDate = (snapshot.docs[i].data()['startedAt'] as Timestamp).toDate();
        final dayDifference = lastWorkoutDate.difference(currentWorkoutDate).inDays;

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
}