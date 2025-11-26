import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../models/saved_routine.dart';
import '../models/calendar_day.dart';
import '../models/workout_data.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onNavigateToWorkout;
  final Function(String) navigateToPage;
  final List<SavedRoutine> savedRoutines;
  final Function(SavedRoutine) onStartWorkoutWithRoutine;

  const HomeScreen({
    Key? key,
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
  late List<CalendarDay> calendarDays;
  bool showCalendarModal = false;
  bool showRoutinesModal = false;
  int currentWeek = 0;
  String activeTab = '운동';
  
  final List<WorkoutData> workoutData = [
    WorkoutData(day: '월', minutes: 45),
    WorkoutData(day: '화', minutes: 60),
    WorkoutData(day: '수', minutes: 90),
    WorkoutData(day: '목', minutes: 30),
    WorkoutData(day: '금', minutes: 120),
    WorkoutData(day: '토', minutes: 0),
    WorkoutData(day: '일', minutes: 75),
  ];

  final int consecutiveDays = 3;
  final Color primaryColor = const Color(0xFFFF5757);

  @override
  void initState() {
    super.initState();
    calendarDays = _generateCalendarDays();
  }

  List<CalendarDay> _generateCalendarDays() {
    final today = DateTime.now();
    final currentMonth = today.month - 1;
    final currentYear = today.year;
    
    final firstDay = DateTime(currentYear, currentMonth + 1, 1);
    final lastDay = DateTime(currentYear, currentMonth + 2, 0);
    
    final startDate = firstDay.subtract(Duration(days: firstDay.weekday % 7));
    
    final days = <CalendarDay>[];
    var currentDate = startDate;
    final random = Random();
    
    for (int i = 0; i < 21; i++) {
      final isCurrentMonth = currentDate.month == currentMonth + 1;
      final isToday = currentDate.year == today.year &&
          currentDate.month == today.month &&
          currentDate. day == today.day;
      final hasWorkout = random.nextDouble() > 0.6;
      
      days.add(CalendarDay(
        date: currentDate,
        day: currentDate.day,
        isCurrentMonth: isCurrentMonth,
        isToday: isToday,
        hasWorkout: isCurrentMonth && hasWorkout,
      ));
      
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return days;
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
          // Main Content
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => widget.navigateToPage('프로틴 구매'),
                          icon: const Icon(Icons.shopping_cart, color: Colors.black54),
                        ),
                        Row(
                          children: [
                            // 주석: appIcon 이미지는 assets에 추가 필요
                            // Image.asset('assets/images/app_icon.png', width: 32, height: 32),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '프로해빗',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors. black87,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => widget.navigateToPage('마이 페이지'),
                          icon: const Icon(Icons.person, color: Colors.black54),
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

  Widget _buildCalendarWidget() {
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
                    onPressed: currentWeek < 2
                        ? () => setState(() => currentWeek++)
                        : null,
                    icon: const Icon(Icons.chevron_right, size: 20),
                    padding: EdgeInsets. zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() => showCalendarModal = true),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets. zero,
                      minimumSize: Size. zero,
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
                  '🔥 $consecutiveDays일 연속 출석! ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '꾸준한 운동으로 목표를 달성해보세요',
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
                          color: Colors. grey.shade600,
                        ),
                      ),
                    ),
                  ))
              . toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: calendarDays
              .sublist(start, end)
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
      textColor = Colors. blue.shade600;
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

  Widget _buildWorkoutChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors. white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment. spaceBetween,
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
                      color: Colors.grey.shade200,
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
                        if (value. toInt() >= 0 && value.toInt() < workoutData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              workoutData[value.toInt()].day,
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
                maxY: 180,
                lineBarsData: [
                  LineChartBarData(
                    spots: workoutData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(
                              e.key.toDouble(),
                              e.value. minutes.toDouble(),
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
                color: Colors.grey. shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: widget.onNavigateToWorkout,
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
      {'id': '운동', 'icon': Icons.play_arrow, 'label': '운동'},
      {'id': '상태확인', 'icon': Icons. assessment, 'label': '상태확인'},
      {'id': '성과확인', 'icon': Icons. bar_chart, 'label': '성과확인'},
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
                padding: const EdgeInsets. symmetric(horizontal: 12, vertical: 8),
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

  // Calendar Modal
  void _showCalendarModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_getCurrentMonthYear()} 운동 캘린더'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '이번 달 운동 기록을 확인하세요.  출석한 날은 빨간색으로 표시됩니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey. shade600,
                ),
              ),
              const SizedBox(height: 16),
              _buildFullCalendar(),
            ],
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
          3,
          (weekIndex) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: calendarDays
                  .sublist(weekIndex * 7, (weekIndex + 1) * 7)
                  .map((day) => _buildCalendarDay(day))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Routines Modal
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
                        color: Colors.grey.shade600,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${routine.workouts.length}개 운동'),
                                  Text(
                                    '${routine. createdAt.year}-${routine.createdAt.month. toString().padLeft(2, '0')}-${routine.createdAt. day.toString().padLeft(2, '0')} 저장',
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
                                widget.onStartWorkoutWithRoutine(routine);
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