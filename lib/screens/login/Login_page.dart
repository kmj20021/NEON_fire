// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:neon_fire/services/auth_service.dart';
import 'sigup_screen.dart';
import 'forgotpw.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final AuthService _authService = AuthService();

  String? _errorMessage;
  String? _focusedField; // 'email' or 'password'
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  // -----------------------------
  // 로그인 처리
  // -----------------------------
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _pwController.text.trim();

    setState(() {
      _errorMessage = null;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = '이메일과 비밀번호를 모두 입력해 주세요.';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firebase 이메일/비밀번호 로그인
      await _authService.login(email: email, password: password);

      // 오류 수정: 로그인 성공 시 GoRouter의 refreshListenable이
      // authStateChanges를 감지하여 자동으로 /home으로 리다이렉트됨
      // 별도의 Navigator 호출 불필요
      debugPrint('✅ 로그인 성공! authStateChanges가 자동으로 홈으로 이동시킴');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = '로그인 중 알 수 없는 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Firebase 에러 코드 → 한글 메시지
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return '해당 이메일로 가입된 계정이 없습니다.';
      case 'wrong-password':
        return '비밀번호가 틀렸습니다.';
      case 'invalid-email':
        return '이메일 형식이 올바르지 않습니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'too-many-requests':
        return '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.';
      default:
        return '로그인에 실패했습니다. 다시 시도해 주세요.';
    }
  }

  // 회원가입 화면으로 이동
  void _openSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  // 비밀번호 재설정 화면으로 이동
  void _openForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPwScreen()),
    );
  }

  OutlineInputBorder _buildBorder({required bool focused}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -----------------------------
                // 로고 + 앱 이름
                // -----------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/icons/icon.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '프로해빗',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // -----------------------------
                // 이메일 / 비밀번호 입력
                // -----------------------------
                Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onTap: () => setState(() => _focusedField = 'email'),
                      onEditingComplete: () =>
                          setState(() => _focusedField = null),
                      decoration: InputDecoration(
                        hintText: '이메일',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        enabledBorder: _buildBorder(
                          focused: _focusedField == 'email',
                        ),
                        focusedBorder: _buildBorder(focused: true),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pwController,
                      obscureText: true,
                      onTap: () => setState(() => _focusedField = 'password'),
                      onEditingComplete: () =>
                          setState(() => _focusedField = null),
                      decoration: InputDecoration(
                        hintText: '비밀번호',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        enabledBorder: _buildBorder(
                          focused: _focusedField == 'password',
                        ),
                        focusedBorder: _buildBorder(focused: true),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // -----------------------------
                // 에러 메시지
                // -----------------------------
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
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
                ],

                // -----------------------------
                // 로그인 버튼
                // -----------------------------
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '로그인',
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // -----------------------------
                // 회원가입 / 아이디/비밀번호 찾기
                // -----------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _openSignUp,
                      child: const Text(
                        '회원가입',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _openForgotPassword,
                      child: const Text(
                        '아이디/비밀번호 찾기',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
