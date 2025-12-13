import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neon_fire/models/exercise_models/workout_set_model.dart';

class WorkoutSessionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 운동 세션 저장
  Future<String?> saveWorkoutSession({
    required String userId,
    required String? routineName,
    required int duration,
    required List<WorkoutSessionData> exercises,
  }) async {
    try {
      // 총 볼륨 계산 (kg)
      final totalVolume = _calculateTotalVolume(exercises);

      // 총 완료된 세트 수
      final completedSets = exercises.fold(
        0,
        (sum, ex) => sum + ex.sets.where((s) => s.completed).length,
      );

      // 세션 문서 생성
      final sessionRef = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .add({
            'routineName': routineName,
            'startedAt': Timestamp.now(),
            'endedAt': Timestamp.now(),
            'duration': duration, // 초 단위
            'totalVolume': totalVolume,
            'totalSets': exercises.fold(0, (sum, ex) => sum + ex.sets.length),
            'completedSets': completedSets,
            'exerciseCount': exercises.length,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 각 운동 저장
      for (var i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];

        final exerciseRef = await sessionRef.collection('exercises').add({
          'exerciseId': exercise.exerciseId,
          'exerciseName': exercise.exerciseName,
          'order': i + 1,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 각 세트 저장
        for (var j = 0; j < exercise.sets.length; j++) {
          final set = exercise.sets[j];

          await exerciseRef.collection('sets').add({
            'setNumber': j + 1,
            'weight': set.weight,
            'reps': set.reps,
            'isCompleted': set.completed,
            'completedAt': set.completedAt != null
                ? Timestamp.fromDate(set.completedAt!)
                : null,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 개인 기록 업데이트 (1RM 등)
      await _updatePersonalRecords(userId, exercises);

      print('✅ 운동 세션 저장 완료: ${sessionRef.id}');
      return sessionRef.id;
    } catch (e) {
      print('❌ 운동 세션 저장 실패: $e');
      return null;
    }
  }

  /// 총 볼륨 계산 (kg)
  double _calculateTotalVolume(List<WorkoutSessionData> exercises) {
    double total = 0;
    for (var exercise in exercises) {
      for (var set in exercise.sets) {
        if (set.completed) {
          total += set.weight * set.reps;
        }
      }
    }
    return total;
  }

  /// 개인 기록 업데이트
  Future<void> _updatePersonalRecords(
    String userId,
    List<WorkoutSessionData> exercises,
  ) async {
    try {
      for (var exercise in exercises) {
        // 1RM 계산 (Epley 공식: weight * (1 + reps/30))
        double maxOneRM = 0;
        double maxWeight = 0;
        int maxReps = 0;

        for (var set in exercise.sets) {
          if (set.completed) {
            final oneRM = set.weight * (1 + set.reps / 30);
            if (oneRM > maxOneRM) {
              maxOneRM = oneRM;
            }
            if (set.weight > maxWeight) {
              maxWeight = set.weight;
            }
            if (set.reps > maxReps) {
              maxReps = set.reps;
            }
          }
        }

        if (maxOneRM == 0) continue;

        // 기존 기록 조회
        final existingRecordSnapshot = await _db
            .collection('users')
            .doc(userId)
            .collection('personal_records')
            .where('exerciseId', isEqualTo: exercise.exerciseId)
            .where('recordType', isEqualTo: '1RM')
            .orderBy('recordValue', descending: true)
            .limit(1)
            .get();

        // 신기록이면 저장
        if (existingRecordSnapshot.docs.isEmpty ||
            maxOneRM >
                existingRecordSnapshot.docs.first.data()['recordValue']) {
          await _db
              .collection('users')
              .doc(userId)
              .collection('personal_records')
              .add({
                'exerciseId': exercise.exerciseId,
                'exerciseName': exercise.exerciseName,
                'recordType': '1RM',
                'recordValue': maxOneRM,
                'recordDate': Timestamp.now(),
                'weight': maxWeight,
                'reps': maxReps,
                'createdAt': FieldValue.serverTimestamp(),
              });
          print(
            '🎉 신기록!  ${exercise.exerciseName}: ${maxOneRM.toStringAsFixed(1)}kg (1RM)',
          );
        }
      }
    } catch (e) {
      print('개인 기록 업데이트 실패: $e');
    }
  }

  /// 최근 운동 세션 조회
  Future<List<Map<String, dynamic>>> getRecentSessions(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .orderBy('startedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      print('최근 세션 조회 실패: $e');
      return [];
    }
  }

  /// 특정 세션 상세 조회
  Future<Map<String, dynamic>?> getSessionDetail(
    String userId,
    String sessionId,
  ) async {
    try {
      final sessionDoc = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) return null;

      final sessionData = sessionDoc.data()!;
      sessionData['id'] = sessionDoc.id;

      // 운동 목록 조회
      final exercisesSnapshot = await sessionDoc.reference
          .collection('exercises')
          .orderBy('order')
          .get();

      final exercises = <Map<String, dynamic>>[];

      for (var exerciseDoc in exercisesSnapshot.docs) {
        final exerciseData = exerciseDoc.data();

        // 세트 목록 조회
        final setsSnapshot = await exerciseDoc.reference
            .collection('sets')
            .orderBy('setNumber')
            .get();

        exerciseData['sets'] = setsSnapshot.docs
            .map((setDoc) => setDoc.data())
            .toList();

        exercises.add(exerciseData);
      }

      sessionData['exercises'] = exercises;

      return sessionData;
    } catch (e) {
      print('세션 상세 조회 실패: $e');
      return null;
    }
  }
}

/// 운동 세션 데이터 전달 객체
class WorkoutSessionData {
  final int exerciseId;
  final String exerciseName;
  final List<WorkoutSet> sets;

  WorkoutSessionData({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });
}
