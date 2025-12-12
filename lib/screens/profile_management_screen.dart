// lib/screens/profile_management_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:neon_fire/services/auth_service.dart';
import 'package:neon_fire/models/app_user.dart';

class ProfileManagementScreen extends StatefulWidget {
  final AppUser user;
  final VoidCallback onBack;

  const ProfileManagementScreen({
    super.key,
    required this.user,
    required this.onBack,
  });

  @override
  State<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  late AppUser _user;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  /// 프로필 사진 선택 (카메라 또는 갤러리)
  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로필 사진 선택'),
        content: const Text('어디서 사진을 선택하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickAndUploadProfileImage(ImageSource.camera);
            },
            child: const Row(
              children: [
                Icon(Icons.camera_alt, color: Color(0xFFFF5757)),
                SizedBox(width: 8),
                Text('카메라'),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickAndUploadProfileImage(ImageSource.gallery);
            },
            child: const Row(
              children: [
                Icon(Icons.photo_library, color: Color(0xFFFF5757)),
                SizedBox(width: 8),
                Text('갤러리'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 프로필 사진 선택 및 업로드
  Future<void> _pickAndUploadProfileImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() => _isUpdating = true);

      final imageFile = File(pickedFile.path);
      final imageUrl = await _authService.uploadProfileImage(
        _user.uid,
        imageFile,
      );

      // Firestore 업데이트
      await _authService.updateUserProfile(
        userId: _user.uid,
        profileImageUrl: imageUrl,
      );

      // 로컬 상태 업데이트
      setState(() {
        _user = _user.copyWith(profileImageUrl: imageUrl);
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 사진이 업데이트되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 사진 업로드 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 별명 수정 다이얼로그
  Future<void> _showNicknameEditDialog() async {
    final controller = TextEditingController(text: _user.nickname);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('별명 수정'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: '새로운 별명을 입력하세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            maxLength: 20,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final newNickname = controller.text.trim();

                if (newNickname.isEmpty) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(const SnackBar(content: Text('별명을 입력해주세요')));
                  return;
                }

                Navigator.of(dialogContext).pop(newNickname);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5757),
              ),
              child: const Text('저장', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result != null && result.isNotEmpty) {
      await _updateNickname(result);
    }
  }

  /// 주소 수정 다이얼로그
  Future<void> _showAddressEditDialog() async {
    final controller = TextEditingController(text: _user.address);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        String? addressMessage;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('주소 수정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '상세 주소를 입력하세요 (최소 5자)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      setDialogState(() {
                        final trimmed = value.trim();
                        if (trimmed.length < 5) {
                          addressMessage = '상세 주소를 입력해주세요. (최소 5자)';
                        } else {
                          addressMessage = null;
                        }
                      });
                    },
                  ),
                  if (addressMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        addressMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF5757),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newAddress = controller.text.trim();

                    if (newAddress.length < 5) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('상세 주소를 입력해주세요. (최소 5자)')),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(newAddress);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5757),
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (result != null && result.isNotEmpty) {
      await _updateAddress(result);
    }
  }

  /// 전화번호 수정 다이얼로그
  Future<void> _showPhoneEditDialog() async {
    final controller = TextEditingController(text: _user.phone);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        String? phoneMessage;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('전화번호 수정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '휴대폰 번호 (010-1234-5678)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 13,
                    onChanged: (value) {
                      setDialogState(() {
                        // 010-1234-5678 형식 대략 체크
                        final onlyDigits = value.replaceAll(RegExp(r'\D'), '');
                        final regex = RegExp(r'^010\d{8}$');

                        if (!regex.hasMatch(onlyDigits)) {
                          phoneMessage = '올바른 휴대폰 번호를 입력해주세요. (010-1234-5678)';
                        } else {
                          phoneMessage = null;
                        }
                      });
                    },
                  ),
                  if (phoneMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        phoneMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF5757),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newPhone = controller.text.trim();
                    final onlyDigits = newPhone.replaceAll(RegExp(r'\D'), '');
                    final regex = RegExp(r'^010\d{8}$');

                    if (!regex.hasMatch(onlyDigits)) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('올바른 휴대폰 번호를 입력해주세요. (010-1234-5678)'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(newPhone);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5757),
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (result != null && result.isNotEmpty) {
      await _updatePhone(result);
    }
  }

  /// 별명 업데이트
  Future<void> _updateNickname(String newNickname) async {
    try {
      setState(() => _isUpdating = true);

      await _authService.updateUserProfile(
        userId: _user.uid,
        nickname: newNickname,
      );

      setState(() {
        _user = _user.copyWith(nickname: newNickname);
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('별명이 업데이트되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('별명 업데이트 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 주소 업데이트
  Future<void> _updateAddress(String newAddress) async {
    try {
      setState(() => _isUpdating = true);

      await _authService.updateUserProfile(
        userId: _user.uid,
        address: newAddress,
      );

      setState(() {
        _user = _user.copyWith(address: newAddress);
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('주소가 업데이트되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('주소 업데이트 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 전화번호 업데이트
  Future<void> _updatePhone(String newPhone) async {
    try {
      setState(() => _isUpdating = true);

      await _authService.updateUserProfile(userId: _user.uid, phone: newPhone);

      setState(() {
        _user = _user.copyWith(phone: newPhone);
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('전화번호가 업데이트되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('전화번호 업데이트 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: widget.onBack,
        ),
        title: const Text(
          '내 정보 / 주소 관리',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 사진 섹션
            _buildProfilePhotoSection(primaryColor),

            // 개인정보 섹션
            _buildSectionTitle('개인정보'),
            _buildInfoCard(
              icon: Icons.person_outline,
              label: '별명',
              value: _user.nickname.isNotEmpty ? _user.nickname : '미설정',
              onEdit: _isUpdating ? null : _showNicknameEditDialog,
            ),
            _buildInfoCard(
              icon: Icons.email_outlined,
              label: '이메일',
              value: _user.email,
              onEdit: null, // 이메일은 수정 불가
            ),

            // 주소 정보 섹션
            _buildSectionTitle('주소 정보'),
            _buildInfoCard(
              icon: Icons.location_on_outlined,
              label: '주소',
              value: _user.address.isNotEmpty ? _user.address : '미설정',
              onEdit: _isUpdating ? null : _showAddressEditDialog,
            ),
            _buildInfoCard(
              icon: Icons.phone_outlined,
              label: '전화번호',
              value: _user.phone.isNotEmpty ? _user.phone : '미설정',
              onEdit: _isUpdating ? null : _showPhoneEditDialog,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 프로필 사진 섹션
  Widget _buildProfilePhotoSection(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 프로필 이미지
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                  image: _user.profileImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_user.profileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _user.profileImageUrl == null
                    ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                    : null,
              ),
              // 카메라 버튼
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUpdating ? null : _showImageSourceDialog,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _user.nickname.isNotEmpty ? '${_user.nickname}님' : '사용자님',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '프로필 사진을 클릭하여 변경하세요',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// 섹션 제목
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  /// 정보 카드 (아이콘 추가)
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFFF5757), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFF5757).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Color(0xFFFF5757),
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
        ],
      ),
    );
  }
}
