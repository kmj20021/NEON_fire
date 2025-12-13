// lib/screens/condition_status_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 근육 부위 정보
class MusclePart {
  final String id;
  final String name;
  final String imagePath;
  final List<int> muscleIds; // 해당하는 근육 ID들
  final double left; // 왼쪽 위치
  final double top; // 위쪽 위치
  final double width; // 이미지 너비
  final double height; // 이미지 높이

  MusclePart({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.muscleIds,
    this.left = 0,
    this.top = 0,
    this.width = 250,
    this.height = 500,
  });
}

/// 회복 상태
enum RecoveryStatus {
  recent, // 최근 운동 (0-48시간) - 빨강
  recovering, // 회복 중 (48-72시간) - 노랑
  recovered, // 회복 완료 (72시간+) - 초록
}

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
  final Color primaryColor = const Color(0xFFFF5757);

  // 근육 부위별 회복 상태
  Map<String, RecoveryStatus> muscleRecoveryStatus = {};
  Map<String, DateTime?> lastWorkoutTime = {};
  bool isLoading = true;

  // 근육 부위 정의
  // 🔧 각 부위의 위치와 크기를 조정하려면 left, top, width, height 값을 수정하세요
  final List<MusclePart> muscleParts = [
    MusclePart(
      id: 'chest',
      name: '가슴',
      imagePath: 'assets/images/muscle/chest.png',
      muscleIds: [1, 2, 3], // 대흉근, 소흉근 등
      left: 0,
      top: 0,
      width: 250,
      height: 500,
    ),
    MusclePart(
      id: 'shoulders',
      name: '어깨',
      imagePath: 'assets/images/muscle/shoulders.png',
      muscleIds: [4, 5, 6], // 삼각근 전면, 측면, 후면
      left: 0,
      top: -10,
      width: 250,
      height: 500,
    ),
    MusclePart(
      id: 'arms',
      name: '팔',
      imagePath: 'assets/images/muscle/arms.png',
      muscleIds: [7, 8, 9, 10], // 이두, 삼두, 전완
      left: 0,
      top: 0,
      width: 250,
      height: 500,
    ),
    MusclePart(
      id: 'back',
      name: '등',
      imagePath: 'assets/images/muscle/back_no.png',
      muscleIds: [11, 12, 13, 14], // 광배근, 승모근, 척추기립근
      left: 0,
      top: -100,
      width: 250,
      height: 500,
    ),
    MusclePart(
      id: 'abs',
      name: '복근',
      imagePath: 'assets/images/muscle/abs.png',
      muscleIds: [15, 16], // 복직근, 복사근
      left: 0,
      top: -10,
      width: 250,
      height: 500,
    ),
    MusclePart(
      id: 'legs',
      name: '다리',
      imagePath: 'assets/images/muscle/legs.png',
      muscleIds: [17, 18, 19, 20, 21], // 대퇴사두근, 햄스트링, 둔근, 종아리
      left: 0,
      top: 0,
      width: 250,
      height: 500,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadRecoveryStatus();
  }

  /// 근육 부위별 마지막 운동 시간 및 회복 상태 계산
  Future<void> _loadRecoveryStatus() async {
    setState(() => isLoading = true);

    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      print('🔍 회복 상태 로딩 시작 - userId: ${widget.userId}');

      // 최근 7일간의 운동 세션 조회 (orderBy 제거하여 복합 인덱스 불필요)
      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('workout_sessions')
          .where(
            'startedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
          )
          .get();

      print('📊 조회된 세션 개수: ${sessionsSnapshot.docs.length}');

      // 근육 부위별 마지막 운동 시간 저장
      Map<String, DateTime> partLastWorkout = {};

      for (var sessionDoc in sessionsSnapshot.docs) {
        // 각 세션의 운동들 조회
        final exercisesSnapshot = await sessionDoc.reference
            .collection('exercises')
            .get();

        final sessionDate = (sessionDoc.data()['startedAt'] as Timestamp)
            .toDate();

        for (var exerciseDoc in exercisesSnapshot.docs) {
          final exerciseData = exerciseDoc.data();
          final exerciseId = exerciseData['exerciseId'] as int?;

          if (exerciseId == null) continue;

          // 이 운동이 속한 근육 부위 찾기
          for (var part in muscleParts) {
            if (part.muscleIds.contains(exerciseId) ||
                _isExerciseInMuscleGroup(exerciseId, part.id)) {
              // 아직 기록이 없거나, 더 최근 운동이면 업데이트
              if (!partLastWorkout.containsKey(part.id) ||
                  sessionDate.isAfter(partLastWorkout[part.id]!)) {
                partLastWorkout[part.id] = sessionDate;
              }
            }
          }
        }
      }

      // 회복 상태 계산
      Map<String, RecoveryStatus> recoveryMap = {};
      Map<String, DateTime?> lastWorkoutMap = {};

      for (var part in muscleParts) {
        final lastWorkout = partLastWorkout[part.id];
        lastWorkoutMap[part.id] = lastWorkout;

        if (lastWorkout == null) {
          // 7일간 운동 안함 = 회복 완료
          recoveryMap[part.id] = RecoveryStatus.recovered;
        } else {
          final hoursSince = now.difference(lastWorkout).inHours;

          if (hoursSince < 48) {
            recoveryMap[part.id] = RecoveryStatus.recent;
          } else if (hoursSince < 72) {
            recoveryMap[part.id] = RecoveryStatus.recovering;
          } else {
            recoveryMap[part.id] = RecoveryStatus.recovered;
          }
        }
      }

      setState(() {
        muscleRecoveryStatus = recoveryMap;
        lastWorkoutTime = lastWorkoutMap;
        isLoading = false;
      });

      print('✅ 회복 상태 로드 완료: ${recoveryMap.length}개 부위');
    } catch (e, stackTrace) {
      print('❌ 회복 상태 로드 실패: $e');
      print(stackTrace);
      setState(() => isLoading = false);
    }
  }

  /// 운동 ID로 근육 그룹 판별 (간단한 매핑)
  bool _isExerciseInMuscleGroup(int exerciseId, String muscleGroup) {
    // 운동 ID 범위로 근육 그룹 매핑
    switch (muscleGroup) {
      case 'chest':
        return exerciseId >= 1 && exerciseId <= 10; // 가슴 운동
      case 'shoulders':
        return exerciseId >= 201 && exerciseId <= 210; // 어깨 운동
      case 'arms':
        return (exerciseId >= 101 && exerciseId <= 110) || // 이두
            (exerciseId >= 4 && exerciseId <= 5); // 삼두
      case 'back':
        return exerciseId >= 101 && exerciseId <= 103; // 등 운동
      case 'abs':
        return exerciseId >= 401 && exerciseId <= 410; // 복근 운동
      case 'legs':
        return exerciseId >= 301 && exerciseId <= 310; // 하체 운동
      default:
        return false;
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
            Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 32,
                  height: 32,
                ),
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
              onPressed: () => widget.navigateToPage('마이페이지'),
              icon: const Icon(
                Icons.person,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadRecoveryStatus,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      children: [
                        // 상단 안내 카드
                        _buildInfoCard(),
                        const SizedBox(height: 16),

                        // 신체 시각화
                        _buildBodyVisualization(),
                        const SizedBox(height: 24),

                        // 범례
                        _buildLegend(),
                        const SizedBox(height: 24),

                        // 부위별 상세 정보
                        _buildMuscleDetails(),
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

  /// 상단 안내 카드
  Widget _buildInfoCard() {
    final recentCount = muscleRecoveryStatus.values
        .where((s) => s == RecoveryStatus.recent)
        .length;
    final recoveringCount = muscleRecoveryStatus.values
        .where((s) => s == RecoveryStatus.recovering)
        .length;
    final recoveredCount = muscleRecoveryStatus.values
        .where((s) => s == RecoveryStatus.recovered)
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: primaryColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                '오늘의 회복 상태',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusCount('최근 운동', recentCount, const Color(0xFFFF5757)),
              _buildStatusCount(
                '회복 중',
                recoveringCount,
                const Color(0xFFFFC107),
              ),
              _buildStatusCount(
                '회복 완료',
                recoveredCount,
                const Color(0xFF4CAF50),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCount(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  /// 신체 시각화 (이미지 기반)
  ///
  /// 🔧 개발자 조정 가이드:
  /// - 각 부위의 위치와 크기는 _buildMusclePart 호출 시 조정 가능
  /// - 전체 컨테이너 크기: width=250, height=500
  /// - 기본 body_base.png 이미지는 배경으로 사용 (선택사항)
  Widget _buildBodyVisualization() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 250,
          height: 500,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 🔧 배경 이미지 - 기본 신체 윤곽
              Image.asset(
                'assets/images/muscle/body_base.png',
                width: 250,
                height: 500,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('⚠️ body_base.png 로드 실패');
                  return const SizedBox.shrink();
                },
              ),

              // 🔧 각 부위별 이미지 오버레이
              // 위치와 크기는 muscleParts 리스트에서 각 부위별로 설정됩니다
              // 리스트로 생성하여 메모리 효율성 개선
              ...muscleParts.map((part) => _buildMusclePart(part: part)),
            ],
          ),
        ),
      ),
    );
  }

  /// 근육 부위 이미지 위젯 생성 (색상 오버레이 적용)
  ///
  /// [part]: 근육 부위 객체 (위치, 크기, 이미지 경로 포함)
  Widget _buildMusclePart({required MusclePart part}) {
    final status = muscleRecoveryStatus[part.id] ?? RecoveryStatus.recovered;
    final color = _getStatusColor(status);

    return Positioned(
      left: part.left,
      top: part.top,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcATop),
        child: Opacity(
          opacity: 0.7,
          child: Image.asset(
            part.imagePath,
            width: part.width,
            height: part.height,
            fit: BoxFit.contain,
            cacheWidth: part.width.toInt(), // 이미지 캐시 크기 제한
            errorBuilder: (context, error, stackTrace) {
              // 이미지 로드 실패 시 투명하게 처리 (텍스트 표시 안함)
              print('⚠️ 이미지 로드 실패: ${part.imagePath}');
              return SizedBox(width: part.width, height: part.height);
            },
          ),
        ),
      ),
    );
  }

  /// 상태별 색상 반환
  Color _getStatusColor(RecoveryStatus status) {
    switch (status) {
      case RecoveryStatus.recent:
        return const Color(0xFFFF5757); // 빨강
      case RecoveryStatus.recovering:
        return const Color(0xFFFFC107); // 노랑
      case RecoveryStatus.recovered:
        return const Color(0xFF4CAF50); // 초록
    }
  }

  /// 범례
  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '회복 상태 기준',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildLegendItem(const Color(0xFFFF5757), '최근 운동', '0-48시간 전 운동한 부위'),
          const SizedBox(height: 8),
          _buildLegendItem(const Color(0xFFFFC107), '회복 중', '48-72시간 전 운동한 부위'),
          const SizedBox(height: 8),
          _buildLegendItem(const Color(0xFF4CAF50), '회복 완료', '72시간 이상 지난 부위'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String title, String description) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 부위별 상세 정보
  Widget _buildMuscleDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '부위별 상세 정보',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1),
          ...muscleParts.map((part) {
            final status =
                muscleRecoveryStatus[part.id] ?? RecoveryStatus.recovered;
            final lastWorkout = lastWorkoutTime[part.id];

            return _buildMuscleDetailItem(part, status, lastWorkout);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMuscleDetailItem(
    MusclePart part,
    RecoveryStatus status,
    DateTime? lastWorkout,
  ) {
    final color = _getStatusColor(status);
    final statusText = _getStatusText(status);

    String timeText;
    if (lastWorkout == null) {
      timeText = '최근 7일간 운동 없음';
    } else {
      final hoursSince = DateTime.now().difference(lastWorkout).inHours;
      if (hoursSince < 24) {
        timeText = '${hoursSince}시간 전';
      } else {
        timeText = '${hoursSince ~/ 24}일 전';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(RecoveryStatus status) {
    switch (status) {
      case RecoveryStatus.recent:
        return '최근 운동';
      case RecoveryStatus.recovering:
        return '회복 중';
      case RecoveryStatus.recovered:
        return '회복 완료';
    }
  }

  /// 하단 네비게이션
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
            final isActive = item['id'] == '상태확인';
            return InkWell(
              onTap: () {
                if (item['id'] != '상태확인') {
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
}
