// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:neon_fire/core/firebase/firebase_options.dart';
import 'package:neon_fire/core/router/app_router.dart';
import 'package:neon_fire/services/workout_seeder.dart';
import 'package:neon_fire/services/group_buy_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 개발자용 주석 풀지 마시오
  // final seeder = DataSeeder();
  // await seeder.seedMuscleGroups();
  // await seeder.seedExercises();

  // 운동 시드 데이터 생성 주석 풀지 마시오.
  // final workoutSeeder = WorkoutSeeder();
  // await workoutSeeder.seedAll(
  //   userId: 'Kw8juSSxuoZZBWULaoYwwa95rgC3',  //
  //   clearExisting: true,           // 기존 데이터 삭제 여부
  //   daysToGenerate: 60,            // 생성할 일수 (60일)
  //   workoutFrequency: 4.0,         // 주당 평균 운동 횟수
  // );

  // 공동구매 시드 데이터 생성 주석 풀지 마시오.
  // final groupBuyService = GroupBuyService();
  // await groupBuyService.seedMockData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '프로해빗',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF5757),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      ),
      routerConfig: AppRouter.router,
    );
  }
}
