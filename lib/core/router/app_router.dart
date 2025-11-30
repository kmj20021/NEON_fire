// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neon_fire/screens/Login_page.dart';
import 'package:neon_fire/screens/home_screen.dart';
import 'package:neon_fire/screens/workout_screen.dart';
import 'package:neon_fire/models/saved_routine.dart';
import 'package:neon_fire/screens/active_workout_screen.dart';

/// Firebase Auth 상태 변화를 감지하는 ChangeNotifier
class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    // Firebase Auth 상태 변화를 감지하여 리스너들에게 알림
    FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }
}

/// 앱의 모든 라우트를 관리하는 GoRouter 설정
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _authNotifier = AuthNotifier();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    
    // 오류 수정: 로그인 상태가 변경될 때마다 redirect가 다시 실행되도록
    // refreshListenable을 추가하여 authStateChanges를 감지
    refreshListenable: _authNotifier,
    
    // 초기 경로
    initialLocation: '/',
    
    // 리다이렉트: 로그인 상태에 따라 페이지 이동
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggingIn = state.matchedLocation == '/';
      
      debugPrint('🔄 Redirect 체크: user=${user?.uid}, location=${state.matchedLocation}');
      
      // 로그인 안되어 있으면 로그인 페이지로
      if (user == null && !isLoggingIn) {
        debugPrint('❌ 로그인 안됨 → 로그인 페이지로');
        return '/';
      }
      
      // 로그인 되어있는데 로그인 페이지에 있으면 홈으로
      if (user != null && isLoggingIn) {
        debugPrint('✅ 로그인됨 → 홈으로 이동');
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
            savedRoutines: const [], // 더 이상 사용되지 않음 (Firebase에서 직접 로드)
            onStartWorkoutWithRoutine: (SavedRoutine routine) {
              // 루틴의 운동 ID 리스트를 extra로 전달하여 active_workout으로 이동
              debugPrint('루틴으로 운동 시작: ${routine.name}');
              context.go('/active_workout', extra: {
                'workoutIds': routine.workouts,
                'routineName': routine.name,
              });
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
              // 선택한 운동 데이터를 active_workout 페이지로 전달
              context.go('/active_workout', extra: workoutIds);
            },
          );
        },
      ),

      GoRoute(
        path: '/active_workout',
        name: 'active_workout',
        builder: (context, state) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return const LoginScreen();
          
          // extra로 전달받은 데이터
          final extraData = state.extra;
          List<int>? selectedWorkoutIds;
          String? routineName;
          
          if (extraData is Map<String, dynamic>) {
            // 루틴으로부터 시작한 경우
            selectedWorkoutIds = (extraData['workoutIds'] as List<dynamic>?)?.cast<int>();
            routineName = extraData['routineName'] as String?;
          } else if (extraData is List<int>) {
            // 직접 선택한 운동으로 시작한 경우
            selectedWorkoutIds = extraData;
          }
          
          // 운동이 선택되지 않았으면 workout 페이지로 리다이렉트
          if (selectedWorkoutIds == null || selectedWorkoutIds.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/workout');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          return ActiveWorkoutScreen(
            userId: user.uid,
            selectedWorkouts: selectedWorkoutIds,
            selectedRoutine: routineName != null
                ? SavedRoutine(
                    id: '',
                    name: routineName,
                    workouts: selectedWorkoutIds,
                    createdAt: DateTime.now(),
                  )
                : null,
            onBack: () {
              context.go('/workout');
            },
            navigateToPage: (String page) {
              if (page == '홈') {
                context.go('/home');
              }
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
