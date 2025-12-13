// lib/services/workout_seeder.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 운동 시드 데이터 생성 서비스
/// 테스트 및 초기 데이터 확인을 위한 가짜 운동 세션 데이터를 생성합니다.
class WorkoutSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _random = Random();

  /// 지난 60일간의 운동 세션 시드 데이터 생성
  ///
  /// [userId] - 사용자 ID (Firebase Auth UID, 이메일 아님!)
  /// [daysToGenerate] - 생성할 일수 (기본: 60일)
  /// [workoutFrequency] - 주당 평균 운동 횟수 (기본: 4회)
  Future<void> seedWorkoutData({
    required String userId,
    int daysToGenerate = 60,
    double workoutFrequency = 4.0,
  }) async {
    try {
      print('');
      print('═══════════════════════════════════════');
      print('🌱 운동 데이터 시딩 시작...');
      print('═══════════════════════════════════════');
      print('👤 사용자 ID: $userId');
      print('📅 생성 기간: 최근 $daysToGenerate일');
      print('💪 평균 주당 운동 횟수: $workoutFrequency회');
      print('');

      // userId 검증
      if (userId.isEmpty ||
          userId == 'YOUR_USER_ID_HERE' ||
          userId.contains('@')) {
        throw Exception(
          '❌ 올바른 userId를 설정하세요! Firebase Auth UID를 사용해야 합니다 (이메일 아님). 현재: $userId',
        );
      }

      final now = DateTime.now();
      int totalSessions = 0;

      // 이번 주의 시작 (월요일)을 계산
      final currentWeekday = now.weekday; // 1=월요일, 7=일요일
      final thisWeekMonday = now.subtract(Duration(days: currentWeekday - 1));

      // 주차별로 운동 세션 생성
      for (
        int weekOffset = 0;
        weekOffset < (daysToGenerate / 7).ceil();
        weekOffset++
      ) {
        final sessionsThisWeek = _calculateSessionsForWeek(workoutFrequency);

        // 이번 주(weekOffset == 0)는 특별 처리: 월요일부터 오늘까지만
        final List<DateTime> availableDates = [];

        if (weekOffset == 0) {
          // 이번 주: 월요일부터 오늘까지의 날짜만 사용
          for (int i = 0; i < currentWeekday; i++) {
            availableDates.add(thisWeekMonday.add(Duration(days: i)));
          }
        } else {
          // 과거 주: 해당 주의 모든 날짜 사용
          final weekStartDate = now.subtract(Duration(days: weekOffset * 7));
          for (int i = 0; i < 7; i++) {
            final date = weekStartDate.subtract(Duration(days: i));
            if (now.difference(date).inDays < daysToGenerate) {
              availableDates.add(date);
            }
          }
        }

        // 사용 가능한 날짜가 없으면 건너뛰기
        if (availableDates.isEmpty) continue;

        // 해당 주에 생성할 세션 수를 사용 가능한 날짜 수로 제한
        final actualSessions = sessionsThisWeek.clamp(0, availableDates.length);

        // 날짜를 섞어서 랜덤하게 선택
        availableDates.shuffle(_random);

        for (
          int sessionIndex = 0;
          sessionIndex < actualSessions;
          sessionIndex++
        ) {
          final sessionDate = availableDates[sessionIndex];

          // 운동 타입 결정 (상체, 하체, 전신, 유산소)
          final workoutType = _selectWorkoutType();

          await _createWorkoutSession(
            userId: userId,
            date: sessionDate,
            workoutType: workoutType,
            weekOffset: weekOffset,
          );

          totalSessions++;
        }
      }

      print('');
      print('═══════════════════════════════════════');
      print('✅ 시딩 완료! 총 $totalSessions개의 운동 세션 생성');
      print('📍 이번 주 데이터: 월요일부터 오늘까지 포함');
      print('═══════════════════════════════════════');
      print('');

      if (totalSessions == 0) {
        print('⚠️ 경고: 생성된 세션이 0개입니다!');
        print('');
      }
    } catch (e, stackTrace) {
      print('');
      print('❌❌❌ 시딩 실패 ❌❌❌');
      print('에러: $e');
      print('스택트레이스: $stackTrace');
      print('');
      rethrow;
    }
  }

  /// 주차별 운동 세션 수 계산 (약간의 변동성 추가)
  int _calculateSessionsForWeek(double avgFrequency) {
    final variation = _random.nextDouble() * 2 - 1; // -1 ~ +1
    final sessions = (avgFrequency + variation).round();
    return sessions.clamp(2, 6); // 최소 2회, 최대 6회
  }

  /// 운동 타입 선택
  String _selectWorkoutType() {
    final types = ['upper', 'lower', 'fullbody', 'cardio'];
    final weights = [0.35, 0.35, 0.20, 0.10]; // 확률 분포

    final rand = _random.nextDouble();
    double cumulative = 0;

    for (int i = 0; i < types.length; i++) {
      cumulative += weights[i];
      if (rand <= cumulative) return types[i];
    }

    return types[0];
  }

  /// 운동 세션 생성
  Future<void> _createWorkoutSession({
    required String userId,
    required DateTime date,
    required String workoutType,
    required int weekOffset,
  }) async {
    try {
      // 운동 시간 (30분 ~ 90분)
      final duration = 1800 + _random.nextInt(3600); // 30-90분 (초 단위)

      // 루틴 이름
      final routineName = _getRoutineName(workoutType);

      // 운동 목록 생성
      final exercises = _generateExercises(workoutType, weekOffset);

      // 총 볼륨 및 세트 계산
      double totalVolume = 0.0;
      for (var ex in exercises) {
        for (var set in ex['sets']) {
          totalVolume +=
              (set['weight'] as num).toDouble() * (set['reps'] as int);
        }
      }

      final totalSets = exercises.fold<int>(
        0,
        (sum, ex) => sum + (ex['sets'] as List).length,
      );

      final completedSets = exercises.fold<int>(
        0,
        (sum, ex) =>
            sum + (ex['sets'] as List).where((s) => s['isCompleted']).length,
      );

      // 세션 문서 생성
      final sessionRef = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .add({
            'routineName': routineName,
            'startedAt': Timestamp.fromDate(date),
            'endedAt': Timestamp.fromDate(
              date.add(Duration(seconds: duration)),
            ),
            'duration': duration,
            'totalVolume': totalVolume,
            'totalSets': totalSets,
            'completedSets': completedSets,
            'exerciseCount': exercises.length,
            'createdAt': Timestamp.fromDate(date),
          });

      // 각 운동 저장
      for (var exercise in exercises) {
        final exerciseRef = await sessionRef.collection('exercises').add({
          'exerciseId': exercise['exerciseId'],
          'exerciseName': exercise['exerciseName'],
          'order': exercise['order'],
          'createdAt': Timestamp.fromDate(date),
        });

        // 각 세트 저장
        for (var set in exercise['sets']) {
          await exerciseRef.collection('sets').add({
            'setNumber': set['setNumber'],
            'weight': set['weight'],
            'reps': set['reps'],
            'isCompleted': set['isCompleted'],
            'completedAt': set['isCompleted']
                ? Timestamp.fromDate(
                    date.add(Duration(seconds: set['setNumber'] * 120)),
                  )
                : null,
            'createdAt': Timestamp.fromDate(date),
          });
        }
      }

      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      print(
        '  ✓ $dateStr - $routineName (${duration ~/ 60}분, ${totalVolume.toStringAsFixed(0)}kg, 세션ID: ${sessionRef.id})',
      );
    } catch (e, stackTrace) {
      print('  ✗✗✗ 세션 생성 실패 ✗✗✗');
      print('  에러: $e');
      print('  날짜: $date');
      print('  userId: $userId');
      print('  스택트레이스: $stackTrace');
      rethrow; // 에러를 상위로 전파
    }
  }

  /// 루틴 이름 가져오기
  String _getRoutineName(String workoutType) {
    switch (workoutType) {
      case 'upper':
        return ['가슴/삼두', '등/이두', '어깨'][_random.nextInt(3)];
      case 'lower':
        return ['하체 A', '하체 B'][_random.nextInt(2)];
      case 'fullbody':
        return '전신 운동';
      case 'cardio':
        return '유산소';
      default:
        return '운동';
    }
  }

  /// 운동 목록 생성
  List<Map<String, dynamic>> _generateExercises(
    String workoutType,
    int weekOffset,
  ) {
    switch (workoutType) {
      case 'upper':
        return _generateUpperBodyExercises(weekOffset);
      case 'lower':
        return _generateLowerBodyExercises(weekOffset);
      case 'fullbody':
        return _generateFullBodyExercises(weekOffset);
      case 'cardio':
        return _generateCardioExercises(weekOffset);
      default:
        return [];
    }
  }

  /// 상체 운동 생성
  List<Map<String, dynamic>> _generateUpperBodyExercises(int weekOffset) {
    final exercises = [
      {'id': 1, 'name': '벤치 프레스', 'baseWeight': 60.0, 'baseReps': 10},
      {'id': 2, 'name': '덤벨 플라이', 'baseWeight': 15.0, 'baseReps': 12},
      {'id': 3, 'name': '케이블 크로스오버', 'baseWeight': 20.0, 'baseReps': 15},
      {'id': 4, 'name': '트라이셉 익스텐션', 'baseWeight': 25.0, 'baseReps': 12},
      {'id': 101, 'name': '랫 풀다운', 'baseWeight': 50.0, 'baseReps': 12},
      {'id': 102, 'name': '덤벨 로우', 'baseWeight': 20.0, 'baseReps': 10},
      {'id': 103, 'name': '바벨 컬', 'baseWeight': 25.0, 'baseReps': 10},
      {'id': 201, 'name': '숄더 프레스', 'baseWeight': 30.0, 'baseReps': 10},
      {'id': 202, 'name': '사이드 레터럴 레이즈', 'baseWeight': 8.0, 'baseReps': 15},
    ];

    // 랜덤하게 4-6개 선택
    final selectedCount = 4 + _random.nextInt(3);
    exercises.shuffle(_random);
    final selected = exercises.take(selectedCount).toList();

    return selected.asMap().entries.map((entry) {
      final index = entry.key;
      final ex = entry.value;

      // 점진적 과부하: 주차가 지날수록 무게/반복 증가
      final progressFactor = 1.0 + (weekOffset * 0.02); // 주당 2% 증가
      final weightVariation = 0.9 + (_random.nextDouble() * 0.2); // ±10% 변동

      final weight =
          (ex['baseWeight'] as double) * progressFactor * weightVariation;
      final reps = ex['baseReps'] as int;

      return {
        'exerciseId': ex['id'],
        'exerciseName': ex['name'],
        'order': index + 1,
        'sets': _generateSets(weight, reps, 4),
      };
    }).toList();
  }

  /// 하체 운동 생성
  List<Map<String, dynamic>> _generateLowerBodyExercises(int weekOffset) {
    final exercises = [
      {'id': 301, 'name': '스쿼트', 'baseWeight': 80.0, 'baseReps': 10},
      {'id': 302, 'name': '레그 프레스', 'baseWeight': 120.0, 'baseReps': 12},
      {'id': 303, 'name': '레그 익스텐션', 'baseWeight': 40.0, 'baseReps': 15},
      {'id': 304, 'name': '레그 컬', 'baseWeight': 35.0, 'baseReps': 12},
      {'id': 305, 'name': '루마니안 데드리프트', 'baseWeight': 70.0, 'baseReps': 10},
      {'id': 306, 'name': '카프 레이즈', 'baseWeight': 50.0, 'baseReps': 20},
    ];

    final selectedCount = 4 + _random.nextInt(2);
    exercises.shuffle(_random);
    final selected = exercises.take(selectedCount).toList();

    return selected.asMap().entries.map((entry) {
      final index = entry.key;
      final ex = entry.value;

      final progressFactor = 1.0 + (weekOffset * 0.02);
      final weightVariation = 0.9 + (_random.nextDouble() * 0.2);

      final weight =
          (ex['baseWeight'] as double) * progressFactor * weightVariation;
      final reps = ex['baseReps'] as int;

      return {
        'exerciseId': ex['id'],
        'exerciseName': ex['name'],
        'order': index + 1,
        'sets': _generateSets(weight, reps, 4),
      };
    }).toList();
  }

  /// 전신 운동 생성
  List<Map<String, dynamic>> _generateFullBodyExercises(int weekOffset) {
    final exercises = [
      {'id': 1, 'name': '벤치 프레스', 'baseWeight': 60.0, 'baseReps': 10},
      {'id': 101, 'name': '랫 풀다운', 'baseWeight': 50.0, 'baseReps': 12},
      {'id': 301, 'name': '스쿼트', 'baseWeight': 80.0, 'baseReps': 10},
      {'id': 305, 'name': '루마니안 데드리프트', 'baseWeight': 70.0, 'baseReps': 10},
      {'id': 201, 'name': '숄더 프레스', 'baseWeight': 30.0, 'baseReps': 10},
    ];

    return exercises.asMap().entries.map((entry) {
      final index = entry.key;
      final ex = entry.value;

      final progressFactor = 1.0 + (weekOffset * 0.02);
      final weightVariation = 0.9 + (_random.nextDouble() * 0.2);

      final weight =
          (ex['baseWeight'] as double) * progressFactor * weightVariation;
      final reps = ex['baseReps'] as int;

      return {
        'exerciseId': ex['id'],
        'exerciseName': ex['name'],
        'order': index + 1,
        'sets': _generateSets(weight, reps, 3),
      };
    }).toList();
  }

  /// 유산소 운동 생성
  List<Map<String, dynamic>> _generateCardioExercises(int weekOffset) {
    final exercises = [
      {'id': 401, 'name': '러닝', 'baseWeight': 0.0, 'baseReps': 30}, // 분
      {'id': 402, 'name': '사이클', 'baseWeight': 0.0, 'baseReps': 40},
      {'id': 403, 'name': '로잉 머신', 'baseWeight': 0.0, 'baseReps': 20},
    ];

    final ex = exercises[_random.nextInt(exercises.length)];
    final duration = (ex['baseReps'] as int) + (weekOffset * 2); // 주당 2분씩 증가

    return [
      {
        'exerciseId': ex['id'],
        'exerciseName': ex['name'],
        'order': 1,
        'sets': [
          {
            'setNumber': 1,
            'weight': 0.0,
            'reps': duration, // 시간(분)을 reps로 저장
            'isCompleted': true,
          },
        ],
      },
    ];
  }

  /// 세트 생성
  List<Map<String, dynamic>> _generateSets(
    double baseWeight,
    int baseReps,
    int setCount,
  ) {
    return List.generate(setCount, (index) {
      // 세트가 진행될수록 무게 감소 또는 반복수 감소
      final weightFactor = 1.0 - (index * 0.05); // 세트당 5% 감소
      final repsFactor = _random.nextBool() ? 0 : -1; // 50% 확률로 반복수 1개 감소

      final weight = (baseWeight * weightFactor).roundToDouble();
      final reps = (baseReps + repsFactor).clamp(1, 30);

      // 대부분의 세트는 완료, 가끔 미완료
      final isCompleted = _random.nextDouble() > 0.05; // 95% 완료율

      return {
        'setNumber': index + 1,
        'weight': weight,
        'reps': reps,
        'isCompleted': isCompleted,
      };
    });
  }

  /// 기존 운동 데이터 삭제
  Future<void> clearWorkoutData(String userId) async {
    try {
      print('🗑️ 기존 운동 데이터 삭제 중...');

      final sessionsSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .get();

      int deletedCount = 0;
      for (var sessionDoc in sessionsSnapshot.docs) {
        // 하위 컬렉션 삭제
        final exercisesSnapshot = await sessionDoc.reference
            .collection('exercises')
            .get();

        for (var exerciseDoc in exercisesSnapshot.docs) {
          // 세트 삭제
          final setsSnapshot = await exerciseDoc.reference
              .collection('sets')
              .get();

          for (var setDoc in setsSnapshot.docs) {
            await setDoc.reference.delete();
          }

          await exerciseDoc.reference.delete();
        }

        await sessionDoc.reference.delete();
        deletedCount++;
      }

      print('✅ $deletedCount개의 운동 세션 삭제 완료');
    } catch (e) {
      print('❌ 데이터 삭제 실패: $e');
      rethrow;
    }
  }

  /// 운동 목표 설정 시드 데이터
  Future<void> seedGoalSettings(String userId) async {
    try {
      print('🎯 목표 설정 시드 데이터 생성 중...');

      await _db.collection('users').doc(userId).set({
        'weeklyGoal': 4, // 주당 4회 운동 목표
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ 목표 설정 완료');
    } catch (e) {
      print('❌ 목표 설정 실패: $e');
    }
  }

  /// 전체 시드 프로세스 실행 (데이터 삭제 + 생성)
  Future<void> seedAll({
    required String userId,
    bool clearExisting = true,
    int daysToGenerate = 60,
    double workoutFrequency = 4.0,
  }) async {
    try {
      print('');
      print('╔═══════════════════════════════════════╗');
      print('║   🌱 운동 데이터 시딩 프로세스 시작   ║');
      print('╚═══════════════════════════════════════╝');
      print('');
      print('⚙️  설정:');
      print('   - 사용자 ID: $userId');
      print('   - 기존 데이터 삭제: $clearExisting');
      print('   - 생성 기간: $daysToGenerate일');
      print('   - 주당 운동 횟수: $workoutFrequency회');
      print('');

      // userId 검증
      if (userId.isEmpty ||
          userId == 'YOUR_USER_ID_HERE' ||
          userId.contains('@')) {
        print('❌❌❌ 오류: 잘못된 userId ❌❌❌');
        print('현재 userId: "$userId"');
        print('');
        print('해결 방법:');
        print('1. Firebase Console에서 Authentication > Users로 이동');
        print('2. 사용자 목록에서 UID 복사 (이메일이 아닙니다!)');
        print('3. main.dart에서 userId를 복사한 UID로 변경');
        print('');
        print('예시:');
        print('  잘못된 예: "user@example.com"');
        print('  올바른 예: "a1b2c3d4e5f6g7h8i9j0"');
        print('');
        throw Exception('잘못된 userId: Firebase Auth UID를 사용해야 합니다 (이메일 아님)');
      }

      if (clearExisting) {
        await clearWorkoutData(userId);
        print('');
      }

      await seedWorkoutData(
        userId: userId,
        daysToGenerate: daysToGenerate,
        workoutFrequency: workoutFrequency,
      );

      print('');

      await seedGoalSettings(userId);

      print('');
      print('═══════════════════════════════════════');
      print('✅ 모든 시드 데이터 생성 완료!');
      print('═══════════════════════════════════════');
      print('');
      print('다음 화면에서 데이터를 확인할 수 있습니다:');
      print('  📅 홈 화면 - 운동 캘린더');
      print('  ⏱️  홈 화면 - 한 주간 운동 시간');
      print('  📊 성과 화면 - 최근 30일 성과');
      print('  🏆 성과 화면 - 개인 기록');
      print('  🎯 성과 화면 - 목표 달성');
      print('  📈 성과 화면 - 볼륨/강도 변화');
      print('  💪 성과 화면 - 부위별 성장');
      print('  ⭐ 성과 화면 - 운동 일관성');
      print('');
    } catch (e) {
      print('');
      print('❌ 시딩 실패: $e');
      print('');
      rethrow;
    }
  }
}
