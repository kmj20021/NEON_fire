import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neon_fire/models/exercise_models/exercise_model.dart';

class ExerciseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 모든 운동 가져오기
  Future<List<ExerciseModel>> getAllExercises() async {
    try {
      final snapshot = await _db.collection('exercises').orderBy('id').get();

      return snapshot.docs
          . map((doc) => ExerciseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('운동 데이터 조회 실패: $e');
      return [];
    }
  }

  /// 근육 그룹별 운동 가져오기
  Future<List<ExerciseModel>> getExercisesByMuscleGroup(
      String muscleGroup) async {
    try {
      if (muscleGroup == '전체') {
        return await getAllExercises();
      }

      final snapshot = await _db
          .collection('exercises')
          .where('primaryMuscles',
              arrayContains: {'name': muscleGroup, 'isPrimary': true})
          .get();

      return snapshot.docs
          .map((doc) => ExerciseModel. fromFirestore(doc))
          .toList();
    } catch (e) {
      print('근육 그룹별 운동 조회 실패: $e');
      return [];
    }
  }

  /// 검색
  Future<List<ExerciseModel>> searchExercises(String query) async {
    try {
      final allExercises = await getAllExercises();
      
      return allExercises. where((exercise) {
        final nameLower = exercise.name.toLowerCase();
        final descLower = (exercise.description ?? '').toLowerCase();
        final queryLower = query.toLowerCase();
        
        return nameLower.contains(queryLower) || descLower.contains(queryLower);
      }). toList();
    } catch (e) {
      print('운동 검색 실패: $e');
      return [];
    }
  }

  /// 특정 ID 목록의 운동들 가져오기
  Future<List<ExerciseModel>> getExercisesByIds(List<int> ids) async {
    try {
      if (ids.isEmpty) return [];

      final snapshot = await _db
          .collection('exercises')
          .where('id', whereIn: ids)
          .get();

      return snapshot.docs
          . map((doc) => ExerciseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('운동 ID 조회 실패: $e');
      return [];
    }
  }
}