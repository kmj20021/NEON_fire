// lib/screens/performance_screen.dart
import 'package:flutter/material.dart';
import 'package:neon_fire/models/performance_models.dart';
import 'package:neon_fire/services/performance_service.dart';

class PerformanceScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onBack;
  final Function(String) navigateToPage;

  const PerformanceScreen({
    Key? key,
    required this.userId,
    required this.onBack,
    required this.navigateToPage,
  }) : super(key: key);

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final PerformanceService _service = PerformanceService();
  final Color primaryColor = const Color(0xFFFF5757);

  // 기간 선택
  PerformancePeriod selectedPeriod = PerformancePeriod.days30;

  // 데이터
  PerformanceSummary? summary;
  List<StrengthPerformance> strengthPerformances = [];
  List<PRRecord> prRecords = [];
  GoalAchievement? goalAchievement;
  VolumeIntensitySummary? volumeIntensity;
  List<BodyPartGrowth> bodyPartGrowth = [];
  ConsistencyScore? consistencyScore;
  SelfComparison? selfComparison;
  PerformanceComment? performanceComment;

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
        _service.getPerformanceSummary(widget.userId, selectedPeriod),
        _service.getStrengthPerformance(widget.userId, selectedPeriod),
        _service.getPRHistory(widget.userId),
        _service.getGoalAchievement(widget.userId),
        _service.getVolumeIntensitySummary(widget.userId, selectedPeriod),
        _service.getBodyPartGrowth(widget.userId, selectedPeriod),
        _service.getConsistencyScore(widget.userId, selectedPeriod),
        _service.getSelfComparison(widget.userId),
        _service.generatePerformanceComment(widget.userId, selectedPeriod),
      ]);

      setState(() {
        summary = results[0] as PerformanceSummary;
        strengthPerformances = results[1] as List<StrengthPerformance>;
        prRecords = results[2] as List<PRRecord>;
        goalAchievement = results[3] as GoalAchievement;
        volumeIntensity = results[4] as VolumeIntensitySummary;
        bodyPartGrowth = results[5] as List<BodyPartGrowth>;
        consistencyScore = results[6] as ConsistencyScore;
        selfComparison = results[7] as SelfComparison;
        performanceComment = results[8] as PerformanceComment;
        isLoading = false;
      });
    } catch (e) {
      print('데이터 로드 실패: $e');
      setState(() => isLoading = false);
    }
  }

  void _onPeriodChanged(PerformancePeriod period) {
    setState(() => selectedPeriod = period);
    _loadAllData();
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
          '성과 확인',
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
                        // 1. 기간 선택 버튼
                        _buildPeriodSelector(),
                        const SizedBox(height: 16),

                    // 2. 핵심 성과 요약 카드
                    _buildSummaryCard(),
                    const SizedBox(height: 16),

                    // 3. 최근 PR 카드
                    _buildPRCard(),
                    const SizedBox(height: 16),

                    // 4. 근력 운동 성과
                    _buildStrengthPerformanceCard(),
                    const SizedBox(height: 16),

                    // 5. 목표 달성 기록
                    _buildGoalAchievementCard(),
                    const SizedBox(height: 16),

                    // 6. 볼륨 & 강도 변화
                    _buildVolumeIntensityCard(),
                    const SizedBox(height: 16),

                    // 7. 부위별 성장 상태
                    _buildBodyPartGrowthCard(),
                    const SizedBox(height: 16),

                    // 8. 일관성 점수
                    _buildConsistencyCard(),
                    const SizedBox(height: 16),

                    // 9. 나 vs 과거 나
                    _buildSelfComparisonCard(),
                    const SizedBox(height: 16),

                        // 10. 자동 성과 코멘트
                        _buildPerformanceCommentCard(),
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
            final isActive = item['id'] == '성과확인';
            return InkWell(
              onTap: () {
                if (item['id'] != '성과확인') {
                  widget.navigateToPage(item['label'] as String);
                }
                // 성과확인은 현재 페이지이므로 아무것도 하지 않음
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

  /// 1. 기간 선택 버튼
  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PerformancePeriod.values.map((period) {
          final isSelected = period == selectedPeriod;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(period.label),
              selected: isSelected,
              onSelected: (_) => _onPeriodChanged(period),
              selectedColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? primaryColor : Colors.grey.shade300,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 2. 핵심 성과 요약 카드
  Widget _buildSummaryCard() {
    if (summary == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${selectedPeriod.label} 성과',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  '운동',
                  '${summary!.workoutCount}회',
                  summary!.workoutCountChange,
                  '회',
                ),
              ),
              Container(width: 1, height: 60, color: Colors.white24),
              Expanded(
                child: _buildSummaryItem(
                  '총 운동 시간',
                  summary!.formattedDuration,
                  summary!.durationChangeMinutes,
                  '분',
                ),
              ),
              Container(width: 1, height: 60, color: Colors.white24),
              Expanded(
                child: _buildSummaryItem(
                  '총 볼륨',
                  '${(summary!.totalVolume / 1000).toStringAsFixed(1)}t',
                  summary!.volumeChangePercent.round(),
                  '%',
                  isPercent: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    int change,
    String changeUnit, {
    bool isPercent = false,
  }) {
    final isPositive = change > 0;
    final changeText = isPositive
        ? '+$change$changeUnit'
        : '$change$changeUnit';
    final changeColor = isPositive
        ? Colors.greenAccent
        : (change < 0 ? Colors.orangeAccent : Colors.white70);

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (change != 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: changeColor,
              ),
              Text(
                changeText,
                style: TextStyle(
                  fontSize: 12,
                  color: changeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// 3. 최근 PR 카드
  Widget _buildPRCard() {
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
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                '최근 개인 기록',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'PR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (prRecords.isEmpty)
            _buildEmptyState(
              Icons.emoji_events_outlined,
              '아직 개인 기록이 없어요',
              '꾸준히 운동하면 PR이 기록됩니다!',
            )
          else
            ...prRecords.take(5).map((pr) => _buildPRItem(pr)),
        ],
      ),
    );
  }

  Widget _buildPRItem(PRRecord pr) {
    return Container(
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
            decoration: const BoxDecoration(
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
                Row(
                  children: [
                    Text(
                      pr.exerciseName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (pr.isNew) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${pr.value.toStringAsFixed(1)}${pr.unit} (${pr.recordTypeLabel})',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
              const SizedBox(height: 4),
              Text(
                pr.timeAgo,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 4. 근력 운동 성과 카드
  Widget _buildStrengthPerformanceCard() {
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
          const Row(
            children: [
              Text('💪', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '근력 운동 성과',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (strengthPerformances.isEmpty)
            _buildEmptyState(
              Icons.fitness_center_outlined,
              '근력 운동 기록이 없어요',
              '운동을 시작해보세요!',
            )
          else
            ...strengthPerformances.map((perf) => _buildStrengthItem(perf)),
        ],
      ),
    );
  }

  Widget _buildStrengthItem(StrengthPerformance perf) {
    final weightChange = perf.weightChange;
    final isImproved = weightChange > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  perf.exerciseName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isImproved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 14,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${weightChange.toStringAsFixed(1)}kg',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatChip(
                '최고 중량',
                '${perf.maxWeight.toStringAsFixed(1)}kg',
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                '최고 볼륨',
                '${perf.maxVolume.toStringAsFixed(0)}kg',
                Colors.purple,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                '1RM 추정',
                '${perf.estimated1RM.toStringAsFixed(1)}kg',
                Colors.orange,
              ),
            ],
          ),
          if (perf.previousMaxWeight != perf.maxWeight) ...[
            const SizedBox(height: 8),
            Text(
              '${perf.previousMaxWeight.toStringAsFixed(1)}kg → ${perf.maxWeight.toStringAsFixed(1)}kg',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 5. 목표 달성 기록 카드
  Widget _buildGoalAchievementCard() {
    if (goalAchievement == null) return const SizedBox.shrink();

    final goal = goalAchievement!;

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
          const Row(
            children: [
              Text('🎯', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '목표 달성 기록',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 이번 주 진행률
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '주 ${goal.targetCount}회 목표',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${goal.achievedCount}/${goal.targetCount}회',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: goal.isAchieved ? Colors.green : primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 프로그레스 바
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
                      colors: goal.isAchieved
                          ? [Colors.green, Colors.green.shade300]
                          : [primaryColor, primaryColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 스트릭 정보
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        goal.currentStreak > 0 ? '🔥' : '💪',
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${goal.currentStreak}주 연속',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '현재 스트릭',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        '${goal.bestStreak}주',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '최고 기록',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // 주간 히스토리
          if (goal.weeklyHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: goal.weeklyHistory.asMap().entries.map((entry) {
                final index = entry.key;
                final achieved = entry.value;
                return Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: achieved ? Colors.green : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        achieved ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${index + 1}주',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 6. 볼륨 & 강도 변화 카드
  Widget _buildVolumeIntensityCard() {
    if (volumeIntensity == null) return const SizedBox.shrink();

    final vi = volumeIntensity!;

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
          const Row(
            children: [
              Text('📊', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '볼륨 & 강도 변화',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '지난 기간 대비',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildChangeIndicator(
                  '평균 중량',
                  vi.avgWeightChangePercent,
                  Icons.fitness_center,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildChangeIndicator(
                  '총 볼륨',
                  vi.totalVolumeChangePercent,
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
          if (vi.currentAvgWeight > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '현재 평균 중량: ${vi.currentAvgWeight.toStringAsFixed(1)}kg',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChangeIndicator(
    String label,
    double changePercent,
    IconData icon,
    Color color,
  ) {
    final isPositive = changePercent > 0;
    final isNegative = changePercent < 0;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (changePercent != 0)
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: isPositive
                      ? Colors.green
                      : (isNegative ? Colors.orange : Colors.grey),
                ),
              Text(
                '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPositive
                      ? Colors.green
                      : (isNegative ? Colors.orange : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 7. 부위별 성장 상태 카드
  Widget _buildBodyPartGrowthCard() {
    if (bodyPartGrowth.isEmpty) return const SizedBox.shrink();

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
          const Row(
            children: [
              Text('🏋️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '부위별 성장 상태',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...bodyPartGrowth.map((growth) => _buildBodyPartItem(growth)),
        ],
      ),
    );
  }

  Widget _buildBodyPartItem(BodyPartGrowth growth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: growth.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: growth.statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(growth.statusEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      growth.bodyPart,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: growth.statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        growth.statusLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  growth.recommendation,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${growth.workoutCount}회',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (growth.volumeChangePercent != 0)
                Text(
                  '${growth.volumeChangePercent > 0 ? '+' : ''}${growth.volumeChangePercent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: growth.volumeChangePercent > 0
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 8. 일관성 점수 카드
  Widget _buildConsistencyCard() {
    if (consistencyScore == null) return const SizedBox.shrink();

    final cs = consistencyScore!;

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
          const Row(
            children: [
              Text('📅', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '운동 일관성',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // 점수 원
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: cs.scoreColor, width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: cs.scoreColor.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${cs.score}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: cs.scoreColor,
                      ),
                    ),
                    Text(
                      cs.scoreGrade,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.scoreColor,
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
                    Text(
                      cs.message,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildConsistencyBar(
                      '계획 대비 실천',
                      cs.planVsActualPercent,
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildConsistencyBar(
                      '운동 규칙성',
                      cs.intervalRegularity,
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${cs.totalPlannedDays}일',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '목표',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                Column(
                  children: [
                    Text(
                      '${cs.actualWorkoutDays}일',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '실천',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsistencyBar(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            Text(
              '${percent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (percent / 100).clamp(0, 1),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 9. 나 vs 과거 나 비교 카드
  Widget _buildSelfComparisonCard() {
    if (selfComparison == null) return const SizedBox.shrink();

    final sc = selfComparison!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌟', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '${sc.monthsAgo}개월 전보다',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildComparisonItem(
                  '운동 빈도',
                  sc.workoutFrequencyChange,
                  '%',
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildComparisonItem(
                  '최대 중량',
                  sc.maxWeightChange,
                  'kg',
                  Icons.fitness_center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.compare_arrows,
                  size: 20,
                  color: Colors.indigo.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  '${sc.previousWorkoutCount}회 → ${sc.currentWorkoutCount}회 (월간)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(
    String label,
    double change,
    String unit,
    IconData icon,
  ) {
    final isPositive = change > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: isPositive ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (change != 0)
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: isPositive ? Colors.green : Colors.orange,
                ),
              Text(
                '${isPositive ? '+' : ''}${change.toStringAsFixed(unit == 'kg' ? 1 : 0)}$unit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 10. 자동 성과 코멘트 카드
  Widget _buildPerformanceCommentCard() {
    if (performanceComment == null) return const SizedBox.shrink();

    final pc = performanceComment!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pc.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(pc.content, style: const TextStyle(fontSize: 15, height: 1.5)),
          if (pc.highlights.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pc.highlights.map((highlight) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    highlight,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pc.suggestion,
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
