import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPwScreen extends StatefulWidget {
  const ForgotPwScreen({super.key});

  @override
  State<ForgotPwScreen> createState() => _ForgotPwScreenState();
}

class _ForgotPwScreenState extends State<ForgotPwScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 컨트롤러
  final _emailController = TextEditingController();

  // 검증 상태
  bool _emailValid = false;
  String? _emailMessage;

  // 포커스 및 상태
  String? _focusedField;
  String? _errorMessage;
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // 이메일 검증
  void _validateEmail(String value) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (value.isEmpty) {
      _emailValid = false;
      _emailMessage = '이메일을 입력해주세요.';
    } else if (!emailRegex.hasMatch(value)) {
      _emailValid = false;
      _emailMessage = '올바른 이메일 주소를 입력해주세요.';
    } else {
      _emailValid = true;
      _emailMessage = null;
    }
  }

  // 비밀번호 재설정 이메일 발송
  Future<void> _sendPasswordResetEmail() async {
    if (!_emailValid) {
      setState(() => _errorMessage = '올바른 이메일을 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '오류가 발생했습니다. 다시 시도해주세요.';
      });
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return '해당 이메일로 가입된 계정이 없습니다.';
      case 'invalid-email':
        return '올바른 이메일 형식이 아닙니다.';
      case 'too-many-requests':
        return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '오류가 발생했습니다. 다시 시도해주세요.';
    }
  }

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
                                  'assets/icons/icon.png',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: accent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.fitness_center,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    );
                                  },
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
                            '비밀번호 찾기',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '가입하신 이메일로 비밀번호 재설정 링크를 보내드립니다',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 이메일 발송 완료 화면
                  if (_emailSent) ...[
                    _buildEmailSentView(accent),
                  ] else ...[
                    _buildEmailInputForm(accent),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 이메일 발송 완료 화면
  Widget _buildEmailSentView(Color accent) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDDDDD)),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.mark_email_read,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '이메일을 확인해주세요!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '${_emailController.text.trim()}으로\n비밀번호 재설정 링크를 발송했습니다.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFF57C00),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '이메일이 도착하지 않으면 스팸함을 확인해주세요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFF57C00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: Text(
            '다른 이메일로 다시 보내기',
            style: TextStyle(color: accent, fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
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
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '로그인 화면으로 돌아가기',
              style: TextStyle(fontSize: 15, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // 이메일 입력 폼
  Widget _buildEmailInputForm(Color accent) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDDDDD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '가입하신 이메일',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => setState(() => _validateEmail(v)),
                onTap: () => setState(() => _focusedField = 'email'),
                onEditingComplete: () => setState(() => _focusedField = null),
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF999999),
                  ),
                  enabledBorder: _border(_focusedField == 'email'),
                  focusedBorder: _border(true),
                ),
              ),
              if (_emailMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _emailMessage!,
                    style: TextStyle(fontSize: 12, color: accent),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 에러 메시지
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 13, color: accent),
                  ),
                ),
              ],
            ),
          ),

        // 전송 버튼
        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              disabledBackgroundColor: const Color(0xFFFFCDD2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: (_emailValid && !_isLoading)
                ? _sendPasswordResetEmail
                : null,
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
                    '비밀번호 재설정 링크 보내기',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // 로그인으로 돌아가기
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '로그인 화면으로 돌아가기',
              style: TextStyle(color: Color(0xFF666666), fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
