// lib/models/home_models/condition_status_model.dart
import 'package:flutter/material.dart';

/// 오늘의 컨디션 점수 모델
class ConditionScore {
  final int score; // 0-100
  final String status; // 좋음, 양호, 주의, 휴식필요
  final Color statusColor;
  final String recommendation;
  final List<String> factors; // 점수에 영향을 준 요소들

  ConditionScore({
    required this.score,
    required this.status,
    required this.statusColor,
    required this.recommendation,
    required this.factors,
  });

  factory ConditionScore.calculate({
    required int restDays,
    required double recentVolume,
    required double avgVolume,
    required int consecutiveHighIntensityDays,
    required Map<String, int> muscleRecoveryStatus,
  }) {
    int score = 100;
    List<String> factors = [];

    // 1. 휴식일 체크 (최근 7일 중)
    if (restDays == 0) {
      score -= 25;
      factors.add('최근 7일간 휴식 없음');
    } else if (restDays == 1) {
      score -= 10;
      factors.add('휴식일 부족 (${restDays}일)');
    } else if (restDays >= 2) {
      factors.add('적절한 휴식 (${restDays}일)');
    }

    // 2. 과훈련 체크
    if (avgVolume > 0) {
      final volumeRatio = recentVolume / avgVolume;
      if (volumeRatio > 1.5) {
        score -= 20;
        factors.add('운동량 급증 (${((volumeRatio - 1) * 100).toInt()}% 증가)');
      } else if (volumeRatio > 1.2) {
        score -= 10;
        factors.add('운동량 다소 증가');
      } else if (volumeRatio < 0.5 && recentVolume > 0) {
        factors.add('운동량 감소 중');
      }
    }

    // 3. 연속 고강도 훈련 체크
    if (consecutiveHighIntensityDays >= 3) {
      score -= 20;
      factors.add('${consecutiveHighIntensityDays}일 연속 고강도 훈련');
    } else if (consecutiveHighIntensityDays >= 2) {
      score -= 10;
      factors.add('연속 훈련 중 (${consecutiveHighIntensityDays}일)');
    }

    // 4. 부위별 회복 상태 체크
    int fatigueCount = 0;
    muscleRecoveryStatus.forEach((muscle, daysSince) {
      if (daysSince == 0) {
        fatigueCount++;
      } else if (daysSince == 1) {
        fatigueCount++;
      }
    });
    if (fatigueCount >= 3) {
      score -= 15;
      factors.add('여러 부위 회복 필요');
    }

    // 점수 범위 제한
    score = score.clamp(0, 100);

    // 상태 결정
    String status;
    Color statusColor;
    String recommendation;

    if (score >= 80) {
      status = '좋음';
      statusColor = const Color(0xFF4CAF50); // 녹색
      recommendation = '컨디션이 좋습니다! 오늘 운동을 시작해보세요.';
    } else if (score >= 60) {
      status = '양호';
      statusColor = const Color(0xFFFFC107); // 노란색
      recommendation = '가벼운 운동이나 회복 운동을 추천합니다.';
    } else if (score >= 40) {
      status = '주의';
      statusColor = const Color(0xFFFF9800); // 주황색
      recommendation = '휴식이 필요합니다. 스트레칭 정도만 권장합니다.';
    } else {
      status = '휴식 필요';
      statusColor = const Color(0xFFF44336); // 빨간색
      recommendation = '충분한 휴식을 취하세요. 과훈련 위험이 있습니다.';
    }

    return ConditionScore(
      score: score,
      status: status,
      statusColor: statusColor,
      recommendation: recommendation,
      factors: factors,
    );
  }
}

/// 부위별 회복 상태
class MuscleRecoveryStatus {
  final String muscleName;
  final int daysSinceLastWorkout;
  final RecoveryLevel recoveryLevel;
  final String? lastExerciseName;

  MuscleRecoveryStatus({
    required this.muscleName,
    required this.daysSinceLastWorkout,
    required this.recoveryLevel,
    this.lastExerciseName,
  });

  Color get statusColor {
    switch (recoveryLevel) {
      case RecoveryLevel.fullyRecovered:
        return const Color(0xFF4CAF50);
      case RecoveryLevel.recovered:
        return const Color(0xFF8BC34A);
      case RecoveryLevel.recovering:
        return const Color(0xFFFFC107);
      case RecoveryLevel.fatigued:
        return const Color(0xFFFF9800);
      case RecoveryLevel.needsRest:
        return const Color(0xFFF44336);
    }
  }

  String get statusText {
    switch (recoveryLevel) {
      case RecoveryLevel.fullyRecovered:
        return '완전 회복';
      case RecoveryLevel.recovered:
        return '회복됨';
      case RecoveryLevel.recovering:
        return '회복 중';
      case RecoveryLevel.fatigued:
        return '피로 누적';
      case RecoveryLevel.needsRest:
        return '휴식 필요';
    }
  }

  int get recoveryPercent {
    switch (recoveryLevel) {
      case RecoveryLevel.fullyRecovered:
        return 100;
      case RecoveryLevel.recovered:
        return 85;
      case RecoveryLevel.recovering:
        return 60;
      case RecoveryLevel.fatigued:
        return 35;
      case RecoveryLevel.needsRest:
        return 15;
    }
  }
}

enum RecoveryLevel {
  fullyRecovered, // 3일 이상
  recovered, // 2일
  recovering, // 1일
  fatigued, // 같은 날 또는 연속 운동
  needsRest, // 과부하
}

/// 최근 7일 운동 요약
class WeeklyStatusSummary {
  final int workoutCount;
  final int totalDuration; // 분
  final double totalVolume; // kg
  final int cardioMinutes;
  final int restDays;
  final double volumeChangePercent; // 지난주 대비

  WeeklyStatusSummary({
    required this.workoutCount,
    required this.totalDuration,
    required this.totalVolume,
    required this.cardioMinutes,
    required this.restDays,
    required this.volumeChangePercent,
  });
}

/// 목표 진행률
class GoalProgress {
  final String goalType; // 주간 운동 횟수, 월간 운동 시간 등
  final int current;
  final int target;
  final String unit;

  GoalProgress({
    required this.goalType,
    required this.current,
    required this.target,
    required this.unit,
  });

  double get progressPercent =>
      target > 0 ? (current / target * 100).clamp(0, 100) : 0;
}

/// PR(개인기록) 달성 정보
class PersonalRecord {
  final String exerciseName;
  final String recordType; // 무게, 횟수, 시간
  final double previousValue;
  final double newValue;
  final DateTime achievedAt;
  final String unit;

  PersonalRecord({
    required this.exerciseName,
    required this.recordType,
    required this.previousValue,
    required this.newValue,
    required this.achievedAt,
    required this.unit,
  });

  double get improvement => newValue - previousValue;
  double get improvementPercent => previousValue > 0
      ? ((newValue - previousValue) / previousValue * 100)
      : 0;
}

/// 위험 신호 알림
class WarningAlert {
  final WarningType type;
  final String message;
  final String suggestion;

  WarningAlert({
    required this.type,
    required this.message,
    required this.suggestion,
  });

  Color get alertColor {
    switch (type) {
      case WarningType.overtraining:
        return const Color(0xFFF44336);
      case WarningType.muscleOverload:
        return const Color(0xFFFF9800);
      case WarningType.noRest:
        return const Color(0xFFFF5722);
      case WarningType.volumeSpike:
        return const Color(0xFFE91E63);
    }
  }

  IconData get alertIcon {
    switch (type) {
      case WarningType.overtraining:
        return Icons.warning_amber_rounded;
      case WarningType.muscleOverload:
        return Icons.fitness_center;
      case WarningType.noRest:
        return Icons.bedtime;
      case WarningType.volumeSpike:
        return Icons.trending_up;
    }
  }
}

enum WarningType {
  overtraining, // 과훈련
  muscleOverload, // 특정 부위 과부하
  noRest, // 휴식 없음
  volumeSpike, // 볼륨 급증
}

/// 주관적 컨디션 로그
class SubjectiveConditionLog {
  final DateTime date;
  final ConditionFeeling feeling;
  final String? comment;

  SubjectiveConditionLog({
    required this.date,
    required this.feeling,
    this.comment,
  });

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'feeling': feeling.index,
    'comment': comment,
  };

  factory SubjectiveConditionLog.fromMap(Map<String, dynamic> map) {
    return SubjectiveConditionLog(
      date: DateTime.parse(map['date']),
      feeling: ConditionFeeling.values[map['feeling'] ?? 1],
      comment: map['comment'],
    );
  }
}

enum ConditionFeeling {
  great, // 😄 좋음
  normal, // 😐 보통
  tired, // 😵 피곤
}

/// 운동 추천
class WorkoutRecommendation {
  final String title;
  final String description;
  final List<String> suggestedMuscles;
  final int suggestedDuration; // 분
  final String intensity; // 저, 중, 고

  WorkoutRecommendation({
    required this.title,
    required this.description,
    required this.suggestedMuscles,
    required this.suggestedDuration,
    required this.intensity,
  });
}
