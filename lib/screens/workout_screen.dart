import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:neon_fire/models/exercise_models/exercise_model.dart';
import 'package:neon_fire/models/saved_routine.dart';
import 'package:neon_fire/services/exercise_services/exercise_service.dart';
import 'package:neon_fire/services/exercise_services/routine_service.dart';

class WorkoutScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onBack;
  final Function(String) navigateToPage;
  final Function(List<int>) onStartWorkout;

  const WorkoutScreen({
    Key? key,
    required this.userId,
    required this.onBack,
    required this.navigateToPage,
    required this.onStartWorkout,
  }) : super(key: key);

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final RoutineService _routineService = RoutineService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _routineNameController = TextEditingController();

  final Color primaryColor = const Color(0xFFFF5757);
  final List<String> categories = ['전체', '가슴', '등', '어깨', '하체', '코어', '팔'];

  String selectedCategory = '전체';
  String searchQuery = '';
  List<int> selectedWorkouts = [];
  String activeTab = '운동';

  List<ExerciseModel> allExercises = [];
  List<ExerciseModel> filteredExercises = [];
  bool isLoading = true;

  ExerciseModel? selectedExercise;
  bool showDetailModal = false;
  bool showSaveRoutineModal = false;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _routineNameController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => isLoading = true);

    try {
      final exercises = await _exerciseService. getAllExercises();

      setState(() {
        allExercises = exercises;
        _filterExercises();
        isLoading = false;
      });
    } catch (e) {
      print('운동 로드 실패: $e');
      setState(() => isLoading = false);
    }
  }

  void _filterExercises() {
    setState(() {
      filteredExercises = allExercises.where((exercise) {
        final matchesCategory = selectedCategory == '전체' ||
            exercise.bodyPart == selectedCategory;
        final matchesSearch = searchQuery. isEmpty ||
            exercise.name. toLowerCase().contains(searchQuery.toLowerCase()) ||
            (exercise.description ??  '')
                .toLowerCase()
                . contains(searchQuery.toLowerCase());

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      selectedCategory = category;
      _filterExercises();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      _filterExercises();
    });
  }

  void _toggleWorkoutSelection(int workoutId) {
    setState(() {
      if (selectedWorkouts.contains(workoutId)) {
        selectedWorkouts.remove(workoutId);
      } else {
        selectedWorkouts.add(workoutId);
      }
    });
  }

  void _showExerciseDetail(ExerciseModel exercise) {
    setState(() {
      selectedExercise = exercise;
      showDetailModal = true;
    });
  }

  Future<void> _saveRoutine() async {
    if (selectedWorkouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('운동을 선택해주세요.')),
      );
      return;
    }

    setState(() => showSaveRoutineModal = true);
  }

  Future<void> _confirmSaveRoutine() async {
    if (_routineNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context). showSnackBar(
        const SnackBar(content: Text('루틴 이름을 입력해주세요.')),
      );
      return;
    }

    final routine = SavedRoutine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _routineNameController.text.trim(),
      workouts: List. from(selectedWorkouts),
      createdAt: DateTime.now(),
    );

    final routineId = await _routineService.saveRoutine(widget.userId, routine);

    if (routineId != null) {
      setState(() {
        showSaveRoutineModal = false;
        _routineNameController.clear();
        selectedWorkouts.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('루틴이 저장되었습니다!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('루틴 저장에 실패했습니다.')),
        );
      }
    }
  }

  Color _getIntensityColor(String intensity) {
    switch (intensity) {
      case '저':
        return Colors.green. shade100;
      case '중':
        return Colors.yellow.shade100;
      case '고':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getIntensityTextColor(String intensity) {
    switch (intensity) {
      case '저':
        return Colors. green. shade800;
      case '중':
        return Colors.yellow.shade800;
      case '고':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
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
              // Header
              SliverAppBar(
                backgroundColor: Colors.white,
                pinned: true,
                elevation: 0,
                toolbarHeight: 60,
                leading: IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.black54),
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logo.png', width: 32, height: 32),
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
                centerTitle: true,
                actions: [
                  IconButton(
                    onPressed: () => widget.navigateToPage('마이 페이지'),
                    icon: const Icon(Icons.person, color: Colors.black54),
                  ),
                ],
              ),

              // Category & Search
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategorySearchDelegate(
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onCategoryChanged: _onCategoryChanged,
                  searchController: _searchController,
                  onSearchChanged: _onSearchChanged,
                  primaryColor: primaryColor,
                ),
              ),

              // Exercise List
              SliverPadding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16, // 수정됨: 운동 검색하기 박스 아래 여백 축소 (16 -> 8)
                  bottom: 180,
                ),
                sliver: isLoading
                    ? const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : filteredExercises.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment. center,
                                children: [
                                  Text(
                                    '검색 결과가 없습니다',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '다른 검색어나 카테고리를 시도해보세요',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final exercise = filteredExercises[index];
                                return _buildExerciseCard(exercise);
                              },
                              childCount: filteredExercises.length,
                            ),
                          ),
              ),
            ],
          ),

          // Fixed Bottom Actions
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: _buildBottomActions(),
          ),

          // Bottom Navigation
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

  Widget _buildExerciseCard(ExerciseModel exercise) {
    final isSelected = selectedWorkouts.contains(exercise.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 64,
              height: 64,
              color: Colors.grey.shade200,
              child: exercise.imagePath != null
                  ? Image.asset(
                      exercise.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.fitness_center,
                          size: 32,
                          color: Colors.grey.shade400,
                        );
                      },
                    )
                  : Icon(
                      Icons.fitness_center,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                if (exercise.description != null)
                  Text(
                    exercise.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors. grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildBadge(exercise.bodyPart, Colors.grey.shade200,
                        Colors.black87),
                    const SizedBox(width: 8),
                    _buildBadge(
                      '강도: ${exercise.intensity}',
                      _getIntensityColor(exercise.intensity),
                      _getIntensityTextColor(exercise.intensity),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              // Checkbox
              InkWell(
                onTap: () => _toggleWorkoutSelection(exercise.id),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Info Button
              IconButton(
                onPressed: () => _showExerciseDetail(exercise),
                icon: Icon(
                  Icons.info_outline,
                  color: Colors.grey.shade400,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Start Workout Button
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: selectedWorkouts.isEmpty
                          ? null
                          : () => widget.onStartWorkout(selectedWorkouts),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center, size: 20),
                          SizedBox(width: 8),
                          Text('운동 시작하기'),
                        ],
                      ),
                    ),
                  ),
                  if (selectedWorkouts.isNotEmpty)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape. circle,
                        ),
                        child: Text(
                          '${selectedWorkouts.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight. bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Save Routine Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: selectedWorkouts.isEmpty ?  null : _saveRoutine,
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
                      Icon(Icons.save_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('루틴 저장하기'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final items = [
      {'id': '운동', 'icon': Icons. play_arrow, 'label': '운동'},
      {'id': '상태확인', 'icon': Icons. assessment, 'label': '상태확인'},
      {'id': '성과확인', 'icon': Icons. bar_chart, 'label': '성과확인'},
      {'id': '식단', 'icon': Icons. restaurant, 'label': '식단'},
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
            final isActive = activeTab == item['id'];
            return InkWell(
              onTap: () {
                setState(() => activeTab = item['id'] as String);
                if (item['id'] != '운동') {
                  widget.navigateToPage(item['label'] as String);
                } else {
                  widget.onBack();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      color: isActive ? Colors.white : Colors. grey.shade600,
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

  // Modals will be shown using showDialog
  void _showDetailModalDialog() {
    if (selectedExercise == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedExercise!.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                selectedExercise!.description ?? '',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double. infinity,
                  height: 200,
                  color: Colors.grey.shade200,
                  child: selectedExercise! .imagePath != null
                      ? Image.asset(
                          selectedExercise!.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: Colors. grey.shade400,
                            );
                          },
                        )
                      : Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Badges
              Row(
                children: [
                  _buildBadge(
                    selectedExercise!.bodyPart,
                    Colors.grey.shade200,
                    Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    '강도: ${selectedExercise!.intensity}',
                    _getIntensityColor(selectedExercise! .intensity),
                    _getIntensityTextColor(selectedExercise!.intensity),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Detail Description
              if (selectedExercise!.detailDescription != null)
                Text(
                  selectedExercise!.detailDescription!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              const SizedBox(height: 20),

              // YouTube Button
              if (selectedExercise!.youtubeUrl != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final url = Uri.parse(selectedExercise! .youtubeUrl!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors. white,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('YouTube에서 보기'),
                        SizedBox(width: 8),
                        Icon(Icons. arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaveRoutineModalDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '루틴 저장하기',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight. bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '선택한 운동들을 루틴으로 저장합니다.  루틴 이름을 입력해주세요.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // Selected Exercises
              Text(
                '선택된 운동 (${selectedWorkouts.length}개)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: selectedWorkouts.length,
                  itemBuilder: (context, index) {
                    final workoutId = selectedWorkouts[index];
                    final exercise = allExercises.firstWhere(
                      (e) => e.id == workoutId,
                      orElse: () => allExercises.first,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  exercise.bodyPart,
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
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Routine Name Input
              const Text(
                '루틴 이름',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _routineNameController,
                decoration: InputDecoration(
                  hintText: '예: 상체 운동 루틴',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                maxLength: 20,
              ),
              const SizedBox(height: 16),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _routineNameController.clear();
                      },
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _confirmSaveRoutine();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('저장하기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Category & Search Delegate
class _CategorySearchDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategoryChanged;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final Color primaryColor;

  _CategorySearchDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this. searchController,
    required this. onSearchChanged,
    required this.primaryColor,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(
        left: 16,    // 여백조절: 운동부위 박스 왼쪽 여백
        right: 16,   // 여백조절: 운동부위 박스 오른쪽 여백
        top: 8,      // 여백조절: 운동부위 박스 상단 여백
        bottom: 0,   // 여백조절: 운동부위 박스 하단 여백
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '운동 부위',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12), // 여백조절: '운동 부위' 텍스트와 카테고리 칩 사이 간격
          SizedBox(
            height: 40, // 여백조절: 카테고리 칩 영역 높이
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8), // 여백조절: 카테고리 칩들 사이 간격
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) onCategoryChanged(category);
                    },
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? primaryColor : Colors.grey.shade300,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8), // 여백조절: 카테고리 칩과 검색박스 사이 간격
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: '운동 검색하기',
              prefixIcon: const Icon(Icons. search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, // 여백조절: 검색박스 내부 좌우 여백
                vertical: 3,    // 여백조절: 검색박스 내부 상하 여백 축소 (12 -> 8)
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 150; // 수정됨: 검색박스 패딩 축소로 전체 높이 조정 (165 -> 157)

  @override
  double get minExtent => 150; // 수정됨: 검색박스 패딩 축소로 전체 높이 조정 (165 -> 157)

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}