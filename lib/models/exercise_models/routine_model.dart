class RoutineExerciseItem {
  final int exerciseId;
  final String exerciseName;
  final String bodyPart;
  int order;

  RoutineExerciseItem({
    required this.exerciseId,
    required this.exerciseName,
    required this.bodyPart,
    required this.order,
  });

  RoutineExerciseItem copyWith({
    int? exerciseId,
    String? exerciseName,
    String? bodyPart,
    int? order,
  }) {
    return RoutineExerciseItem(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      bodyPart: bodyPart ?? this.bodyPart,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'bodyPart': bodyPart,
    'order': order,
  };

  factory RoutineExerciseItem.fromJson(Map<String, dynamic> json) =>
      RoutineExerciseItem(
        exerciseId: json['exerciseId'],
        exerciseName: json['exerciseName'],
        bodyPart: json['bodyPart'],
        order: json['order'],
      );
}
