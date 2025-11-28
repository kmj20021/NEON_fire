// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase 초기화를 위해 필요
import 'package:firebase_auth/firebase_auth.dart'; // 테스트를 위해 미사용
import 'core/firebase/firebase_options.dart'; //firebase 옵션 임포트
import 'screens/Login_page.dart'; // 테스트를 위해 미사용
import 'screens/home_screen.dart';

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
    // 응답없음 원인: AuthGate를 MaterialApp 없이 바로 runApp()에 전달하면
    // StreamBuilder가 제대로 동작하지 않아 초기 로딩 화면에서 멈춤
    // 해결: MaterialApp으로 감싸고 home에 AuthGate를 배치
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
        // 응답없음 원인: ConnectionState.waiting 조건에서 무한 대기
        // Firebase authStateChanges 스트림이 첫 이벤트를 발생시키지 않으면
        // waiting 상태에서 벗어나지 못해 로딩 화면에 계속 머물게 됨
        // 해결: waiting 체크를 제거하고 바로 데이터 유무로 분기 처리
        
        // 로그인 되어 있으면 홈 화면
        if (snapshot.hasData) {
          return HomeScreen(
            userId: snapshot.data!.uid,
            onLogout: () {
              debugPrint("로그아웃 테스트 호출");
            },
            onNavigateToWorkout: () {
              debugPrint("운동 화면 이동 테스트 호출");
            },
            navigateToPage: (String page) {
              debugPrint("페이지 이동: $page");
            },
            savedRoutines: [],
            onStartWorkoutWithRoutine: (routine) {
              debugPrint("선택된 루틴: ${routine.name}");
            },
          );
        }

        // 아니면 로그인 화면 (초기 로딩 포함)
        return const LoginScreen();
      },
    );
  }
}

