// lib/controllers/performance_controller.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neon_fire/models/performance_models.dart';
import 'package:neon_fire/services/performance_service.dart';

/// Performance Controller - MVC 패턴의 Controller
/// 비즈니스 로직과 상태 관리를 담당
class PerformanceController extends ChangeNotifier {
  final PerformanceService _service = PerformanceService();
  final String userId;

  // 기간 고정: 최근 30일
  final PerformancePeriod selectedPeriod = PerformancePeriod.days30;

  // 데이터 상태
  PerformanceSummary? summary;
  GoalAchievement? goalAchievement;
  VolumeIntensitySummary? volumeIntensity;
  ConsistencyScore? consistencyScore;
  PerformanceComment? performanceComment;

  bool isLoading = true;
  String? errorMessage;

  PerformanceController({required this.userId});

  /// 모든 데이터 로드
  Future<void> loadAllData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 모든 데이터를 병렬로 한 번에 로드
      final results = await Future.wait([
        _service.getPerformanceSummary(userId, selectedPeriod),
        _service.getGoalAchievement(userId),
        _service.getVolumeIntensitySummary(userId, selectedPeriod),
        _service.getConsistencyScore(userId, selectedPeriod),
        _service.generatePerformanceComment(userId, selectedPeriod),
      ]);

      // 모든 데이터 로드가 완료된 후 한 번에 업데이트
      summary = results[0] as PerformanceSummary?;
      goalAchievement = results[1] as GoalAchievement?;
      volumeIntensity = results[2] as VolumeIntensitySummary?;
      consistencyScore = results[3] as ConsistencyScore?;
      performanceComment = results[4] as PerformanceComment?;
      isLoading = false;
      
      notifyListeners();
    } catch (e) {
      print('데이터 로드 실패: $e');
      errorMessage = '데이터를 불러오는데 실패했습니다';
      isLoading = false;
      notifyListeners();
    }
  }

  /// 운동 기록 불러오기
  Future<List<Map<String, dynamic>>> loadWorkoutHistory() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .orderBy('startedAt', descending: true)
          .limit(30)
          .get();

      final workouts = <Map<String, dynamic>>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // exercises 서브컬렉션의 개수를 직접 카운트
        final exercisesSnapshot = await doc.reference
            .collection('exercises')
            .get();
        
        workouts.add({
          'id': doc.id,
          'startedAt': data['startedAt'],
          'duration': data['duration'] ?? 0,
          'exerciseCount': exercisesSnapshot.docs.length,
        });
      }
      
      return workouts;
    } catch (e) {
      print('운동 기록 불러오기 실패: $e');
      return [];
    }
  }

  /// 운동 상세 기록 불러오기
  Future<List<Map<String, dynamic>>> loadWorkoutDetails(String sessionId) async {
    try {
      final exercisesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .doc(sessionId)
          .collection('exercises')
          .orderBy('order')
          .get();

      final exercises = <Map<String, dynamic>>[];
      for (var exerciseDoc in exercisesSnapshot.docs) {
        final exerciseData = exerciseDoc.data();
        
        // 세트 정보 가져오기
        final setsSnapshot = await exerciseDoc.reference
            .collection('sets')
            .orderBy('setNumber')
            .get();
        
        final sets = setsSnapshot.docs.map((setDoc) {
          final setData = setDoc.data();
          return {
            'weight': setData['weight'] ?? 0,
            'reps': setData['reps'] ?? 0,
          };
        }).toList();

        exercises.add({
          'name': exerciseData['exerciseName'] ?? '운동',
          'sets': sets,
        });
      }

      return exercises;
    } catch (e) {
      print('운동 상세 기록 불러오기 실패: $e');
      return [];
    }
  }

  /// 날짜 포맷팅
  String formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // 리소스 정리
    super.dispose();
  }
}
