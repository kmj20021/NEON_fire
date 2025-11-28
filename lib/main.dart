// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/firebase/firebase_options.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 개발자용 주석 풀지 마시오
  // final seeder = DataSeeder();
  // await seeder.seedMuscleGroups();
  // await seeder.seedExercises();

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

