// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:neon_fire/models/saved_routine.dart';
import 'package:neon_fire/models/home_models/calendar_day.dart';
import 'package:neon_fire/models/home_models/workout_stats_model.dart';
import 'package:neon_fire/models/home_models/recommended_exercise_model.dart';
import 'package:neon_fire/services/home_service/recommendation_service_v2.dart';
import 'package:neon_fire/services/home_service/workout_stats_service.dart';
import 'package:neon_fire/services/home_service/calender_service.dart';

class HomeScreen extends StatefulWidget {
  final String userId; 
  final VoidCallback onLogout;
  final VoidCallback onNavigateToWorkout;
  final Function(String) navigateToPage;
  final List<SavedRoutine> savedRoutines;
  final Function(SavedRoutine) onStartWorkoutWithRoutine;

  const HomeScreen({
    Key? key,
    required this.userId, 
    required this.onLogout,
    required this.onNavigateToWorkout,
    required this.navigateToPage,
    required this.savedRoutines,
    required this.onStartWorkoutWithRoutine,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 🆕 서비스 인스턴스
  late final WorkoutStatsService _statsService = WorkoutStatsService();
  late final CalendarService _calendarService = CalendarService();
  late final RecommendationServiceV2 _recommendationService =
      RecommendationServiceV2();

  // 🆕 Firebase에서 가져올 데이터
  late List<CalendarDay> calendarDays = [];
  late List<WeeklyWorkoutData> weeklyWorkoutData = [];
  int consecutiveDays = 0;
  RecommendedExercise? recommendedExercise;

  // 로딩 상태
  bool isLoadingCalendar = true;
  bool isLoadingWeeklyData = true;
  bool isLoadingRecommendation = true;

  bool showCalendarModal = false;
  bool showRoutinesModal = false;
  int currentWeek = 0;
  String activeTab = '운동';

  final Color primaryColor = const Color(0xFFFF5757);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  /// 모든 데이터 로드
  Future<void> _loadAllData() async {
    await Future.wait([
      _loadCalendarData(),
      _loadWeeklyWorkoutData(),
      _loadConsecutiveDays(),
      _loadRecommendedExercise(),
    ]);
  }

  /// 캘린더 데이터 로드
  Future<void> _loadCalendarData() async {
    try {
      setState(() => isLoadingCalendar = true);

      final days = await _calendarService.generateMonthlyCalendar(widget.userId);

      setState(() {
        calendarDays = days;
        isLoadingCalendar = false;
      });
    } catch (e) {
      print('캘린더 데이터 로드 실패: $e');
      setState(() => isLoadingCalendar = false);
    }
  }

  /// 주간 운동 데이터 로드
  Future<void> _loadWeeklyWorkoutData() async {
    try {
      setState(() => isLoadingWeeklyData = true);

      final weekData =
          await _statsService.getWeeklyWorkoutData(widget.userId);

      setState(() {
        weeklyWorkoutData = weekData;
        isLoadingWeeklyData = false;
      });
    } catch (e) {
      print('주간 데이터 로드 실패: $e');
      setState(() => isLoadingWeeklyData = false);
    }
  }

  /// 연속 운동일 로드
  Future<void> _loadConsecutiveDays() async {
    try {
      final days =
          await _statsService.getConsecutiveWorkoutDays(widget.userId);

      setState(() => consecutiveDays = days);
    } catch (e) {
      print('연속 운동일 로드 실패: $e');
    }
  }

  /// 추천 운동 로드
  Future<void> _loadRecommendedExercise() async {
    try {
      setState(() => isLoadingRecommendation = true);

      final exercise =
          await _recommendationService. getRecommendedExerciseAdvanced(
        widget.userId,
      );

      setState(() {
        recommendedExercise = exercise;
        isLoadingRecommendation = false;
      });
    } catch (e) {
      print('추천 운동 로드 실패: $e');
      setState(() => isLoadingRecommendation = false);
    }
  }

  String _getCurrentMonthYear() {
    final today = DateTime.now();
    const monthNames = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    return '${today.year} ${monthNames[today.month - 1]}';
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Fixed Header
              SliverAppBar(
                backgroundColor: Colors.white,
                pinned: true,
                elevation: 0,
                toolbarHeight: 60,
                automaticallyImplyLeading: false,
                flexibleSpace: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () =>
                              widget.navigateToPage('프로틴 구매'),
                          icon: const Icon(Icons.shopping_cart,
                              color: Colors.black54),
                        ),
                        Row(
                          children: [
                            Image.asset('assets/images/logo.png',
                                width: 32, height: 32),
                            const SizedBox(width: 8),
                            const Text(
                              '프로해빗',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () =>
                              widget.navigateToPage('마이 페이지'),
                          icon: const Icon(Icons.person,
                              color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main Content
              SliverPadding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 24,
                  bottom: 160,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildRecommendedExerciseWidget(),
                    const SizedBox(height: 24),
                    _buildCalendarWidget(),
                    const SizedBox(height: 24),
                    _buildWorkoutChart(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ]),
                ),
              ),
            ],
          ),

          // Floating Protein Button
          Positioned(
            bottom: 130,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => widget.navigateToPage('프로틴 구매'),
              backgroundColor: primaryColor,
              child: const Icon(Icons.shopping_bag, color: Colors.white),
            ),
          ),

          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedExerciseWidget() {
    if (isLoadingRecommendation) {
      return _buildLoadingWidget();
    }

    if (recommendedExercise == null) {
      return _buildErrorWidget('추천 운동을 불러올 수 없습니다', _loadRecommendedExercise);
    }

    final exercise = recommendedExercise! ;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor. withOpacity(0.3), width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '추천 운동',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color: primaryColor, size: 18),
              const SizedBox(width: 6),
              Text(
                exercise.daysSinceLastWorkout == 0 || exercise.daysSinceLastWorkout > 100
                    ? '${exercise.muscleGroup} 운동은 어떠신가요?'
                    : '마지막 ${exercise.muscleGroup} 운동 후 ${exercise.daysSinceLastWorkout}일 경과!',
                style: TextStyle(
                  fontSize: 14,
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey. shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: exercise.imagePath != null
                        ? Image.asset(
                            exercise. imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderIcon(),
                          )
                        : _buildPlaceholderIcon(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (exercise.description != null)
                        Text(
                          exercise.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors. grey.shade700,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor. withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              exercise.muscleGroup,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '강도: 고',
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton. icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('${exercise.exerciseName}을(를) 루틴에 추가했습니다!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('루틴에 추가하기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 수정된 캘린더 위젯
  Widget _buildCalendarWidget() {
    if (isLoadingCalendar) {
      return _buildLoadingWidget();
    }

    if (calendarDays.isEmpty) {
      return _buildErrorWidget('캘린더를 불러올 수 없습니다', _loadCalendarData);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '운동 캘린더',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _getCurrentMonthYear(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors. grey.shade600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: currentWeek > 0
                        ? () => setState(() => currentWeek--)
                        : null,
                    icon: const Icon(Icons.chevron_left, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: currentWeek < 5
                        ? () => setState(() => currentWeek++)
                        : null,
                    icon: const Icon(Icons. chevron_right, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() => showCalendarModal = true),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size. zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '전체보기',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors. grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendarGrid(currentWeek * 7, (currentWeek + 1) * 7),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  consecutiveDays == 0
                      ? '💪 오늘부터 시작해볼까요?'
                      : '🔥 ${consecutiveDays}일 연속 출석!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  consecutiveDays == 0
                      ? '첫 운동을 시작하면 연속 출석 기록이 시작됩니다'
                      : '꾸준한 운동으로 목표를 달성해보세요',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(int start, int end) {
    final weekDays = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays
              .map((day) => SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: calendarDays
              .sublist(start, (end). clamp(0, calendarDays.length))
              .map((day) => _buildCalendarDay(day))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCalendarDay(CalendarDay day) {
    Color?  backgroundColor;
    Color textColor = Colors.black87;
    FontWeight fontWeight = FontWeight.normal;

    if (day.isToday) {
      backgroundColor = Colors.blue.shade100;
      textColor = Colors.blue.shade600;
      fontWeight = FontWeight.w500;
    } else if (day.hasWorkout) {
      backgroundColor = primaryColor;
      textColor = Colors.white;
      fontWeight = FontWeight.w500;
    } else if (! day.isCurrentMonth) {
      textColor = Colors.grey.shade400;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 14,
            color: textColor,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }

  // 🆕 수정된 운동 차트 위젯
  Widget _buildWorkoutChart() {
    if (isLoadingWeeklyData) {
      return _buildLoadingWidget();
    }

    if (weeklyWorkoutData.isEmpty) {
      return _buildErrorWidget('운동 데이터를 불러올 수 없습니다', _loadWeeklyWorkoutData);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '한 주간 운동시간',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 2,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '운동시간',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 30,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors. grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: 30,
                      getTitlesWidget: (value, meta) {
                        String text;
                        if (value == 0) text = '0분';
                        else if (value == 30) text = '30분';
                        else if (value == 60) text = '1시간';
                        else if (value == 120) text = '2시간';
                        else if (value >= 180) text = '3시간+';
                        else return Container();

                        return Text(
                          text,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value. toInt() >= 0 &&
                            value.toInt() < weeklyWorkoutData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              weeklyWorkoutData[value.toInt()]. day,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors. grey.shade600,
                              ),
                            ),
                          );
                        }
                        return Container();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade300),
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: _getMaxYValue(),
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklyWorkoutData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(
                              e.key.toDouble(),
                              e.value. minutes. toDouble(),
                            ))
                        .toList(),
                    isCurved: true,
                    color: primaryColor,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: primaryColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => widget.navigateToPage('성과 확인'),
            child: Text(
              '자세히보기',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

   // 최대 Y값 계산
  double _getMaxYValue() {
    if (weeklyWorkoutData.isEmpty) return 180;
    final maxMinutes =
        weeklyWorkoutData. map((w) => w.minutes).reduce((a, b) => a > b ? a : b);
    if (maxMinutes == 0) return 180;
    // 최대값의 120% 또는 최소 180
    return (maxMinutes * 1.2).clamp(180, double.infinity);
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => widget.navigateToPage('운동'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons. fitness_center, size: 20),
                SizedBox(width: 8),
                Text('운동 시작하기'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => setState(() => showRoutinesModal = true),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload, size: 20),
                SizedBox(width: 8),
                Text('루틴 불러오기'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    final items = [
      {'id': '운동', 'icon': Icons. play_arrow, 'label': '운동'},
      {'id': '상태확인', 'icon': Icons. assessment, 'label': '상태확인'},
      {'id': '성과확인', 'icon': Icons.bar_chart, 'label': '성과확인'},
      {'id': '식단', 'icon': Icons. restaurant, 'label': '식단'},
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
            final isActive = activeTab == item['id'];
            return InkWell(
              onTap: () {
                setState(() => activeTab = item['id'] as String);
                if (item['id'] != '운동') {
                  widget.navigateToPage(item['label'] as String);
                }
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

  // 헬퍼 위젯들
  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      height: 150,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget(String message, VoidCallback onRetry) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(
        Icons.fitness_center,
        size: 40,
        color: Colors.grey.shade600,
      ),
    );
  }

  // 기존의 캘린더 모달, 루틴 모달 등의 나머지 메서드들도 필요하면 추가
  void _showCalendarModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_getCurrentMonthYear()} 운동 캘린더'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '이번 달 운동 기록을 확인하세요.  출석한 날은 빨간색으로 표시됩니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors. grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFullCalendar(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildFullCalendar() {
    final weekDays = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays
              .map((day) => SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        ... List.generate(
          (calendarDays. length / 7).ceil(),
          (weekIndex) {
            final start = weekIndex * 7;
            final end = ((weekIndex + 1) * 7).clamp(0, calendarDays.length);
            if (start >= calendarDays.length) return Container();

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: calendarDays
                    .sublist(start, end)
                    .map((day) => _buildCalendarDay(day))
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }
  void _showRoutinesModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저장된 루틴'),
        content: SizedBox(
          width: double.maxFinite,
          child: widget.savedRoutines.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '저장된 루틴이 없습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors. grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onNavigateToWorkout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('새 루틴 만들기'),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '저장된 루틴을 선택하여 운동을 시작하세요.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView. builder(
                        shrinkWrap: true,
                        itemCount: widget.savedRoutines.length,
                        itemBuilder: (context, index) {
                          final routine = widget. savedRoutines[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(routine.name),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment. start,
                                children: [
                                  Text('${routine.workouts.length}개 운동'),
                                  Text(
                                    '${routine.createdAt.year}-${routine.createdAt. month.toString().padLeft(2, '0')}-${routine.createdAt. day.toString().padLeft(2, '0')} 저장',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.play_arrow),
                              onTap: () {
                                Navigator.of(context).pop();
                                widget
                                    .onStartWorkoutWithRoutine(routine);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onNavigateToWorkout();
                      },
                      child: const Text('새 루틴 만들기'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}