import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();

  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  // 회원가입 처리 메서드
  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final pw = _pwController.text.trim();

    if (email.isEmpty || pw.isEmpty) {
      setState(() {
        _errorMessage = "이메일과 비밀번호를 입력해 주세요.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signUpWithEmail(email: email, password: pw);

      // 회원가입 성공 → 홈 화면으로 이동
      if (!mounted) return; //mounted 뜻 : 위젯이 현재 트리에서 활성 상태인지 확인
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on Exception catch (e) {
      setState(() {
        _errorMessage = "회원가입 실패: $e";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 컨트롤러 해제
  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  // UI 빌드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: '이메일'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pwController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleSignUp,
                    child: const Text('회원가입'),
                  ),
          ],
        ),
      ),
    );
  }
}
