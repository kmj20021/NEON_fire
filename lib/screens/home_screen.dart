// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:neon_fire/models/saved_routine.dart';
import 'package:neon_fire/models/home_models/calendar_day.dart';
import 'package:neon_fire/models/home_models/workout_stats_model.dart';
import 'package:neon_fire/models/home_models/recommended_exercise_model.dart';
import 'package:neon_fire/services/home_services/recommendation_service_v2.dart';
import 'package:neon_fire/services/home_services/workout_stats_service.dart';
import 'package:neon_fire/services/home_services/calender_service.dart';

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
  int weeklyWorkoutDays = 0;
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
      _loadWeeklyWorkoutDays(),
      _loadRecommendedExercise(),
    ]);
  }

  /// 캘린더 데이터 로드 (현재 주)
  Future<void> _loadCalendarData() async {
    try {
      setState(() => isLoadingCalendar = true);

      // 현재 주 캘린더 로드
      final days = await _calendarService.generateCurrentWeekCalendar(widget.userId);

      setState(() {
        calendarDays = days;
        isLoadingCalendar = false;
        // 이번주 운동일 수 계산
        weeklyWorkoutDays = days.where((day) => day.hasWorkout).length;
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

      print('🔄 주간 운동 데이터 로드 시작 (userId: ${widget.userId})');
      final weekData =
          await _statsService.getWeeklyWorkoutData(widget.userId);

      print('📈 로드된 주간 데이터: ${weekData.map((d) => '${d.day}:${d.minutes}분').join(', ')}');

      setState(() {
        weeklyWorkoutData = weekData;
        isLoadingWeeklyData = false;
      });

      print('✅ 주간 데이터 setState 완료');
    } catch (e) {
      print('❌ 주간 데이터 로드 실패: $e');
      setState(() => isLoadingWeeklyData = false);
    }
  }

  /// 이번주 운동일 로드
  Future<void> _loadWeeklyWorkoutDays() async {
    try {
      // calendarDays가 이미 로드되어 있으면 계산
      if (calendarDays.isNotEmpty) {
        final workoutCount = calendarDays.where((day) => day.hasWorkout).length;
        setState(() => weeklyWorkoutDays = workoutCount);
      }
    } catch (e) {
      print('이번주 운동일 로드 실패: $e');
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
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _showFullCalendarModal,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '전체보기',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildWeekCalendarGrid(),
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
                  weeklyWorkoutDays == 0
                      ? '💪 오늘부터 시작해볼까요?'
                      : '🔥 이번주 ${weeklyWorkoutDays}일 출석',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weeklyWorkoutDays == 0
                      ? '첫 운동을 시작하면 출석 기록이 시작됩니다'
                      : '꾸준함이 가장 중요해요! 응원합니다!',
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

  /// 주간 캘린더 그리드 (월~일)
  Widget _buildWeekCalendarGrid() {
    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      children: [
        Row(
          children: weekDays
              .map((day) => Expanded(
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
          children: calendarDays
              .map((day) => Expanded(
                    child: _buildCalendarDay(day),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCalendarDay(CalendarDay day) {
    Color? backgroundColor;
    Color textColor = Colors.black87;
    FontWeight fontWeight = FontWeight.normal;
    Border? border;

    // 1순위: 운동한 날 - 0xFFFF5757 배경 + 흰색 글자
    if (day.hasWorkout) {
      backgroundColor = const Color(0xFFFF5757);
      textColor = Colors.white;
      fontWeight = FontWeight.w500;
      
      // 운동한 날이면서 오늘인 경우에도 배경색 유지
      if (day.isToday) {
        // 배경색은 그대로, 테두리는 추가하지 않음
        // 또는 약간 더 진한 테두리를 원한다면:
        // border = Border.all(color: const Color(0xFFCC4646), width: 2);
      }
    } 
    // 2순위: 오늘 (운동 안한 경우) - 0xFFFF5757 테두리
    else if (day.isToday) {
      border = Border.all(color: const Color(0xFFFF5757), width: 2);
      textColor = Colors.black87;
      fontWeight = FontWeight.w500;
    } 
    // 3순위: 이번 달이 아닌 날 - 회색 처리
    else if (!day.isCurrentMonth) {
      textColor = Colors.grey.shade400;
    }

    return AspectRatio(
      aspectRatio: 1, // 정사각형 유지
      child: Container(
        margin: const EdgeInsets.all(2), // 간격 추가
        decoration: BoxDecoration(
          color: backgroundColor,
          border: border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13, // 크기 약간 줄여서 확실히 보이도록
              color: textColor,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ),
    );
  }

  /// 전체 캘린더 모달 표시
  void _showFullCalendarModal() async {
    final now = DateTime.now();
    
    // 이번 달 운동 날짜 가져오기
    final workoutDates = await _calendarService.getWorkoutDatesForMonth(
      widget.userId,
      now.year,
      now.month,
    );
    
    // 이번 달 캘린더 생성
    final firstDay = DateTime(now.year, now.month, 1);
    final startDate = firstDay.subtract(Duration(days: firstDay.weekday % 7));
    final today = DateTime(now.year, now.month, now.day);
    
    final monthDays = <CalendarDay>[];
    var currentDate = startDate;
    
    for (int i = 0; i < 42; i++) {
      final isCurrentMonth = currentDate.month == now.month;
      final isToday = currentDate.year == today.year &&
          currentDate.month == today.month &&
          currentDate.day == today.day;
      final hasWorkout = workoutDates.contains(currentDate);
      
      monthDays.add(CalendarDay(
        date: currentDate,
        day: currentDate.day,
        isCurrentMonth: isCurrentMonth,
        isToday: isToday,
        hasWorkout: hasWorkout,
      ));
      
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    // 모달 표시
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${now.year}년 ${now.month}월',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFullMonthCalendar(monthDays),
            ],
          ),
        ),
      ),
    );
  }

  /// 월간 캘린더 그리드
  Widget _buildFullMonthCalendar(List<CalendarDay> monthDays) {
    final weekDays = ['일', '월', '화', '수', '목', '금', '토'];
    
    return Column(
      children: [
        // 요일 헤더
        Row(
          children: weekDays.map((day) => Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        // 6주 그리드
        ...List.generate(6, (weekIndex) {
          final start = weekIndex * 7;
          final end = start + 7;
          final weekDays = monthDays.sublist(start, end.clamp(0, monthDays.length));
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: weekDays.map((day) => Expanded(
                child: _buildCalendarDay(day),
              )).toList(),
            ),
          );
        }),
      ],
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
                    preventCurveOverShooting: true, // 곡선 오버슈팅(시간 음수) 방지
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
            onPressed: _showWeeklyWorkoutSummary,
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

  /// 주간 운동 요약 모달 표시
  void _showWeeklyWorkoutSummary() async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // 데이터 로드
    final summary = await _statsService.getWeeklyWorkoutSummary(widget.userId);

    // 로딩 다이얼로그 닫기
    if (!mounted) return;
    Navigator.of(context).pop();

    // 요약 정보 모달 표시
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.insights, color: primaryColor, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          '이번 주 운동 분석',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 주요 통계
                _buildSummaryCard(
                  '총 운동 시간',
                  '${summary.totalDuration ~/ 60}시간 ${summary.totalDuration % 60}분',
                  Icons.timer,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallSummaryCard(
                        '운동한 날',
                        '${summary.workoutDays}일',
                        Icons.calendar_today,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSmallSummaryCard(
                        '총 세트',
                        '${summary.totalSets}',
                        Icons.fitness_center,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallSummaryCard(
                        '총 볼륨',
                        '${summary.totalVolume.toStringAsFixed(0)}kg',
                        Icons.trending_up,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSmallSummaryCard(
                        '운동 종목',
                        '${summary.totalExercises}개',
                        Icons.list,
                        Colors.teal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // 인사이트
                _buildInsightSection(
                  '📊 인사이트',
                  [
                    if (summary.workoutDays > 0) ...[
                      '평균 운동 시간: ${summary.avgDuration.toStringAsFixed(0)}분',
                      '가장 열심히 한 요일: ${summary.mostActiveDay} (${summary.maxDailyDuration}분)',
                      if (summary.workoutDays >= 5)
                        '🔥 이번 주 ${summary.workoutDays}일 운동! 정말 대단해요!'
                      else if (summary.workoutDays >= 3)
                        '💪 꾸준히 하고 있어요! 조금만 더 힘내세요!'
                      else
                        '🌟 시작이 반이에요! 더 자주 운동해봐요!',
                    ] else
                      '이번 주는 아직 운동 기록이 없어요. 오늘부터 시작해볼까요?',
                  ],
                ),

                if (summary.topExercises.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInsightSection(
                    '🏆 이번 주 TOP 3 운동',
                    summary.topExercises
                        .asMap()
                        .entries
                        .map((e) => '${e.key + 1}. ${e.value} (${summary.exerciseCount[e.value]}회)')
                        .toList(),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.navigateToPage('성과 확인');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('전체 성과 확인하기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
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

  Widget _buildInsightSection(String title, List<String> insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...insights.map((insight) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 14)),
              Expanded(
                child: Text(
                  insight,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}