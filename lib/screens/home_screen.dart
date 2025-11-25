import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('홈 화면')),
      body: Center(
        child: Text(
          user != null
              ? '환영합니다!\n${user.email}'
              : '로그인 정보가 없습니다.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
