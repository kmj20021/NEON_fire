import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neon_fire/models/saved_routine.dart';

class RoutineService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 루틴 저장
  Future<String?> saveRoutine(String userId, SavedRoutine routine) async {
    try {
      print('💾 루틴 저장 시작');
      print('  - userId: $userId');
      print('  - 루틴 이름: ${routine.name}');
      print('  - 운동 개수: ${routine.workouts.length}');
      print('  - 운동 IDs: ${routine.workouts}');

      final docRef = await _db
          .collection('users')
          .doc(userId)
          .collection('routines')
          .add({
            'name': routine.name,
            'workouts': routine.workouts,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });

      print('✅ 루틴 저장 성공! 문서 ID: ${docRef.id}');
      print('  - 경로: users/$userId/routines/${docRef.id}');

      return docRef.id;
    } catch (e) {
      print('❌ 루틴 저장 실패: $e');
      print('스택 트레이스: ${StackTrace.current}');
      return null;
    }
  }

  /// 사용자 루틴 목록 가져오기
  Future<List<SavedRoutine>> getUserRoutines(String userId) async {
    try {
      print('🔍 루틴 조회 시작: userId=$userId');

      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('routines')
          .where('isActive', isEqualTo: true)
          .get();

      print('📦 조회된 루틴 개수: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        print('⚠️ 저장된 루틴이 없습니다');
        return [];
      }

      // 루틴 리스트 생성
      final routines = snapshot.docs.map((doc) {
        final data = doc.data();
        print('📄 루틴 데이터: ${doc.id} - ${data['name']}');

        return SavedRoutine(
          id: doc.id,
          name: data['name'] ?? '이름 없음',
          workouts: List<int>.from(data['workouts'] ?? []),
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      // createdAt 기준으로 최신순 정렬 (클라이언트에서)
      routines.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ 루틴 조회 성공: ${routines.length}개');
      return routines;
    } catch (e) {
      print('❌ 루틴 목록 조회 실패: $e');
      print('스택 트레이스: ${StackTrace.current}');
      return [];
    }
  }

  /// 루틴 삭제 (소프트 삭제)
  Future<bool> deleteRoutine(String userId, String routineId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routineId)
          .update({
            'isActive': false,
            'deletedAt': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      print('루틴 삭제 실패: $e');
      return false;
    }
  }
}
