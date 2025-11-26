// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase 초기화를 위해 필요
import 'package:firebase_auth/firebase_auth.dart';
import 'core/firebase/firebase_options.dart'; //firebase 옵션 임포트
import 'screens/Login_page.dart';
import 'screens/home_screen.dart';
import 'screens/sigup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // flutter엔진을 먼저 초기화 해서 Firebase같은 플러그인이 제대로 작동하도록 함
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); //앱이 어떤 Firebase 프로젝트를 사용할지 알려주는 단계

  //개발자용 주석 풀지 마시오
  // final seeder = DataSeeder();
  // await seeder.seedMuscleGroups();
  // await seeder.seedExercises();

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
          return HomeScreen(
            onLogout: () {
              print("로그아웃 테스트 호출");
            }, //지워버림
            onNavigateToWorkout: () {
              print("운동 화면 이동 테스트 호출");
            },
            navigateToPage: (String page) {
              print("페이지 이동: $page");
            },
            savedRoutines: [],
            onStartWorkoutWithRoutine: (routine) {
              print("선택된 루틴: ${routine.name}");
            },
          );
        }

        // 아니면 로그인 화면
        return const LoginScreen();
      },
    );
  }
}
