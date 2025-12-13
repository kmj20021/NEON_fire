import 'package:cloud_firestore/cloud_firestore.dart';

class MuscleInfo {
  final int id;
  final String name;
  final bool isPrimary;

  MuscleInfo({required this.id, required this.name, required this.isPrimary});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'isPrimary': isPrimary,
  };

  factory MuscleInfo.fromMap(Map<String, dynamic> map) => MuscleInfo(
    id: map['id'],
    name: map['name'],
    isPrimary: map['isPrimary'] ?? false,
  );
}

class ExerciseModel {
  final String docId;
  final int id;
  final String name;
  final String? description;
  final String? equipment;
  final String? youtubeUrl;
  final String? imagePath;
  final String? thumbnailPath;
  final bool supportsReps;
  final bool supportsWeight;
  final bool supportsTime;
  final bool supportsDistance;
  final List<MuscleInfo> primaryMuscles;
  final List<MuscleInfo> secondaryMuscles;
  final List<int> allMuscleIds;
  final String? detailDescription;

  ExerciseModel({
    required this.docId,
    required this.id,
    required this.name,
    this.description,
    this.equipment,
    this.youtubeUrl,
    this.imagePath,
    this.thumbnailPath,
    this.supportsReps = true,
    this.supportsWeight = true,
    this.supportsTime = false,
    this.supportsDistance = false,
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.allMuscleIds = const [],
    this.detailDescription,
  });

  // 주 근육 그룹 이름
  String get bodyPart {
    if (primaryMuscles.isNotEmpty) {
      return primaryMuscles.first.name;
    }
    return '전체';
  }

  // 강도 (임시로 랜덤 또는 고정값)
  String get intensity {
    if (supportsWeight) return '고';
    if (supportsReps) return '중';
    return '저';
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'description': description,
    'equipment': equipment,
    'youtubeUrl': youtubeUrl,
    'imagePath': imagePath,
    'thumbnailPath': thumbnailPath,
    'supportsReps': supportsReps,
    'supportsWeight': supportsWeight,
    'supportsTime': supportsTime,
    'supportsDistance': supportsDistance,
    'primaryMuscles': primaryMuscles.map((m) => m.toMap()).toList(),
    'secondaryMuscles': secondaryMuscles.map((m) => m.toMap()).toList(),
    'allMuscleIds': allMuscleIds,
    'detailDescription': detailDescription,
  };

  factory ExerciseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseModel(
      docId: doc.id,
      id: data['id'],
      name: data['name'],
      description: data['description'],
      equipment: data['equipment'],
      youtubeUrl: data['youtubeUrl'],
      imagePath: data['imagePath'],
      thumbnailPath: data['thumbnailPath'],
      supportsReps: data['supportsReps'] ?? true,
      supportsWeight: data['supportsWeight'] ?? true,
      supportsTime: data['supportsTime'] ?? false,
      supportsDistance: data['supportsDistance'] ?? false,
      primaryMuscles:
          (data['primaryMuscles'] as List?)
              ?.map((m) => MuscleInfo.fromMap(m))
              .toList() ??
          [],
      secondaryMuscles:
          (data['secondaryMuscles'] as List?)
              ?.map((m) => MuscleInfo.fromMap(m))
              .toList() ??
          [],
      allMuscleIds: List<int>.from(data['allMuscleIds'] ?? []),
      detailDescription: data['detailDescription'],
    );
  }
}
