class CalendarDay {
  final DateTime date;
  final int day;
  final bool isCurrentMonth;
  final bool isToday;
  final bool hasWorkout;

  CalendarDay({
    required this.date,
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.hasWorkout,
  });
}
