import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutStats {
  final DateTime date;
  final int duration; // 분
  final int? setCount;
  final double? totalVolume; // kg
  final bool completed;

  WorkoutStats({
    required this.date,
    required this.duration,
    this.setCount,
    this.totalVolume,
    required this.completed,
  });

  factory WorkoutStats.fromFirestore(Map<String, dynamic> data) {
    return WorkoutStats(
      date: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      duration: data['duration'] ?? 0,
      setCount: data['setCount'],
      totalVolume: (data['totalVolume'] as num?)?.toDouble(),
      completed: data['completed'] ?? true,
    );
  }
}

class DailyWorkoutData {
  final DateTime date;
  final int minutes;
  final bool hasWorkout;
  final List<WorkoutStats>? workouts;

  DailyWorkoutData({
    required this.date,
    required this.minutes,
    required this.hasWorkout,
    this.workouts,
  });
}

class WeeklyWorkoutData {
  final String day;
  final int minutes;

  WeeklyWorkoutData({
    required this.day,
    required this.minutes,
  });
}