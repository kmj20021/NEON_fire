// lib/screens/performance_screen_refactored.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neon_fire/models/performance_models.dart';
import 'package:neon_fire/services/performance_controller.dart';
import 'package:neon_fire/widgets/performance_widgets.dart';

/// Performance Screen - MVC 패턴의 View (Main Screen)
/// Controller를 사용하여 UI를 렌더링
class PerformanceScreenMVC extends StatefulWidget {
  final String userId;
  final VoidCallback onBack;
  final Function(String) navigateToPage;

  const PerformanceScreenMVC({
    Key? key,
    required this.userId,
    required this.onBack,
    required this.navigateToPage,
  }) : super(key: key);

  @override
  State<PerformanceScreenMVC> createState() => _PerformanceScreenMVCState();
}

class _PerformanceScreenMVCState extends State<PerformanceScreenMVC> {
  late PerformanceController _controller;
  final Color primaryColor = const Color(0xFFFF5757);

  @override
  void initState() {
    super.initState();
    _controller = PerformanceController(userId: widget.userId);
    _controller.addListener(_onControllerUpdate);
    _controller.loadAllData();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: _controller.isLoading
          ? PerformanceLoadingScreen(primaryColor: primaryColor)
          : _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => widget.navigateToPage('내 참여'),
            icon: const Icon(
              Icons.shopping_cart,
              color: Colors.black54,
            ),
          ),
          const Text(
            '성과 확인',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          IconButton(
            onPressed: () => widget.navigateToPage('마이페이지'),
            icon: const Icon(
              Icons.person,
              color: Colors.black54,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _controller.loadAllData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 최근 운동 기록 보기 버튼 (가장 위로 이동)
                WorkoutHistoryButton(
                  onTap: _showWorkoutHistoryDialog,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),

                // 핵심 성과 요약 카드
                if (_controller.summary != null)
                  PerformanceSummaryCard(
                    summary: _controller.summary!,
                    primaryColor: primaryColor,
                  ),
                const SizedBox(height: 3),

                // 볼륨 & 강도 변화
                if (_controller.volumeIntensity != null)
                  VolumeIntensityCard(
                    volumeIntensity: _controller.volumeIntensity!,
                    primaryColor: primaryColor,
                  ),
                const SizedBox(height: 16),

                // 일관성 점수
                if (_controller.consistencyScore != null)
                  ConsistencyCard(
                    consistencyScore: _controller.consistencyScore!,
                    primaryColor: primaryColor,
                  ),
                const SizedBox(height: 16),

                // 자동 성과 코멘트
                if (_controller.performanceComment != null)
                  PerformanceCommentCard(
                    performanceComment: _controller.performanceComment!,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    final items = [
      {'id': '운동', 'icon': Icons.fitness_center, 'label': '운동'},
      {'id': '상태확인', 'icon': Icons.assessment, 'label': '상태확인'},
      {'id': '성과확인', 'icon': Icons.bar_chart, 'label': '성과확인'},
      {'id': '공동구매', 'icon': Icons.shopping_bag, 'label': '공동 구매'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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

  void _showWorkoutHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => WorkoutHistoryDialog(
        controller: _controller,
        primaryColor: primaryColor,
        onWorkoutTap: _showWorkoutDetailDialog,
      ),
    );
  }

  void _showWorkoutDetailDialog(Map<String, dynamic> workout) {
    final sessionId = workout['id'] as String;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '운동 상세 기록',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _controller.formatDate((workout['startedAt'] as Timestamp).toDate()),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // 운동 상세 리스트
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _controller.loadWorkoutDetails(sessionId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          '상세 기록을 불러올 수 없습니다',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    final exercises = snapshot.data ?? [];
                    if (exercises.isEmpty) {
                      return Center(
                        child: Text(
                          '운동 기록이 없습니다',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        final sets = exercise['sets'] as List<Map<String, dynamic>>;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        exercise['name'] ?? '운동',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...sets.asMap().entries.map((entry) {
                                  final setIndex = entry.key;
                                  final set = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 60,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${setIndex + 1}세트',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                '${set['weight'] ?? 0}kg',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '×',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${set['reps'] ?? 0}회',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
