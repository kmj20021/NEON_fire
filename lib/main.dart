// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/firebase/firebase_options.dart'; // flutterfire configure 로 생성된 파일
import 'screens/Login_page.dart';
import 'screens/home_screen.dart';
import 'screens/sigup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '프로해빗',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF5757),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      ),
      home: const AuthGate(),
    );
  }
}

/// 로그인 여부에 따라 화면 분기
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 초기 로딩
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 로그인 되어 있으면 홈 화면
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // 아니면 로그인 화면
        return const LoginScreen();
      },
    );
  }
}
