// lib/screens/profile_management_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
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
    final selectedSource = await showDialog<ImageSource>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('프로필 사진 선택'),
        content: const Text('어디서 사진을 선택하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(ImageSource.camera),
            child: const Row(
              children: [
                Icon(Icons.camera_alt, color: Color(0xFFFF5757)),
                SizedBox(width: 8),
                Text('카메라'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(ImageSource.gallery),
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

    if (selectedSource != null) {
      await _pickAndUploadProfileImage(selectedSource);
    }
  }

  /// 프로필 사진 선택 및 업로드
  Future<void> _pickAndUploadProfileImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
        preferredCameraDevice: CameraDevice.front,
      );

      if (pickedFile == null) {
        print('사용자가 이미지 선택을 취소했습니다');
        return;
      }

      print('선택된 이미지 경로: ${pickedFile.path}');

      if (!mounted) return;
      setState(() => _isUpdating = true);

      final imageFile = File(pickedFile.path);

      // 파일 존재 확인
      if (!await imageFile.exists()) {
        throw Exception('이미지 파일을 찾을 수 없습니다');
      }

      print('이미지 파일 크기: ${await imageFile.length()} bytes');

      // 앱 문서 디렉토리에 저장
      final appDir = await getApplicationDocumentsDirectory();
      final userImagesDir = Directory('${appDir.path}/user_profiles');
      
      // 디렉토리가 없으면 생성
      if (!await userImagesDir.exists()) {
        await userImagesDir.create(recursive: true);
        print('사용자 프로필 디렉토리 생성: ${userImagesDir.path}');
      }

      // 파일명 생성 (userId + 타임스탬프 + 원본 확장자)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(pickedFile.path);
      final fileName = '${_user.uid}_$timestamp$extension';
      final savedImagePath = '${userImagesDir.path}/$fileName';

      // 이미지 파일 복사
      final savedFile = await imageFile.copy(savedImagePath);
      print('이미지 저장 완료: $savedImagePath');

      // 기존 프로필 이미지가 있으면 삭제
      if (_user.profileImageUrl != null && _user.profileImageUrl!.isNotEmpty) {
        try {
          final oldFile = File(_user.profileImageUrl!);
          if (await oldFile.exists()) {
            await oldFile.delete();
            print('기존 프로필 이미지 삭제: ${_user.profileImageUrl}');
          }
        } catch (e) {
          print('기존 이미지 삭제 실패 (무시): $e');
        }
      }

      // Firestore에 로컬 파일 경로 저장
      await _authService.updateUserProfile(
        userId: _user.uid,
        profileImageUrl: savedImagePath,
      );

      print('Firestore 업데이트 완료: $savedImagePath');

      // 로컬 상태 업데이트
      if (!mounted) return;
      setState(() {
        _user = _user.copyWith(profileImageUrl: savedImagePath);
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
    } catch (e, stackTrace) {
      print('프로필 사진 저장 실패: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;
      setState(() => _isUpdating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 사진 저장 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// 별명 수정 다이얼로그
  Future<void> _showNicknameEditDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _NicknameEditDialog(initialValue: _user.nickname);
      },
    );

    if (result != null && result.isNotEmpty) {
      await _updateNickname(result);
    } else if (result != null && result.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('별명을 입력해주세요'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// 주소 수정 다이얼로그
  Future<void> _showAddressEditDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _AddressEditDialog(initialValue: _user.address);
      },
    );

    if (result != null && result.isNotEmpty) {
      await _updateAddress(result);
    }
  }

  /// 전화번호 수정 다이얼로그
  Future<void> _showPhoneEditDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _PhoneEditDialog(initialValue: _user.phone);
      },
    );

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

      if (!mounted) return;
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
      if (!mounted) return;
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

      if (!mounted) return;
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
      if (!mounted) return;
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

      await _authService.updateUserProfile(
        userId: _user.uid, 
        phone: newPhone,
      );

      if (!mounted) return;
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
      if (!mounted) return;
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

  /// 이미지 프로바이더 결정 (로컬 파일 또는 네트워크)
  ImageProvider _getImageProvider(String imagePath) {
    // 로컬 파일 경로인 경우
    if (imagePath.startsWith('/') || imagePath.contains('user_profiles')) {
      final file = File(imagePath);
      return FileImage(file);
    }
    // URL인 경우 (기존 Firebase Storage URL)
    return NetworkImage(imagePath);
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
          // 프로필 이미지 - 가운데 정렬
          Center(
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    image: _user.profileImageUrl != null &&
                            _user.profileImageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: _getImageProvider(_user.profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _user.profileImageUrl == null ||
                          _user.profileImageUrl!.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey.shade400,
                        )
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

// ====== 별도의 다이얼로그 위젯들 ======

/// 별명 수정 다이얼로그
class _NicknameEditDialog extends StatelessWidget {
  final String initialValue;

  const _NicknameEditDialog({required this.initialValue});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initialValue);

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
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            final newNickname = controller.text.trim();
            if (newNickname.isEmpty) {
              return;
            }
            Navigator.of(context).pop(newNickname);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5757),
          ),
          child: const Text('저장', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

/// 주소 수정 다이얼로그
class _AddressEditDialog extends StatefulWidget {
  final String initialValue;

  const _AddressEditDialog({required this.initialValue});

  @override
  State<_AddressEditDialog> createState() => _AddressEditDialogState();
}

class _AddressEditDialogState extends State<_AddressEditDialog> {
  late TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final newAddress = _controller.text.trim();
    if (newAddress.length < 5) {
      setState(() {
        _errorMessage = '상세 주소를 입력해주세요. (최소 5자)';
      });
      return;
    }
    Navigator.of(context).pop(newAddress);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('주소 수정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
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
              setState(() {
                final trimmed = value.trim();
                if (trimmed.length < 5) {
                  _errorMessage = '상세 주소를 입력해주세요. (최소 5자)';
                } else {
                  _errorMessage = null;
                }
              });
            },
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage!,
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
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _validateAndSubmit,
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
  }
}

/// 전화번호 수정 다이얼로그
class _PhoneEditDialog extends StatefulWidget {
  final String initialValue;

  const _PhoneEditDialog({required this.initialValue});

  @override
  State<_PhoneEditDialog> createState() => _PhoneEditDialogState();
}

class _PhoneEditDialogState extends State<_PhoneEditDialog> {
  late TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final newPhone = _controller.text.trim();
    final onlyDigits = newPhone.replaceAll(RegExp(r'\D'), '');
    final regex = RegExp(r'^010\d{8}$');

    if (!regex.hasMatch(onlyDigits)) {
      setState(() {
        _errorMessage = '올바른 휴대폰 번호를 입력해주세요. (010-1234-5678)';
      });
      return;
    }
    Navigator.of(context).pop(newPhone);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('전화번호 수정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
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
              setState(() {
                final onlyDigits = value.replaceAll(RegExp(r'\D'), '');
                final regex = RegExp(r'^010\d{8}$');

                if (!regex.hasMatch(onlyDigits)) {
                  _errorMessage = '올바른 휴대폰 번호를 입력해주세요. (010-1234-5678)';
                } else {
                  _errorMessage = null;
                }
              });
            },
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage!,
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
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _validateAndSubmit,
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
  }
}
