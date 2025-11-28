import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neon_fire/models/home_models/calendar_day.dart';

class CalendarService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Firebase 데이터 기반 캘린더 생성
  Future<List<CalendarDay>> generateMonthlyCalendar(String userId) async {
    try {
      final now = DateTime.now();
      final currentMonth = now.month - 1;
      final currentYear = now. year;

      // 이번 달 첫 날과 마지막 날
      final firstDay = DateTime(currentYear, currentMonth + 1, 1);
      final lastDay = DateTime(currentYear, currentMonth + 2, 0);

      // 캘린더 시작 날짜 (이전 달 마지막 주 포함)
      final startDate = firstDay.subtract(Duration(days: firstDay.weekday % 7));

      // Firebase에서 월간 운동 데이터 가져오기
      final monthStart = DateTime(currentYear, currentMonth + 1, 1);
      final monthEnd = DateTime(currentYear, currentMonth + 2, 0, 23, 59, 59);

      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('startedAt', isLessThanOrEqualTo: Timestamp. fromDate(monthEnd))
          .get();

      // 운동 날짜 집합 생성
      final workoutDates = <DateTime>{};
      for (var doc in snapshot.docs) {
        final startedAt = (doc.data()['startedAt'] as Timestamp).toDate();
        final dateOnly = DateTime(startedAt.year, startedAt.month, startedAt. day);
        workoutDates.add(dateOnly);
      }

      // 캘린더 날짜 생성
      final days = <CalendarDay>[];
      var currentDate = startDate;

      for (int i = 0; i < 42; i++) {
        // 6주 * 7일
        final isCurrentMonth = currentDate.month == currentMonth + 1;
        final isToday = currentDate.year == now.year &&
            currentDate.month == now.month &&
            currentDate. day == now.day;
        final hasWorkout =
            isCurrentMonth && workoutDates.contains(currentDate);

        days.add(CalendarDay(
          date: currentDate,
          day: currentDate.day,
          isCurrentMonth: isCurrentMonth,
          isToday: isToday,
          hasWorkout: hasWorkout,
        ));

        currentDate = currentDate.add(const Duration(days: 1));
      }

      return days;
    } catch (e) {
      print('캘린더 생성 실패: $e');
      return [];
    }
  }

  /// 특정 주의 캘린더 가져오기
  List<CalendarDay> getWeekFromCalendar(
    List<CalendarDay> allDays,
    int weekIndex,
  ) {
    final start = weekIndex * 7;
    final end = (weekIndex + 1) * 7;

    if (start >= allDays.length) return [];
    return allDays.sublist(start, end. clamp(0, allDays.length));
  }
}