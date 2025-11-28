import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neon_fire/models/saved_routine.dart';

class RoutineService {
  final FirebaseFirestore _db = FirebaseFirestore. instance;

  /// 루틴 저장
  Future<String? > saveRoutine(String userId, SavedRoutine routine) async {
    try {
      final docRef = await _db
          .collection('users')
          .doc(userId)
          . collection('routines')
          . add({
        'name': routine.name,
        'workouts': routine.workouts,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      return docRef.id;
    } catch (e) {
      print('루틴 저장 실패: $e');
      return null;
    }
  }

  /// 사용자 루틴 목록 가져오기
  Future<List<SavedRoutine>> getUserRoutines(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          . doc(userId)
          .collection('routines')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs. map((doc) {
        final data = doc.data();
        return SavedRoutine(
          id: doc.id,
          name: data['name'],
          workouts: List<int>.from(data['workouts']),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('루틴 목록 조회 실패: $e');
      return [];
    }
  }
}