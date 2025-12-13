// lib/screens/mypage.dart
import 'package:flutter/material.dart';
import 'package:neon_fire/services/auth_service.dart';
import 'package:neon_fire/models/app_user.dart';
import 'package:neon_fire/screens/login/profile_management_screen.dart';

class MyPageScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final Function(String) navigateToPage;

  const MyPageScreen({
    super.key,
    required this.onLogout,
    required this.navigateToPage,
  });

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final AuthService _authService = AuthService();
  AppUser? _user;
  bool _isLoading = true;
  bool _notificationEnabled = false; // 알림 설정 상태
  int? _expandedFaqIndex; // 확장된 FAQ 인덱스

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.fetchCurrentAppUser();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('유저 정보 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 프로필 관리 화면으로 이동
  void _navigateToProfileManagement() {
    if (_user == null) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => ProfileManagementScreen(
              user: _user!,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
        )
        .then((_) {
          // 돌아올 때 사용자 정보 새로고침
          _loadUserData();
        });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF5757);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          '마이페이지',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 섹션
                  GestureDetector(
                    onTap: _navigateToProfileManagement,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          // 프로필 이미지
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                              image: _user?.profileImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        _user!.profileImageUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _user?.profileImageUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          // 닉네임 및 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user?.nickname.isNotEmpty == true
                                      ? '${_user!.nickname}님'
                                      : '사용자님',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '내 정보 / 주소 관리',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _user?.email ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 계정 및 설정 섹션
                  _buildSectionTitle('계정 및 설정'),
                  _buildMenuItemWithToggle(
                    icon: Icons.notifications_none,
                    title: '알림 설정',
                    value: _notificationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationEnabled = value;
                      });
                      // 스낵바 표시
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value ? '알림이 켜졌습니다' : '알림이 꺼졌습니다'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  _buildMenuItemWithSubtitle(
                    icon: Icons.palette_outlined,
                    title: '화면 테마',
                    subtitle: '시스템 기본값 사용',
                    onTap: () {},
                  ),
                  _buildMenuItemWithSubtitle(
                    icon: Icons.language,
                    title: '언어 설정',
                    subtitle: '한국어',
                    onTap: () {},
                  ),

                  // 고객 지원 및 정보 섹션
                  _buildSectionTitle('고객 지원 및 정보'),
                  _buildFaqAccordion(),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    title: '서비스 약관',
                    onTap: () {},
                  ),

                  // 로그아웃 버튼
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '로그아웃',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    const primaryColor = Color(0xFFFF5757);
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
            final isActive = false; // 마이페이지는 네비게이션 바에 없음
            return InkWell(
              onTap: () {
                widget.navigateToPage(item['label'] as String);
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: Colors.black54, size: 24),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMenuItemWithSubtitle({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: Colors.black54, size: 24),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMenuItemWithToggle({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: Colors.black54, size: 24),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFFF5757),
        ),
      ),
    );
  }

  /// FAQ 아코디언 위젯
  Widget _buildFaqAccordion() {
    final faqs = [
      {
        'question': '운동 기록은 어떻게 하나요?',
        'answer':
            '홈 화면 하단의 "운동" 버튼을 누른 후, "운동 시작" 버튼을 클릭하면 운동을 기록할 수 있습니다. 운동 중에는 운동 종류, 무게, 횟수를 기록할 수 있습니다.',
      },
      {
        'question': '루틴은 어떻게 저장하나요?',
        'answer':
            '운동 화면에서 운동을 추가한 후, 화면 상단의 "루틴 저장" 버튼을 누르면 현재 운동 목록을 루틴으로 저장할 수 있습니다. 저장된 루틴은 홈 화면에서 불러와 사용할 수 있습니다.',
      },
      {
        'question': '회복 상태는 어떻게 확인하나요?',
        'answer':
            '하단 네비게이션 바의 "상태확인" 버튼을 누르면 근육 부위별 회복 상태를 확인할 수 있습니다. 각 부위는 색상으로 구분되며, 최근 운동 시간을 기준으로 회복 단계를 보여줍니다.',
      },
    ];

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // FAQ 헤더
          ListTile(
            leading: const Icon(
              Icons.help_outline,
              color: Colors.black54,
              size: 24,
            ),
            title: const Text(
              '고객센터/FAQ',
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
            trailing: Icon(
              _expandedFaqIndex != null
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 24,
              color: Colors.grey.shade400,
            ),
            onTap: () {
              setState(() {
                // 전체 열기/닫기 토글
                if (_expandedFaqIndex != null) {
                  _expandedFaqIndex = null;
                } else {
                  _expandedFaqIndex = 0;
                }
              });
            },
          ),
          // FAQ 목록
          if (_expandedFaqIndex != null)
            ...faqs.asMap().entries.map((entry) {
              final index = entry.key;
              final faq = entry.value;
              final isExpanded = _expandedFaqIndex == index;

              return Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5757).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Q',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF5757),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              faq['question']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: isExpanded
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                      onTap: () {
                        setState(() {
                          _expandedFaqIndex = isExpanded ? null : index;
                        });
                      },
                    ),
                    if (isExpanded)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        decoration: BoxDecoration(color: Colors.grey.shade50),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'A',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                faq['answer']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
