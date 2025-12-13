class WorkoutSet {
  final double weight;
  final int reps;
  final bool completed;
  final DateTime? completedAt;

  WorkoutSet({
    this.weight = 0,
    this.reps = 0,
    this.completed = false,
    this.completedAt,
  });

  WorkoutSet copyWith({
    double? weight,
    int? reps,
    bool? completed,
    DateTime? completedAt,
  }) {
    return WorkoutSet(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'weight': weight,
    'reps': reps,
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory WorkoutSet.fromMap(Map<String, dynamic> map) => WorkoutSet(
    weight: (map['weight'] as num?)?.toDouble() ?? 0,
    reps: map['reps'] ?? 0,
    completed: map['completed'] ?? false,
    completedAt: map['completedAt'] != null
        ? DateTime.parse(map['completedAt'])
        : null,
  );
}

class WorkoutSession {
  final int workoutId;
  final List<WorkoutSet> sets;

  WorkoutSession({required this.workoutId, required this.sets});

  WorkoutSession copyWith({int? workoutId, List<WorkoutSet>? sets}) {
    return WorkoutSession(
      workoutId: workoutId ?? this.workoutId,
      sets: sets ?? this.sets,
    );
  }

  Map<String, dynamic> toMap() => {
    'workoutId': workoutId,
    'sets': sets.map((s) => s.toMap()).toList(),
  };

  factory WorkoutSession.fromMap(Map<String, dynamic> map) => WorkoutSession(
    workoutId: map['workoutId'],
    sets: (map['sets'] as List).map((s) => WorkoutSet.fromMap(s)).toList(),
  );
}
