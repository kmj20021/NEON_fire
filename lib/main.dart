import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase 초기화를 위해 필요
import 'core/firebase/firebase_options.dart'; //firebase 옵션 임포트
import 'screens/home_screen.dart';
//import 'services/data_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();// flutter엔진을 먼저 초기화 해서 Firebase같은 플러그인이 제대로 작동하도록 함
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
      title: 'Firebase SignUp Demo',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(
        onLogout: () {
          print("로그아웃 테스트 호출");
        }, //지워버림
        onNavigateToWorkout: () {
          print("운동 화면 이동 테스트 호출");
        },
        navigateToPage: (String page){
          print("페이지 이동: $page");
        },
        savedRoutines: [],
        onStartWorkoutWithRoutine: (routine) {
          print("선택된 루틴: ${routine.name}");
        },
      ),
    );
  }
}
