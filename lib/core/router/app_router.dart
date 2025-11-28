// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neon_fire/screens/Login_page.dart';
import 'package:neon_fire/screens/home_screen.dart';
import 'package:neon_fire/screens/workout_screen.dart';
import 'package:neon_fire/models/saved_routine.dart';

/// 앱의 모든 라우트를 관리하는 GoRouter 설정
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    
    // 초기 경로
    initialLocation: '/',
    
    // 리다이렉트: 로그인 상태에 따라 페이지 이동
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggingIn = state.matchedLocation == '/';
      
      // 로그인 안되어 있으면 로그인 페이지로
      if (user == null && !isLoggingIn) {
        return '/';
      }
      
      // 로그인 되어있는데 로그인 페이지에 있으면 홈으로
      if (user != null && isLoggingIn) {
        return '/home';
      }
      
      return null; // 리다이렉트 없음
    },
    
    // 라우트 정의
    routes: [
      // 로그인 페이지
      GoRoute(
        path: '/',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // 홈 페이지
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return const LoginScreen();
          
          return HomeScreen(
            userId: user.uid,
            onLogout: () async {
              await FirebaseAuth.instance.signOut();
            },
            onNavigateToWorkout: () {
              context.go('/workout');
            },
            navigateToPage: (String page) {
              switch (page) {
                case '운동':
                  context.go('/workout');
                  break;
                case '프로틴 구매':
                  // TODO: 프로틴 구매 페이지 구현
                  debugPrint('프로틴 구매 페이지로 이동');
                  break;
                case '마이 페이지':
                  // TODO: 마이 페이지 구현
                  debugPrint('마이 페이지로 이동');
                  break;
                case '성과 확인':
                  // TODO: 성과 확인 페이지 구현
                  debugPrint('성과 확인 페이지로 이동');
                  break;
                default:
                  debugPrint('알 수 없는 페이지: $page');
              }
            },
            savedRoutines: const [], // TODO: 실제 저장된 루틴 불러오기
            onStartWorkoutWithRoutine: (SavedRoutine routine) {
              // TODO: 루틴으로 운동 시작
              debugPrint('루틴으로 운동 시작: ${routine.name}');
              context.go('/workout');
            },
          );
        },
      ),
      
      // 운동 페이지
      GoRoute(
        path: '/workout',
        name: 'workout',
        builder: (context, state) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return const LoginScreen();
          
          return WorkoutScreen(
            userId: user.uid,
            onBack: () {
              context.go('/home');
            },
            navigateToPage: (String page) {
              if (page == '홈') {
                context.go('/home');
              }
            },
            onStartWorkout: (List<int> workoutIds) {
              // TODO: 운동 시작 로직
              debugPrint('운동 시작: $workoutIds');
            },
          );
        },
      ),
    ],
    
    // 에러 페이지
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '페이지를 찾을 수 없습니다',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('경로: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    ),
  );
}
