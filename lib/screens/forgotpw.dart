// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();

  String? _message;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = '이메일을 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // ✅ 여기만 수정
      await _authService.sendPasswordReset(email: email);
      setState(() {
        _message = '비밀번호 재설정 메일을 보냈습니다.';
      });
    } catch (_) {
      setState(() {
        _message = '메일 전송 중 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF5757);

    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 재설정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('가입하신 이메일을 입력하면 재설정 메일을 보내드립니다.'),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: '이메일'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(
                  color: _message!.contains('보냈') ? Colors.green : Colors.red,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                onPressed: _isLoading ? null : _handleReset,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('메일 보내기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
