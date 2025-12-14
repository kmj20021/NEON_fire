import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neon_fire/models/home_models/recommended_exercise_model.dart';

class RecommendationServiceV2 {
  // 싱글톤 패턴
  static final RecommendationServiceV2 _instance = RecommendationServiceV2._internal();
  factory RecommendationServiceV2() => _instance;
  RecommendationServiceV2._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 캐싱
  RecommendedExercise? _cachedRecommendation;
  DateTime? _lastWorkoutCheckTime;
  DateTime? _cacheTime;

  /// 캐시 유효성 검사 (24시간)
  bool _isCacheValid() {
    if (_cachedRecommendation == null || _cacheTime == null) {
      return false;
    }
    final now = DateTime.now();
    return now.difference(_cacheTime!) < const Duration(hours: 24);
  }

  /// 사용자 운동 기록 기반 추천
  Future<RecommendedExercise?> getRecommendedExerciseAdvanced(
    String userId,
  ) async {
    try {
      print('📝 캐시 상태: ${_cachedRecommendation != null ? "있음" : "없음"}, 시간: $_cacheTime');
      
      // 캐시가 유효하고, 새로운 운동이 없으면 캐시 반환
      if (_isCacheValid()) {
        print('⏱️ 캐시 유효성 검사 통과');
        final hasNewWorkout = await _hasNewWorkoutSince(userId, _lastWorkoutCheckTime!);
        print('🔍 새 운동 확인: $hasNewWorkout');
        
        if (!hasNewWorkout) {
          print('✅ 캐시된 추천 운동 사용 (즉시 반환)');
          return _cachedRecommendation;
        } else {
          print('🆕 새로운 운동 발견, 재계산 필요');
        }
      } else {
        print('❌ 캐시 유효하지 않음 (첫 실행 또는 만료)');
      }

      print('🔄 새로운 추천 운동 계산 중...');
      final startTime = DateTime.now();

      // 1. 최근 30일 운동 세션의 모든 운동 가져오기
      final muscleWorkoutMap = await _getMuscleWorkoutHistory(userId);

      // 2.  가장 오래 안 한 근육 그룹 찾기
      final neglectedMuscle = _findMostNeglectedMuscleAdvanced(
        muscleWorkoutMap,
      );

      if (neglectedMuscle == null) {
        final exercise = await _getRandomExercise();
        _cachedRecommendation = exercise;
        _cacheTime = DateTime.now();
        _lastWorkoutCheckTime = DateTime.now();
        
        final duration = DateTime.now().difference(startTime);
        print('⚡ 랜덤 추천 완료 (${duration.inMilliseconds}ms)');
        return exercise;
      }

      // 3. 해당 근육의 운동 중 사용자가 안 해본 운동 우선 추천
      final exercise = await _getExerciseForMuscle(
        userId,
        neglectedMuscle['muscleId'] as int,
      );

      // 캐시 저장
      _cachedRecommendation = exercise;
      _cacheTime = DateTime.now();
      _lastWorkoutCheckTime = DateTime.now();

      final duration = DateTime.now().difference(startTime);
      print('⚡ 추천 계산 완료 (${duration.inMilliseconds}ms), 캐시 저장됨');

      return exercise;
    } catch (e) {
      print('❌ 추천 운동 조회 실패: $e');
      return _cachedRecommendation; // 오류 시 캐시 반환
    }
  }

  /// 마지막 확인 이후 새로운 운동이 있는지 확인
  Future<bool> _hasNewWorkoutSince(String userId, DateTime since) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('workout_sessions')
        .where(
          'startedAt',
          isGreaterThan: Timestamp.fromDate(since),
        )
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// 근육별 운동 기록 맵 생성
  Future<Map<int, Map<String, dynamic>>> _getMuscleWorkoutHistory(
    String userId,
  ) async {
    final Map<int, Map<String, dynamic>> muscleMap = {};
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // 기본 근육 그룹 초기화 (1~6)
    for (int i = 1; i <= 6; i++) {
      muscleMap[i] = {
        'lastWorkoutDate': null,
        'workoutCount': 0,
        'exercises': <int>[],
      };
    }

    final sessionsSnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('workout_sessions')
        .where(
          'startedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
        )
        .orderBy('startedAt', descending: true)
        .get();

    // 각 세션의 운동 조회
    for (var sessionDoc in sessionsSnapshot.docs) {
      final sessionData = sessionDoc.data();
      final sessionDate = (sessionData['startedAt'] as Timestamp).toDate();

      // 세션의 운동 서브컬렉션 조회
      final exercisesSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .doc(sessionDoc.id)
          .collection('exercises')
          .get();

      for (var exerciseDoc in exercisesSnapshot.docs) {
        final exerciseData = exerciseDoc.data();
        final exerciseId = exerciseData['exerciseId'] as int;

        // 운동 정보 조회하여 근육 그룹 파악
        final exerciseInfo = await _getExerciseInfo(exerciseId);
        if (exerciseInfo == null) continue;

        final muscleIds = List<int>.from(exerciseInfo['allMuscleIds'] ?? []);

        for (var muscleId in muscleIds) {
          if (muscleMap.containsKey(muscleId)) {
            final current = muscleMap[muscleId]!;

            // 마지막 운동일 업데이트
            if (current['lastWorkoutDate'] == null ||
                sessionDate.isAfter(current['lastWorkoutDate'] as DateTime)) {
              current['lastWorkoutDate'] = sessionDate;
            }

            // 운동 횟수 증가
            current['workoutCount'] = (current['workoutCount'] as int) + 1;

            // 운동 ID 추가
            (current['exercises'] as List<int>).add(exerciseId);
          }
        }
      }
    }

    return muscleMap;
  }

  /// 운동 정보 조회
  Future<Map<String, dynamic>?> _getExerciseInfo(int exerciseId) async {
    final doc = await _db.collection('exercises').doc('ex_$exerciseId').get();
    return doc.exists ? doc.data() : null;
  }

  /// 가장 방치된 근육 찾기
  Map<String, dynamic>? _findMostNeglectedMuscleAdvanced(
    Map<int, Map<String, dynamic>> muscleMap,
  ) {
    final now = DateTime.now();
    int? mostNeglectedMuscleId; // 가장 방치된 근육 ID
    int maxDaysSince = -1; // 최대 경과 일수

    for (var entry in muscleMap.entries) {
      // muscleId와 데이터 쌍
      final muscleId = entry.key;
      final data = entry.value;
      final lastDate = data['lastWorkoutDate'] as DateTime?;

      int daysSince;
      if (lastDate == null) {
        daysSince = 999; // 한 번도 안 한 경우
      } else {
        daysSince = now.difference(lastDate).inDays;
      }

      if (daysSince > maxDaysSince) {
        maxDaysSince = daysSince;
        mostNeglectedMuscleId = muscleId;
      }
    }

    if (mostNeglectedMuscleId == null) return null;

    return {
      'muscleId': mostNeglectedMuscleId,
      'daysSince': maxDaysSince, // 마지막 운동 후 경과 일수
      'doneExercises':
          muscleMap[mostNeglectedMuscleId]!['exercises'], // 이미 한 운동 목록
    };
  }

  /// 특정 근육의 운동 추천 (안 해본 운동 우선)
  Future<RecommendedExercise?> _getExerciseForMuscle(
    String userId,
    int muscleId,
  ) async {
    // 해당 근육 그룹의 모든 운동 조회
    final snapshot = await _db
        .collection('exercises')
        .where('allMuscleIds', arrayContains: muscleId)
        .get();

    if (snapshot.docs.isEmpty) return null;

    // 사용자가 최근에 한 운동 목록
    final recentExerciseIds = await _getRecentExerciseIds(userId);

    // 안 해본 운동 우선 추천
    Map<String, dynamic>? selectedExercise;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (!recentExerciseIds.contains(data['id'])) {
        selectedExercise = data;
        break;
      }
    }

    // 모두 해봤으면 첫 번째 운동
    selectedExercise ??= snapshot.docs.first.data();

    return RecommendedExercise.fromMap(selectedExercise, 0);
  }

  /// 최근 한 운동 ID 목록
  Future<Set<int>> _getRecentExerciseIds(String userId) async {
    final Set<int> exerciseIds = {};
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    final sessionsSnapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('workout_sessions')
        .where(
          'startedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
        )
        .get();

    for (var sessionDoc in sessionsSnapshot.docs) {
      final exercisesSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .doc(sessionDoc.id)
          .collection('exercises')
          .get();

      for (var exerciseDoc in exercisesSnapshot.docs) {
        exerciseIds.add(exerciseDoc.data()['exerciseId'] as int);
      }
    }

    return exerciseIds;
  }

  /// 랜덤 운동 추천
  Future<RecommendedExercise?> _getRandomExercise() async {
    final snapshot = await _db.collection('exercises').limit(10).get();

    if (snapshot.docs.isEmpty) return null;

    final randomDoc =
        snapshot.docs[DateTime.now().millisecond % snapshot.docs.length];
    final data = randomDoc.data();

    return RecommendedExercise.fromMap(data, 0);
  }
}
