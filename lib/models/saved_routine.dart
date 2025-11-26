class SavedRoutine {
  final String id;
  final String name;
  final List<int> workouts;
  final DateTime createdAt;

  SavedRoutine({
    required this.id,
    required this.name,
    required this.workouts,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'workouts': workouts,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedRoutine.fromJson(Map<String, dynamic> json) => SavedRoutine(
    id: json['id'],
    name: json['name'],
    workouts: List<int>.from(json['workouts']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}