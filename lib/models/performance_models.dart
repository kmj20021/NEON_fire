// lib/models/performance_models.dart
import 'package:flutter/material.dart';

/// 기간 선택 enum
enum PerformancePeriod {
  week7, // 최근 7일
  days30, // 최근 30일
  months3, // 최근 3개월
  all, // 전체
}

extension PerformancePeriodExtension on PerformancePeriod {
  String get label {
    switch (this) {
      case PerformancePeriod.week7:
        return '최근 7일';
      case PerformancePeriod.days30:
        return '최근 30일';
      case PerformancePeriod.months3:
        return '최근 3개월';
      case PerformancePeriod.all:
        return '전체';
    }
  }

  int get days {
    switch (this) {
      case PerformancePeriod.week7:
        return 7;
      case PerformancePeriod.days30:
        return 30;
      case PerformancePeriod.months3:
        return 90;
      case PerformancePeriod.all:
        return 365 * 10; // 10년
    }
  }
}

/// 기간별 성과 요약 모델
class PerformanceSummary {
  final int workoutCount;
  final int totalDurationMinutes;
  final double totalVolume;
  final double volumeChangePercent;
  final int workoutCountChange;
  final int durationChangeMinutes;

  PerformanceSummary({
    required this.workoutCount,
    required this.totalDurationMinutes,
    required this.totalVolume,
    required this.volumeChangePercent,
    required this.workoutCountChange,
    required this.durationChangeMinutes,
  });

  String get formattedDuration {
    final hours = totalDurationMinutes ~/ 60;
    final minutes = totalDurationMinutes % 60;
    if (hours > 0) {
      return '$hours시간 ${minutes}분';
    }
    return '$minutes분';
  }
}

/// 근력 운동 성과 모델
class StrengthPerformance {
  final String exerciseName;
  final int exerciseId;
  final double maxWeight; // 최고 무게
  final double previousMaxWeight; // 이전 최고 무게
  final double maxVolume; // 최고 볼륨
  final int maxReps; // 최고 반복수
  final double estimated1RM; // 1RM 추정치
  final double previous1RM; // 이전 1RM

  StrengthPerformance({
    required this.exerciseName,
    required this.exerciseId,
    required this.maxWeight,
    required this.previousMaxWeight,
    required this.maxVolume,
    required this.maxReps,
    required this.estimated1RM,
    required this.previous1RM,
  });

  double get weightChange => maxWeight - previousMaxWeight;
  double get rm1Change => estimated1RM - previous1RM;
}

/// 유산소 운동 성과 모델
class CardioPerformance {
  final String exerciseName;
  final int exerciseId;
  final int maxDurationMinutes; // 최장 시간
  final double maxDistance; // 최고 거리 (km)
  final double avgPace; // 평균 페이스 (분/km)
  final double previousAvgPace; // 이전 평균 페이스
  final int totalSessions; // 총 세션 수

  CardioPerformance({
    required this.exerciseName,
    required this.exerciseId,
    required this.maxDurationMinutes,
    required this.maxDistance,
    required this.avgPace,
    required this.previousAvgPace,
    required this.totalSessions,
  });

  double get paceChange => previousAvgPace - avgPace; // 감소가 좋음
}

/// 개인 기록 (PR) 히스토리 모델
class PRRecord {
  final String exerciseName;
  final int exerciseId;
  final String recordType; // 'weight', 'reps', 'duration', 'volume'
  final double value;
  final double previousValue;
  final String unit;
  final DateTime achievedAt;
  final bool isNew; // 최근 기록 여부

  PRRecord({
    required this.exerciseName,
    required this.exerciseId,
    required this.recordType,
    required this.value,
    required this.previousValue,
    required this.unit,
    required this.achievedAt,
    this.isNew = false,
  });

  double get improvement => value - previousValue;

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(achievedAt);

    if (diff.inDays == 0) {
      return '오늘';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else if (diff.inDays < 30) {
      return '${diff.inDays ~/ 7}주 전';
    } else {
      return '${diff.inDays ~/ 30}개월 전';
    }
  }

  String get recordTypeLabel {
    switch (recordType) {
      case 'weight':
        return '최고 중량';
      case 'reps':
        return '최고 반복수';
      case 'duration':
        return '최장 시간';
      case 'volume':
        return '최고 볼륨';
      default:
        return '개인 기록';
    }
  }
}

/// 목표 달성 기록 모델
class GoalAchievement {
  final String goalType; // 'weekly', 'monthly'
  final int targetCount; // 목표 횟수
  final int achievedCount; // 달성 횟수
  final int currentStreak; // 현재 연속 달성
  final int bestStreak; // 최고 연속 기록
  final List<bool> weeklyHistory; // 최근 주간 달성 히스토리

  GoalAchievement({
    required this.goalType,
    required this.targetCount,
    required this.achievedCount,
    required this.currentStreak,
    required this.bestStreak,
    required this.weeklyHistory,
  });

  bool get isAchieved => achievedCount >= targetCount;
  double get progressPercent =>
      targetCount > 0 ? (achievedCount / targetCount * 100).clamp(0, 100) : 0;
}

/// 볼륨 & 강도 변화 데이터 모델
class VolumeIntensityData {
  final DateTime date;
  final double totalVolume;
  final double avgWeight;
  final double avgRPE; // 주관적 운동 강도

  VolumeIntensityData({
    required this.date,
    required this.totalVolume,
    required this.avgWeight,
    required this.avgRPE,
  });
}

/// 볼륨 & 강도 요약 모델
class VolumeIntensitySummary {
  final List<VolumeIntensityData> weeklyData;
  final double avgWeightChangePercent;
  final double totalVolumeChangePercent;
  final double currentAvgWeight;
  final double previousAvgWeight;

  VolumeIntensitySummary({
    required this.weeklyData,
    required this.avgWeightChangePercent,
    required this.totalVolumeChangePercent,
    required this.currentAvgWeight,
    required this.previousAvgWeight,
  });
}

/// 부위별 성장 지표 모델
class BodyPartGrowth {
  final String bodyPart; // 상체, 하체, 코어
  final GrowthStatus status;
  final int workoutCount; // 운동 횟수
  final double volumeChangePercent;
  final String recommendation;

  BodyPartGrowth({
    required this.bodyPart,
    required this.status,
    required this.workoutCount,
    required this.volumeChangePercent,
    required this.recommendation,
  });

  Color get statusColor {
    switch (status) {
      case GrowthStatus.excellent:
        return const Color(0xFF4CAF50); // 녹색
      case GrowthStatus.good:
        return const Color(0xFF8BC34A); // 연녹색
      case GrowthStatus.maintain:
        return const Color(0xFFFFC107); // 노란색
      case GrowthStatus.lacking:
        return const Color(0xFFFF9800); // 주황색
      case GrowthStatus.needsAttention:
        return const Color(0xFFF44336); // 빨간색
    }
  }

  String get statusEmoji {
    switch (status) {
      case GrowthStatus.excellent:
        return '🟢';
      case GrowthStatus.good:
        return '🟢';
      case GrowthStatus.maintain:
        return '🟡';
      case GrowthStatus.lacking:
        return '🟠';
      case GrowthStatus.needsAttention:
        return '🔴';
    }
  }

  String get statusLabel {
    switch (status) {
      case GrowthStatus.excellent:
        return '성장 우수';
      case GrowthStatus.good:
        return '성장 중';
      case GrowthStatus.maintain:
        return '유지';
      case GrowthStatus.lacking:
        return '부족';
      case GrowthStatus.needsAttention:
        return '주의 필요';
    }
  }
}

enum GrowthStatus {
  excellent, // 매우 좋음
  good, // 좋음
  maintain, // 유지
  lacking, // 부족
  needsAttention, // 주의 필요
}

/// 일관성 점수 모델
class ConsistencyScore {
  final int score; // 0-100
  final double planVsActualPercent; // 계획 대비 실천률
  final double intervalRegularity; // 운동 간격 규칙성
  final int totalPlannedDays;
  final int actualWorkoutDays;
  final String message;

  ConsistencyScore({
    required this.score,
    required this.planVsActualPercent,
    required this.intervalRegularity,
    required this.totalPlannedDays,
    required this.actualWorkoutDays,
    required this.message,
  });

  Color get scoreColor {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFFFFC107);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String get scoreGrade {
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B+';
    if (score >= 60) return 'B';
    if (score >= 50) return 'C+';
    if (score >= 40) return 'C';
    return 'D';
  }
}

/// 과거 나 vs 현재 나 비교 모델
class SelfComparison {
  final int monthsAgo; // 비교 기간 (개월)
  final double workoutFrequencyChange; // 운동 빈도 변화율
  final double maxWeightChange; // 최대 중량 변화
  final double totalVolumeChange; // 총 볼륨 변화
  final double avgDurationChange; // 평균 운동 시간 변화
  final int previousWorkoutCount;
  final int currentWorkoutCount;

  SelfComparison({
    required this.monthsAgo,
    required this.workoutFrequencyChange,
    required this.maxWeightChange,
    required this.totalVolumeChange,
    required this.avgDurationChange,
    required this.previousWorkoutCount,
    required this.currentWorkoutCount,
  });
}

/// 성과 요약 코멘트 모델
class PerformanceComment {
  final String title;
  final String content;
  final List<String> highlights;
  final String suggestion;

  PerformanceComment({
    required this.title,
    required this.content,
    required this.highlights,
    required this.suggestion,
  });
}
