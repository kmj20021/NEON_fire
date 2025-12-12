// lib/screens/condition_status_screen.dart
import 'package:flutter/material.dart';
import 'package:neon_fire/models/home_models/condition_status_model.dart';
import 'package:neon_fire/services/home_services/condition_status_service.dart';

class ConditionStatusScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onBack;
  final Function(String) navigateToPage;

  const ConditionStatusScreen({
    Key? key,
    required this.userId,
    required this.onBack,
    required this.navigateToPage,
  }) : super(key: key);

  @override
  State<ConditionStatusScreen> createState() => _ConditionStatusScreenState();
}

class _ConditionStatusScreenState extends State<ConditionStatusScreen> {
  final ConditionStatusService _service = ConditionStatusService();
  final Color primaryColor = const Color(0xFFFF5757);

  // 데이터
  ConditionScore? conditionScore;
  List<MuscleRecoveryStatus> muscleRecoveryStatus = [];
  WeeklyStatusSummary? weeklySummary;
  List<GoalProgress> goalProgress = [];
  List<PersonalRecord> recentPRs = [];
  List<WarningAlert> warnings = [];
  WorkoutRecommendation? workoutRecommendation;
  SubjectiveConditionLog? todayLog;

  // 로딩 상태
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);

    try {
      final results = await Future.wait([
        _service.calculateConditionScore(widget.userId),
        _service.getMuscleRecoveryStatus(widget.userId),
        _service.getWeeklyStatusSummary(widget.userId),
        _service.getGoalProgress(widget.userId),
        _service.getRecentPRs(widget.userId),
        _service.analyzeWarnings(widget.userId),
        _service.getWorkoutRecommendation(widget.userId),
        _service.getTodayConditionLog(widget.userId),
      ]);

      setState(() {
        conditionScore = results[0] as ConditionScore;
        muscleRecoveryStatus = results[1] as List<MuscleRecoveryStatus>;
        weeklySummary = results[2] as WeeklyStatusSummary;
        goalProgress = results[3] as List<GoalProgress>;
        recentPRs = results[4] as List<PersonalRecord>;
        warnings = results[5] as List<WarningAlert>;
        workoutRecommendation = results[6] as WorkoutRecommendation;
        todayLog = results[7] as SubjectiveConditionLog?;
        isLoading = false;
      });
    } catch (e) {
      print('데이터 로드 실패: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          '상태 확인',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadAllData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. 오늘의 컨디션 점수
                        _buildConditionScoreCard(),
                        const SizedBox(height: 16),

                        // 2. 오늘 운동 추천 / 휴식 권장
                        _buildWorkoutRecommendationCard(),
                        const SizedBox(height: 16),

                        // 3. 위험 신호 알림 (있을 경우만)
                        if (warnings.isNotEmpty) ...[
                      _buildWarningAlertsCard(),
                      const SizedBox(height: 16),
                    ],

                    // 4. 최근 7일 요약
                    _buildWeeklySummaryCard(),
                    const SizedBox(height: 16),

                    // 5. 부위별 회복 상태
                    _buildMuscleRecoveryCard(),
                    const SizedBox(height: 16),

                    // 6. 목표 진행률
                    _buildGoalProgressCard(),
                    const SizedBox(height: 16),

                    // 7. 최근 성과 / PR
                    _buildRecentPRsCard(),
                    const SizedBox(height: 16),

                        // 8. 주관적 컨디션 로그
                        _buildConditionLogCard(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final items = [
      {'id': '운동', 'icon': Icons.fitness_center, 'label': '운동'},
      {'id': '상태확인', 'icon': Icons.assessment, 'label': '상태확인'},
      {'id': '성과확인', 'icon': Icons.bar_chart, 'label': '성과확인'},
      {'id': '마이페이지', 'icon': Icons.person, 'label': '마이페이지'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final isActive = item['id'] == '상태확인';
            return InkWell(
              onTap: () {
                if (item['id'] != '상태확인') {
                  widget.navigateToPage(item['label'] as String);
                }
                // 상태확인은 현재 페이지이므로 아무것도 하지 않음
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 20,
                      color: isActive ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 1. 오늘의 컨디션 점수 카드
  Widget _buildConditionScoreCard() {
    if (conditionScore == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            conditionScore!.statusColor.withOpacity(0.1),
            conditionScore!.statusColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: conditionScore!.statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // 점수 서클
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: conditionScore!.statusColor,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: conditionScore!.statusColor.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${conditionScore!.score}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: conditionScore!.statusColor,
                      ),
                    ),
                    Text(
                      '점',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: conditionScore!.statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            conditionScore!.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '오늘의 컨디션',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conditionScore!.recommendation,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (conditionScore!.factors.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: conditionScore!.factors.map((factor) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    factor,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 2. 운동 추천 카드
  Widget _buildWorkoutRecommendationCard() {
    if (workoutRecommendation == null) return const SizedBox.shrink();

    final rec = workoutRecommendation!;
    Color intensityColor;
    IconData intensityIcon;

    switch (rec.intensity) {
      case '고':
        intensityColor = const Color(0xFFFF5757);
        intensityIcon = Icons.local_fire_department;
        break;
      case '중':
        intensityColor = const Color(0xFFFFC107);
        intensityIcon = Icons.fitness_center;
        break;
      case '저':
        intensityColor = const Color(0xFF4CAF50);
        intensityIcon = Icons.self_improvement;
        break;
      default:
        intensityColor = const Color(0xFF9E9E9E);
        intensityIcon = Icons.hotel;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: intensityColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: intensityColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(intensityIcon, color: intensityColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: intensityColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rec.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rec.suggestedDuration > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildRecommendationChip(
                  Icons.timer,
                  '${rec.suggestedDuration}분',
                  intensityColor,
                ),
                const SizedBox(width: 8),
                _buildRecommendationChip(
                  Icons.speed,
                  '강도: ${rec.intensity}',
                  intensityColor,
                ),
              ],
            ),
          ],
          if (rec.suggestedMuscles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rec.suggestedMuscles.map((muscle) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: intensityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    muscle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: intensityColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => widget.navigateToPage('운동'),
              icon: const Icon(Icons.play_arrow),
              label: Text(rec.intensity == '휴식' ? '스트레칭 시작' : '운동 시작하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: intensityColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 3. 위험 신호 알림 카드
  Widget _buildWarningAlertsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                '주의가 필요해요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(warning.alertIcon, size: 20, color: warning.alertColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          warning.message,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade800,
                          ),
                        ),
                        Text(
                          warning.suggestion,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. 최근 7일 요약 카드
  Widget _buildWeeklySummaryCard() {
    if (weeklySummary == null) return const SizedBox.shrink();

    final summary = weeklySummary!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📊 최근 7일 요약',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (summary.volumeChangePercent != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: summary.volumeChangePercent > 0
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${summary.volumeChangePercent > 0 ? '+' : ''}${summary.volumeChangePercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: summary.volumeChangePercent > 0
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  Icons.fitness_center,
                  '운동 횟수',
                  '${summary.workoutCount}회',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  Icons.timer,
                  '총 시간',
                  '${summary.totalDuration}분',
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  Icons.trending_up,
                  '총 볼륨',
                  '${summary.totalVolume.toStringAsFixed(0)}kg',
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  Icons.hotel,
                  '휴식일',
                  '${summary.restDays}일',
                  Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 5. 부위별 회복 상태 카드
  Widget _buildMuscleRecoveryCard() {
    if (muscleRecoveryStatus.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💪 부위별 회복 상태',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...muscleRecoveryStatus
              .take(6)
              .map(
                (muscle) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          muscle.muscleName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: muscle.recoveryPercent / 100,
                              child: Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  color: muscle.statusColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Center(
                                child: Text(
                                  muscle.statusText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: muscle.recoveryPercent > 50
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 50,
                        child: Text(
                          muscle.daysSinceLastWorkout > 100
                              ? '-'
                              : '${muscle.daysSinceLastWorkout}일 전',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('🟢', '회복됨'),
              _buildLegendItem('🟡', '회복 중'),
              _buildLegendItem('🔴', '휴식 필요'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// 6. 목표 진행률 카드
  Widget _buildGoalProgressCard() {
    if (goalProgress.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 목표 진행률',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...goalProgress.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        goal.goalType,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${goal.current} / ${goal.target}${goal.unit}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: goal.progressPercent / 100,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                primaryColor.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${goal.progressPercent.toStringAsFixed(0)}% 달성',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 7. 최근 PR 카드
  Widget _buildRecentPRsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔥 최근 성과',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (recentPRs.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '아직 기록된 PR이 없어요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '꾸준히 운동하면 PR이 기록됩니다!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentPRs.map(
              (pr) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade50, Colors.orange.shade50],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pr.exerciseName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${pr.previousValue.toStringAsFixed(1)} → ${pr.newValue.toStringAsFixed(1)}${pr.unit}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${pr.improvement.toStringAsFixed(1)}${pr.unit}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 8. 주관적 컨디션 로그 카드
  Widget _buildConditionLogCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '😊 오늘 컨디션은 어떠신가요?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (todayLog != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Text(
                    _getFeelingEmoji(todayLog!.feeling),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '오늘 기록 완료!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        if (todayLog!.comment != null)
                          Text(
                            todayLog!.comment!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFeelingButton(ConditionFeeling.great, '😄', '좋음'),
                _buildFeelingButton(ConditionFeeling.normal, '😐', '보통'),
                _buildFeelingButton(ConditionFeeling.tired, '😵', '피곤'),
              ],
            ),
        ],
      ),
    );
  }

  String _getFeelingEmoji(ConditionFeeling feeling) {
    switch (feeling) {
      case ConditionFeeling.great:
        return '😄';
      case ConditionFeeling.normal:
        return '😐';
      case ConditionFeeling.tired:
        return '😵';
    }
  }

  Widget _buildFeelingButton(
    ConditionFeeling feeling,
    String emoji,
    String label,
  ) {
    return InkWell(
      onTap: () => _showConditionLogDialog(feeling),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  void _showConditionLogDialog(ConditionFeeling feeling) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(
              _getFeelingEmoji(feeling),
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 8),
            const Text('오늘의 컨디션'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: '간단한 메모를 남겨주세요 (선택)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _service.saveConditionLog(
                widget.userId,
                feeling,
                commentController.text.isEmpty ? null : commentController.text,
              );
              if (success) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('컨디션이 기록되었습니다!')));
                _loadAllData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
