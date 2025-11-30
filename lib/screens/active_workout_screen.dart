import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:neon_fire/models/exercise_models/exercise_model.dart';
import 'package:neon_fire/models/exercise_models/workout_set_model.dart';
import 'package:neon_fire/models/saved_routine.dart';
import 'package:neon_fire/services/exercise_services/exercise_service.dart';
import 'package:neon_fire/services/exercise_services/workout_session_service.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onBack; // 뒤로가기 콜백
  final Function(String) navigateToPage; // 페이지 네비게이션 콜백
  final SavedRoutine? selectedRoutine;
  final List<int>? selectedWorkouts;

  const ActiveWorkoutScreen({
    Key? key,
    required this.userId,
    required this.onBack,
    required this.navigateToPage,
    this.selectedRoutine,
    this.selectedWorkouts,
  }) : super(key: key);

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final WorkoutSessionService _sessionService = WorkoutSessionService();
  final Color primaryColor = const Color(0xFFFF5757);

  int workoutTime = 0;
  bool isTimerActive = true;
  Timer? _timer;
  DateTime? sessionStartTime; 

  List<ExerciseModel> currentWorkouts = [];
  List<ExerciseModel> availableWorkouts = [];
  List<int> currentWorkoutIds = [];
  List<WorkoutSession> workoutSessions = [];
  bool isLoading = true;
  bool showAddWorkoutDialog = false;
  bool isSaving = false; // 🆕 저장 중 상태


  @override
  void initState() {
    super.initState();
  sessionStartTime = DateTime.now(); // 🆕 세션 시작 시간 기록
    _initializeWorkouts();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isTimerActive) {
        setState(() => workoutTime++);
      }
    });
  }

    Future<void> _initializeWorkouts() async {
    setState(() => isLoading = true);

    try {
      final workoutIds = widget.selectedRoutine?.workouts ??
          widget.selectedWorkouts ??
          [1, 2, 3];

      final allExercises = await _exerciseService.getAllExercises();
      final exercises = await _exerciseService.getExercisesByIds(workoutIds);

      setState(() {
        currentWorkoutIds = workoutIds;
        currentWorkouts = exercises;
        availableWorkouts =
            allExercises.where((e) => !workoutIds.contains(e.id)).toList();
        _initializeSessions();
        isLoading = false;
      });
    } catch (e) {
      print('운동 초기화 실패: $e');
      setState(() => isLoading = false);
    }
  }

  void _initializeSessions() {
    workoutSessions = currentWorkouts.map((workout) {
      return WorkoutSession(
        workoutId: workout.id,
        sets: [
          WorkoutSet(),
          WorkoutSet(),
          WorkoutSet(),
        ],
      );
    }).toList();
  }

  WorkoutSession?  _getWorkoutSession(int workoutId) {
    try {
      return workoutSessions.firstWhere((s) => s.workoutId == workoutId);
    } catch (e) {
      return null;
    }
  }

  int _getTotalCompletedSets() {
    return workoutSessions.fold(
      0,
      (total, session) =>
          total + session.sets.where((set) => set.completed).length,
    );
  }

  int _getTotalSets() {
    return workoutSessions.fold(0, (total, session) => total + session.sets.length);
  }

  void _updateSetValue(int workoutId, int setIndex, String field, dynamic value) {
    setState(() {
      final sessionIndex =
          workoutSessions.indexWhere((s) => s. workoutId == workoutId);
      if (sessionIndex == -1) return;

      final session = workoutSessions[sessionIndex];
      final updatedSets = List<WorkoutSet>.from(session. sets);

      if (field == 'weight') {
        updatedSets[setIndex] = updatedSets[setIndex].copyWith(
          weight: (value as double). clamp(0, double.infinity),
        );
      } else if (field == 'reps') {
        updatedSets[setIndex] = updatedSets[setIndex].copyWith(
          reps: (value as int).clamp(0, 999),
        );
      }

      workoutSessions[sessionIndex] = session.copyWith(sets: updatedSets);
    });
  }

  void _toggleSetCompletion(int workoutId, int setIndex) {
    setState(() {
      final sessionIndex =
          workoutSessions.indexWhere((s) => s. workoutId == workoutId);
      if (sessionIndex == -1) return;

      final session = workoutSessions[sessionIndex];
      final updatedSets = List<WorkoutSet>.from(session.sets);
      final currentSet = updatedSets[setIndex];

      updatedSets[setIndex] = currentSet.copyWith(
        completed: !currentSet.completed,
        completedAt: ! currentSet.completed ?  DateTime.now() : null,
      );

      workoutSessions[sessionIndex] = session.copyWith(sets: updatedSets);
    });
  }

  void _addSet(int workoutId) {
    setState(() {
      final sessionIndex =
          workoutSessions.indexWhere((s) => s. workoutId == workoutId);
      if (sessionIndex == -1) return;

      final session = workoutSessions[sessionIndex];
      final updatedSets = List<WorkoutSet>.from(session.sets).. add(WorkoutSet());

      workoutSessions[sessionIndex] = session.copyWith(sets: updatedSets);
    });
  }

  void _removeLastSet(int workoutId) {
    setState(() {
      final sessionIndex =
          workoutSessions.indexWhere((s) => s.workoutId == workoutId);
      if (sessionIndex == -1) return;

      final session = workoutSessions[sessionIndex];
      if (session.sets.length <= 1) return;

      final updatedSets = List<WorkoutSet>.from(session.sets)..removeLast();

      workoutSessions[sessionIndex] = session.copyWith(sets: updatedSets);
    });
  }

  void _addWorkoutToSession(int workoutId) {
    setState(() {
      final newSession = WorkoutSession(
        workoutId: workoutId,
        sets: [WorkoutSet(), WorkoutSet(), WorkoutSet()],
      );

      workoutSessions.add(newSession);
      currentWorkoutIds.add(workoutId);

      // Update current and available workouts
      final exercise =
          availableWorkouts.firstWhere((e) => e.id == workoutId);
      currentWorkouts.add(exercise);
      availableWorkouts.removeWhere((e) => e. id == workoutId);

      showAddWorkoutDialog = false;
    });
  }

  String _formatTime(int seconds) {
    final hrs = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Firebase에 저장하는 함수
  Future<void> _completeWorkout() async {
    _timer?.cancel();
    setState(() {
      isTimerActive = false;
      isSaving = true;
    });

    try {
      // 운동 데이터 준비
      final exercisesData = <WorkoutSessionData>[];

      for (var session in workoutSessions) {
        final exercise = currentWorkouts.firstWhere(
          (e) => e.id == session.workoutId,
          orElse: () => currentWorkouts.first,
        );

        exercisesData.add(WorkoutSessionData(
          exerciseId: session.workoutId,
          exerciseName: exercise.name,
          sets: session.sets,
        ));
      }

      // Firebase에 저장
      final sessionId = await _sessionService.saveWorkoutSession(
        userId: widget.userId,
        routineName: widget.selectedRoutine?.name,
        duration: workoutTime,
        exercises: exercisesData,
      );

      setState(() => isSaving = false);

      if (sessionId != null) {
        // 저장 성공
        if (!mounted) return;
        
        showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('운동 완료!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('운동 시간', _formatTime(workoutTime)),
              const SizedBox(height: 8),
              _buildStatRow(
                '완료한 세트',
                '${_getTotalCompletedSets()}/${_getTotalSets()}',
              ),
              const SizedBox(height: 8),
              _buildStatRow('운동 종목', '${currentWorkouts.length}개'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_done, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '운동 기록이 저장되었습니다!',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                context.go('/home'); // 홈 화면으로 이동
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
      } else {
        // 저장 실패
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('운동 기록 저장에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류 발생: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

    Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: false, // 키보드가 올라와도 네비게이션바 고정
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                backgroundColor: Colors.white,
                pinned: true,
                elevation: 0,
                toolbarHeight: 60,
                leading: IconButton(
                  onPressed: () => _showExitConfirmation(),
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

              // Timer Header
              SliverPersistentHeader(
                pinned: true,
                delegate: _TimerHeaderDelegate(
                  workoutTime: workoutTime,
                  formatTime: _formatTime,
                  isTimerActive: isTimerActive,
                  onToggleTimer: () =>
                      setState(() => isTimerActive = !isTimerActive),
                  completedSets: _getTotalCompletedSets(),
                  totalSets: _getTotalSets(),
                  routineName: widget.selectedRoutine?. name ?? '운동 세션',
                  primaryColor: primaryColor,
                ),
              ),

              // Main Content
              SliverPadding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 180,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Workout List
                    ... currentWorkouts.map((workout) {
                      final session = _getWorkoutSession(workout.id);
                      if (session == null) return const SizedBox();
                      return _buildWorkoutCard(workout, session);
                    }),

                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            ],
          ),

          // Add Workout Button
          Positioned(
            bottom: 130,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: OutlinedButton.icon(
                onPressed: () => _showAddWorkoutDialog(),
                icon: Icon(Icons.add, size: 20, color: primaryColor),
                label: Text(
                  '운동 추가',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: BorderSide(color: primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigation(),
          ),


          // 🆕 저장 중 오버레이
          if (isSaving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('운동 기록 저장 중...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(ExerciseModel workout, WorkoutSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey.shade200,
                  child: workout.imagePath != null
                      ? Image.asset(
                          workout.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.fitness_center,
                              size: 24,
                              color: Colors.grey.shade400,
                            );
                          },
                        )
                      : Icon(
                          Icons.fitness_center,
                          size: 24,
                          color: Colors.grey.shade400,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      workout.bodyPart,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors. grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (session.sets.length > 1)
                IconButton(
                  onPressed: () => _removeLastSet(workout.id),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: '마지막 세트 삭제',
                ),
              if (workout.youtubeUrl != null)
                IconButton(
                  onPressed: () async {
                    final url = Uri.parse(workout.youtubeUrl!);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: Icon(Icons.open_in_new, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Sets
          ... session.sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value;
            return _buildSetRow(workout. id, index, set);
          }),

          // Add Set Button
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _addSet(workout.id),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('세트 추가'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              side: BorderSide(color: Colors.grey.shade300, style: BorderStyle.solid),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildSetRow(int workoutId, int setIndex, WorkoutSet set) {
    return SetRowWidget(
      key: ValueKey('set_${workoutId}_$setIndex'),
      workoutId: workoutId,
      setIndex: setIndex,
      set: set,
      primaryColor: primaryColor,
      onUpdateSetValue: _updateSetValue,
      onToggleCompletion: _toggleSetCompletion,
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isSaving ? null : _completeWorkout, // 🆕 저장 중엔 비활성화
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '운동 완료',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showAddWorkoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '운동 추가',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '세션에 추가할 운동을 선택하세요.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: availableWorkouts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fitness_center,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text('추가할 수 있는 운동이 없습니다.'),
                            const SizedBox(height: 8),
                            Text(
                              '모든 운동이 이미 세션에 추가되었습니다.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableWorkouts.length,
                        itemBuilder: (context, index) {
                          final workout = availableWorkouts[index];
                          return _buildAddWorkoutItem(workout);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddWorkoutItem(ExerciseModel workout) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _addWorkoutToSession(workout. id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 64,
                height: 64,
                color: Colors.grey. shade200,
                child: workout.imagePath != null
                    ? Image.asset(
                        workout.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.fitness_center,
                              size: 32, color: Colors.grey.shade400);
                        },
                      )
                    : Icon(Icons.fitness_center,
                        size: 32, color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  if (workout.description != null)
                    Text(
                      workout.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey. shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildBadge(workout.bodyPart),
                      const SizedBox(width: 8),
                      _buildBadge('강도: ${workout.intensity}'),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius. circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('운동 종료'),
        content: const Text('운동을 종료하시겠습니까?\n현재까지의 기록은 저장되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onBack();
            },
            child: Text('종료', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }
}

// Timer Header Delegate
class _TimerHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int workoutTime;
  final String Function(int) formatTime;
  final bool isTimerActive;
  final VoidCallback onToggleTimer;
  final int completedSets;
  final int totalSets;
  final String routineName;
  final Color primaryColor;

  _TimerHeaderDelegate({
    required this. workoutTime,
    required this.formatTime,
    required this.isTimerActive,
    required this.onToggleTimer,
    required this.completedSets,
    required this.totalSets,
    required this. routineName,
    required this.primaryColor,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            routineName,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatTime(workoutTime),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$completedSets/$totalSets 세트 완료',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors. grey.shade600,
                    ),
                  ),
                ],
              ),
              OutlinedButton. icon(
                onPressed: onToggleTimer,
                icon: Icon(
                  isTimerActive ? Icons.pause : Icons.play_arrow,
                  size: 16,
                ),
                label: Text(isTimerActive ? '일시정지' : '시작'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets. symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 120;

  @override
  double get minExtent => 120;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

// SetRowWidget - 각 세트의 입력 UI를 관리하는 StatefulWidget
class SetRowWidget extends StatefulWidget {
  final int workoutId;
  final int setIndex;
  final WorkoutSet set;
  final Color primaryColor;
  final Function(int, int, String, dynamic) onUpdateSetValue;
  final Function(int, int) onToggleCompletion;

  const SetRowWidget({
    Key? key,
    required this.workoutId,
    required this.setIndex,
    required this.set,
    required this.primaryColor,
    required this.onUpdateSetValue,
    required this.onToggleCompletion,
  }) : super(key: key);

  @override
  State<SetRowWidget> createState() => _SetRowWidgetState();
}

class _SetRowWidgetState extends State<SetRowWidget> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set.weight.toStringAsFixed(1),
    );
    _repsController = TextEditingController(
      text: widget.set.reps.toString(),
    );
  }

  @override
  void didUpdateWidget(SetRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부에서 값이 변경되면 컨트롤러도 업데이트
    if (oldWidget.set.weight != widget.set.weight) {
      _weightController.text = widget.set.weight.toStringAsFixed(1);
    }
    if (oldWidget.set.reps != widget.set.reps) {
      _repsController.text = widget.set.reps.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _updateWeight(double newValue) {
    widget.onUpdateSetValue(widget.workoutId, widget.setIndex, 'weight', newValue);
    _weightController.text = newValue.toStringAsFixed(1);
  }

  void _updateReps(int newValue) {
    widget.onUpdateSetValue(widget.workoutId, widget.setIndex, 'reps', newValue);
    _repsController.text = newValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Set Number
            SizedBox(
              width: 35,
              child: Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Text(
                  '${widget.setIndex + 1}세트',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),

            // Weight
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '무게(kg)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          onPressed: () {
                            final newValue = widget.set.weight - 0.5;
                            _updateWeight(newValue.clamp(0, double.infinity));
                          },
                          icon: const Icon(Icons.remove, size: 14),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            shape: const CircleBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      SizedBox(
                        width: 45,
                        child: TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: widget.primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.isEmpty) return;
                            final parsedValue = double.tryParse(value);
                            if (parsedValue != null) {
                              _updateWeight(parsedValue.clamp(0, double.infinity));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 3),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          onPressed: () {
                            final newValue = widget.set.weight + 0.5;
                            _updateWeight(newValue);
                          },
                          icon: const Icon(Icons.add, size: 14),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            shape: const CircleBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // Reps
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '횟수',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          onPressed: () {
                            final newValue = widget.set.reps - 1;
                            _updateReps(newValue.clamp(0, 999));
                          },
                          icon: const Icon(Icons.remove, size: 14),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            shape: const CircleBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      SizedBox(
                        width: 45,
                        child: TextField(
                          controller: _repsController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: widget.primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.isEmpty) return;
                            final parsedValue = int.tryParse(value);
                            if (parsedValue != null) {
                              _updateReps(parsedValue.clamp(0, 999));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 3),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          onPressed: () {
                            final newValue = widget.set.reps + 1;
                            _updateReps(newValue.clamp(0, 999));
                          },
                          icon: const Icon(Icons.add, size: 14),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            shape: const CircleBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // Complete Checkbox
            SizedBox(
              width: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '완료',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => widget.onToggleCompletion(
                      widget.workoutId,
                      widget.setIndex,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: widget.set.completed
                            ? widget.primaryColor
                            : Colors.transparent,
                        border: Border.all(
                          color: widget.set.completed
                              ? widget.primaryColor
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: widget.set.completed
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
