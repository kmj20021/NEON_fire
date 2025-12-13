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

  WeeklyWorkoutData({required this.day, required this.minutes});
}

/// 주간 운동 요약 정보
class WeeklyWorkoutSummary {
  final int totalDuration; // 총 운동 시간 (분)
  final int totalSets; // 총 세트 수
  final double totalVolume; // 총 볼륨 (kg)
  final int workoutDays; // 운동한 날 수
  final int totalExercises; // 총 운동 종목 수
  final double avgDuration; // 평균 운동 시간
  final String mostActiveDay; // 가장 열심히 한 요일
  final int maxDailyDuration; // 하루 최대 운동 시간
  final Map<String, int> exerciseCount; // 운동별 횟수
  final List<String> topExercises; // 가장 많이 한 운동 Top 3

  WeeklyWorkoutSummary({
    required this.totalDuration,
    required this.totalSets,
    required this.totalVolume,
    required this.workoutDays,
    required this.totalExercises,
    required this.avgDuration,
    required this.mostActiveDay,
    required this.maxDailyDuration,
    required this.exerciseCount,
    required this.topExercises,
  });
}
