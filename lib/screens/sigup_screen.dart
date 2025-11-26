// lib/screens/sign_up_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neon_fire/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // -----------------------------
  // 컨트롤러들
  // -----------------------------
  final _emailController = TextEditingController(); // ✅ 이메일
  final _nicknameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPwController = TextEditingController();

  final _authService = AuthService();

  // -----------------------------
  // 검증 상태
  // -----------------------------
  bool _emailValid = false;
  bool _emailChecked = false;
  String? _emailMessage;

  bool _nicknameValid = false;
  String? _nicknameMessage;

  bool _addressValid = false;
  String? _addressMessage;

  bool _phoneValid = false;
  bool _phoneVerified = false;
  String? _phoneMessage;

  bool _codeValid = false;
  String? _codeMessage;

  bool _passwordValid = false;
  String? _passwordMessage;

  bool _confirmPwValid = false;
  String? _confirmPwMessage;

  String? _errorMessage;

  // 포커스된 필드 이름
  String? _focusedField;

  // 인증번호 관련
  bool _isCodeSent = false;
  int _secondsLeft = 0;
  Timer? _timer;

  bool _isSigningUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nicknameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPwController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // -----------------------------
  // 실시간 입력 처리 & 검증
  // -----------------------------
  void _onChanged(String field, String value) {
    setState(() {
      _errorMessage = null;
    });

    switch (field) {
      case 'email':
        _validateEmail(value);
        break;
      case 'nickname':
        _validateNickname(value);
        break;
      case 'address':
        _validateAddress(value);
        break;
      case 'phone':
        _validatePhone(value);
        break;
      case 'code':
        _validateCode(value);
        break;
      case 'password':
        _validatePassword(value);
        // 비밀번호 바뀌면 확인도 다시 체크
        _validateConfirmPassword(_confirmPwController.text);
        break;
      case 'confirmPassword':
        _validateConfirmPassword(value);
        break;
    }
  }

  // 이메일 형식 체크
  void _validateEmail(String value) {
    final trimmed = value.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

    if (!emailRegex.hasMatch(trimmed)) {
      _emailValid = false;
      _emailMessage = '올바른 이메일 형식을 입력해주세요.';
    } else {
      _emailValid = true;
      _emailMessage = null;
    }
    _emailChecked = false; // 이메일 바뀌면 다시 중복확인 필요
  }

  void _validateNickname(String value) {
    final trimmed = value.trim();

    if (trimmed.length < 2) {
      _nicknameValid = false;
      _nicknameMessage = '닉네임은 2자 이상이어야 합니다.';
    } else if (trimmed.length > 20) {
      _nicknameValid = false;
      _nicknameMessage = '닉네임은 20자 이하여야 합니다.';
    } else if (!RegExp(r'^[가-힣a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      _nicknameValid = false;
      _nicknameMessage = '닉네임은 한글, 영문, 숫자, _만 사용 가능합니다.';
    } else {
      _nicknameValid = true;
      _nicknameMessage = null;
    }
  }

  void _validateAddress(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 5) {
      _addressValid = false;
      _addressMessage = '상세 주소를 입력해주세요.';
    } else {
      _addressValid = true;
      _addressMessage = null;
    }
  }

  void _validatePhone(String value) {
    // 010-1234-5678 형식 대략 체크
    final onlyDigits = value.replaceAll(RegExp(r'\D'), '');
    final regex = RegExp(r'^010\d{8}$');

    if (!regex.hasMatch(onlyDigits)) {
      _phoneValid = false;
      _phoneMessage = '올바른 휴대폰 번호를 입력해주세요.';
    } else {
      _phoneValid = true;
      _phoneMessage = null;
    }

    _phoneVerified = false;
    _isCodeSent = false;
    _secondsLeft = 0;
    _timer?.cancel();
  }

  void _validateCode(String value) {
    if (value.length == 6 && RegExp(r'^\d{6}$').hasMatch(value)) {
      _codeValid = true;
      _codeMessage = null;
    } else {
      _codeValid = false;
      _codeMessage = '인증번호 6자리를 입력해주세요.';
    }
  }

  void _validatePassword(String value) {
    if (value.length < 8) {
      _passwordValid = false;
      _passwordMessage = '비밀번호는 8자 이상이어야 합니다.';
    } else if (!RegExp(r'(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
      _passwordValid = false;
      _passwordMessage = '영문과 숫자를 모두 포함해야 합니다.';
    } else {
      _passwordValid = true;
      _passwordMessage = null;
    }
  }

  void _validateConfirmPassword(String value) {
    if (value != _passwordController.text) {
      _confirmPwValid = false;
      _confirmPwMessage = '비밀번호가 일치하지 않습니다.';
    } else if (value.isEmpty) {
      _confirmPwValid = false;
      _confirmPwMessage = '비밀번호를 한 번 더 입력해주세요.';
    } else {
      _confirmPwValid = true;
      _confirmPwMessage = null;
    }
  }

  // -----------------------------
  // 이메일 중복확인 (형식 + 버튼 클릭만 체크)
  // -----------------------------
  Future<void> _checkEmail() async {
    if (!_emailValid) {
      setState(() {
        _emailMessage = '이메일을 올바르게 입력해주세요.';
        _emailChecked = false;
      });
      return;
    }

    setState(() {
      _emailChecked = true;
      _emailMessage = '사용 가능한 형식의 이메일입니다.\n회원가입 시 이미 가입된 이메일이면 안내 메시지가 표시됩니다.';
    });
  }

  // -----------------------------
  // 주소 자동입력 (데모)
  // -----------------------------
  void _searchAddress() {
    const mockAddresses = [
      '서울특별시 강남구 테헤란로 123',
      '서울특별시 서초구 강남대로 456',
      '경기도 성남시 분당구 정자일로 789',
    ];

    mockAddresses.shuffle();
    final addr = mockAddresses.first;

    setState(() {
      _addressController.text = addr;
    });
    _validateAddress(addr);
  }

  // -----------------------------
  // 인증번호 전송 (데모: 123456)
  // -----------------------------
  void _sendVerificationCode() {
    if (!_phoneValid) {
      setState(() {
        _errorMessage = '올바른 휴대폰 번호를 먼저 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isCodeSent = true;
      _secondsLeft = 180;
      _phoneVerified = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
        });
      } else {
        setState(() {
          _secondsLeft -= 1;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('인증번호가 발송되었습니다. (데모: 123456)')),
    );
  }

  // -----------------------------
  // 인증번호 확인 (데모)
  // -----------------------------
  void _verifyCode() {
    if (_codeController.text == '123456') {
      setState(() {
        _phoneVerified = true;
        _phoneMessage = '휴대폰 인증이 완료되었습니다.';
        _secondsLeft = 0;
        _timer?.cancel();
      });
    } else {
      setState(() {
        _errorMessage = '인증번호가 올바르지 않습니다.';
      });
    }
  }

  bool get _isFormValid {
    return _emailValid &&
        _emailChecked &&
        _nicknameValid &&
        _addressValid &&
        _phoneValid &&
        _phoneVerified &&
        _passwordValid &&
        _confirmPwValid;
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // -----------------------------
  // 회원가입 처리 (서비스 호출)
  // -----------------------------
  Future<void> _handleSignUp() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_isFormValid) {
      setState(() {
        _errorMessage = '모든 필수 항목을 올바르게 입력해주세요.';
      });
      return;
    }

    setState(() => _isSigningUp = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final nickname = _nicknameController.text.trim();
      final address = _addressController.text.trim();
      final phone = _phoneController.text.trim();

      await _authService.signUp(
        email: email,
        password: password,
        nickname: nickname,
        address: address,
        phone: phone,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('회원가입이 완료되었습니다.')));

      // 회원가입 완료 후 로그인 화면으로 되돌아가기
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? '회원가입 중 오류가 발생했습니다.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = '알 수 없는 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSigningUp = false);
      }
    }
  }

  // -----------------------------
  // UI
  // -----------------------------
  OutlineInputBorder _border(bool focused) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: focused ? const Color(0xFFFF5757) : const Color(0xFFDDDDDD),
        width: focused ? 1.4 : 1.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF5757);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 헤더
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/icon.png',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '프로해빗',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF111111),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '회원가입',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '프로해빗과 함께 습관을 만들어보세요',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ✅ 이메일 + 중복확인
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (v) =>
                              setState(() => _onChanged('email', v)),
                          onTap: () => setState(() => _focusedField = 'email'),
                          onEditingComplete: () =>
                              setState(() => _focusedField = null),
                          decoration: InputDecoration(
                            hintText: '이메일',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            enabledBorder: _border(_focusedField == 'email'),
                            focusedBorder: _border(true),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _emailValid ? _checkEmail : null,
                          child: const Text(
                            '중복확인',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_emailMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _emailMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          color: (_emailChecked && _emailValid)
                              ? Colors.green
                              : accent,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // 비밀번호
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    onChanged: (v) => setState(() => _onChanged('password', v)),
                    onTap: () => setState(() => _focusedField = 'password'),
                    onEditingComplete: () =>
                        setState(() => _focusedField = null),
                    decoration: InputDecoration(
                      hintText: '비밀번호',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      enabledBorder: _border(_focusedField == 'password'),
                      focusedBorder: _border(true),
                    ),
                  ),
                  if (_passwordMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _passwordMessage!,
                        style: const TextStyle(fontSize: 11, color: accent),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // 비밀번호 확인
                  TextField(
                    controller: _confirmPwController,
                    obscureText: true,
                    onChanged: (v) =>
                        setState(() => _onChanged('confirmPassword', v)),
                    onTap: () =>
                        setState(() => _focusedField = 'confirmPassword'),
                    onEditingComplete: () =>
                        setState(() => _focusedField = null),
                    decoration: InputDecoration(
                      hintText: '비밀번호 확인',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      enabledBorder: _border(
                        _focusedField == 'confirmPassword',
                      ),
                      focusedBorder: _border(true),
                    ),
                  ),
                  if (_confirmPwMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _confirmPwMessage!,
                        style: const TextStyle(fontSize: 11, color: accent),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // 닉네임
                  TextField(
                    controller: _nicknameController,
                    onChanged: (v) => setState(() => _onChanged('nickname', v)),
                    onTap: () => setState(() => _focusedField = 'nickname'),
                    onEditingComplete: () =>
                        setState(() => _focusedField = null),
                    decoration: InputDecoration(
                      hintText: '닉네임',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      enabledBorder: _border(_focusedField == 'nickname'),
                      focusedBorder: _border(true),
                    ),
                  ),
                  if (_nicknameMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _nicknameMessage!,
                        style: const TextStyle(fontSize: 11, color: accent),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // 주소 + 우편번호 찾기
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addressController,
                          onChanged: (v) =>
                              setState(() => _onChanged('address', v)),
                          onTap: () =>
                              setState(() => _focusedField = 'address'),
                          onEditingComplete: () =>
                              setState(() => _focusedField = null),
                          decoration: InputDecoration(
                            hintText: '주소',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            enabledBorder: _border(_focusedField == 'address'),
                            focusedBorder: _border(true),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _searchAddress,
                          child: const Text(
                            '우편번호 찾기',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_addressMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _addressMessage!,
                        style: const TextStyle(fontSize: 11, color: accent),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // 휴대폰 + 인증요청
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          onChanged: (v) =>
                              setState(() => _onChanged('phone', v)),
                          onTap: () => setState(() => _focusedField = 'phone'),
                          onEditingComplete: () =>
                              setState(() => _focusedField = null),
                          decoration: InputDecoration(
                            hintText: '휴대폰 번호 (010-1234-5678)',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            enabledBorder: _border(_focusedField == 'phone'),
                            focusedBorder: _border(true),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: (!_phoneValid || _secondsLeft > 0)
                              ? null
                              : _sendVerificationCode,
                          child: Text(
                            _secondsLeft > 0
                                ? _formatTime(_secondsLeft)
                                : '인증요청',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_phoneMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _phoneMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          color: _phoneVerified ? Colors.green : accent,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // 인증번호 입력
                  if (_isCodeSent) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            onChanged: (v) =>
                                setState(() => _onChanged('code', v)),
                            onTap: () => setState(() => _focusedField = 'code'),
                            onEditingComplete: () =>
                                setState(() => _focusedField = null),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '인증번호 6자리',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              enabledBorder: _border(_focusedField == 'code'),
                              focusedBorder: _border(true),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: (!_codeValid || _phoneVerified)
                                ? null
                                : _verifyCode,
                            child: const Text(
                              '인증확인',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_codeMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _codeMessage!,
                          style: const TextStyle(fontSize: 11, color: accent),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],

                  // 에러 메시지
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 13, color: accent),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // 계정 생성 버튼
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: (!_isFormValid || _isSigningUp)
                          ? null
                          : _handleSignUp,
                      child: _isSigningUp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '계정 생성',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 로그인 링크
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '이미 계정이 있으신가요? 로그인하기',
                      style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 데모 안내
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBDEFB)),
                    ),
                    child: const Text(
                      '💡 데모: 휴대폰 인증번호는 123456을 입력하면 됩니다.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
