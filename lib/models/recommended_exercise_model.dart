class RecommendedExercise {
  final int exerciseId;
  final String exerciseName;
  final String?  description;
  final String? imagePath;
  final String muscleGroup;
  final int daysSinceLastWorkout;

  RecommendedExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.description,
    this.imagePath,
    required this.muscleGroup,
    required this.daysSinceLastWorkout,
  });

  factory RecommendedExercise. fromMap(Map<String, dynamic> data, int days) {
    return RecommendedExercise(
      exerciseId: data['id'],
      exerciseName: data['name'],
      description: data['description'],
      imagePath: data['imagePath'],
      muscleGroup: (data['primaryMuscles'] as List). isNotEmpty
          ? data['primaryMuscles'][0]['name']
          : '전체',
      daysSinceLastWorkout: days,
    );
  }
}