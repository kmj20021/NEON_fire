# Performance Screen - MVC 패턴 구조

## 개요
Performance Screen을 MVC(Model-View-Controller) 패턴으로 리팩토링했습니다.

## 파일 구조

```
lib/
├── models/
│   └── performance_models.dart          # Model: 데이터 모델 정의
├── controllers/
│   └── performance_controller.dart      # Controller: 비즈니스 로직 & 상태 관리
├── widgets/
│   └── performance_widgets.dart         # View: 재사용 가능한 UI 위젯들
├── screens/
│   ├── performance_screen.dart          # 기존 파일 (유지)
│   └── performance_screen_mvc.dart      # View: MVC 패턴 메인 화면
└── services/
    └── performance_service.dart         # Service: 데이터 통신 계층
```

## MVC 패턴 구성

### 1. Model (models/performance_models.dart)
데이터 구조와 비즈니스 엔티티를 정의합니다.

**주요 모델:**
- `PerformanceSummary` - 성과 요약 데이터
- `VolumeIntensitySummary` - 볼륨 & 강도 데이터
- `ConsistencyScore` - 일관성 점수
- `PerformanceComment` - 성과 코멘트

### 2. View (screens/performance_screen_mvc.dart & widgets/performance_widgets.dart)

#### 메인 화면 (performance_screen_mvc.dart)
- `PerformanceScreenMVC` - 메인 화면 위젯
- Controller를 초기화하고 UI를 렌더링
- 사용자 인터랙션을 Controller에 전달

#### 재사용 위젯 (performance_widgets.dart)
순수 UI 컴포넌트만 포함:
- `PerformanceSummaryCard` - 성과 요약 카드
- `WorkoutHistoryButton` - 운동 기록 버튼
- `VolumeIntensityCard` - 볼륨 & 강도 카드
- `ConsistencyCard` - 일관성 점수 카드
- `PerformanceCommentCard` - 성과 코멘트 카드
- `PerformanceLoadingScreen` - 로딩 화면
- `WorkoutHistoryDialog` - 운동 기록 다이얼로그

### 3. Controller (controllers/performance_controller.dart)
비즈니스 로직과 상태 관리를 담당합니다.

**주요 기능:**
```dart
class PerformanceController extends ChangeNotifier {
  // 상태 변수
  PerformanceSummary? summary;
  VolumeIntensitySummary? volumeIntensity;
  ConsistencyScore? consistencyScore;
  bool isLoading = true;
  
  // 비즈니스 로직
  Future<void> loadAllData();
  Future<List<Map<String, dynamic>>> loadWorkoutHistory();
  Future<List<Map<String, dynamic>>> loadWorkoutDetails(String sessionId);
  String formatDate(DateTime date);
}
```

**특징:**
- `ChangeNotifier` 상속으로 상태 변화 알림
- 서비스 레이어와 통신
- UI와 분리된 독립적인 테스트 가능

## 장점

### 1. 관심사의 분리 (Separation of Concerns)
- **Model**: 데이터 구조만 정의
- **View**: UI 렌더링만 담당
- **Controller**: 비즈니스 로직만 처리

### 2. 재사용성 (Reusability)
- 위젯들을 다른 화면에서도 재사용 가능
- Controller를 다른 View에서도 사용 가능

### 3. 테스트 용이성 (Testability)
- Controller를 독립적으로 단위 테스트 가능
- UI 없이 비즈니스 로직 테스트 가능

### 4. 유지보수성 (Maintainability)
- 각 레이어가 독립적이어서 수정이 용이
- 버그 발생 시 책임 소재가 명확

### 5. 확장성 (Scalability)
- 새로운 기능 추가 시 기존 코드 영향 최소화
- 새로운 위젯 쉽게 추가 가능

## 사용 방법

### Controller 초기화
```dart
class _PerformanceScreenMVCState extends State<PerformanceScreenMVC> {
  late PerformanceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PerformanceController(userId: widget.userId);
    _controller.addListener(_onControllerUpdate);
    _controller.loadAllData();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }
}
```

### View에서 Controller 사용
```dart
Widget build(BuildContext context) {
  return _controller.isLoading
      ? PerformanceLoadingScreen(primaryColor: primaryColor)
      : Column(
          children: [
            if (_controller.summary != null)
              PerformanceSummaryCard(
                summary: _controller.summary!,
                primaryColor: primaryColor,
              ),
          ],
        );
}
```

### Controller 메서드 호출
```dart
// 데이터 새로고침
RefreshIndicator(
  onRefresh: _controller.loadAllData,
  child: ...,
)

// 운동 기록 불러오기
FutureBuilder(
  future: _controller.loadWorkoutHistory(),
  builder: ...,
)
```

## 마이그레이션 가이드

### 기존 코드에서 MVC로 전환
1. **State 변수를 Controller로 이동**
   ```dart
   // Before (Screen)
   bool isLoading = true;
   PerformanceSummary? summary;
   
   // After (Controller)
   class PerformanceController extends ChangeNotifier {
     bool isLoading = true;
     PerformanceSummary? summary;
   }
   ```

2. **비즈니스 로직을 Controller로 이동**
   ```dart
   // Before (Screen)
   Future<void> _loadAllData() async { ... }
   
   // After (Controller)
   Future<void> loadAllData() async { ... }
   ```

3. **UI 위젯을 별도 파일로 분리**
   ```dart
   // Before (Screen 내부)
   Widget _buildSummaryCard() { ... }
   
   // After (Widgets 파일)
   class PerformanceSummaryCard extends StatelessWidget { ... }
   ```

## 향후 개선 사항

1. **Provider 패턴 도입**
   - ChangeNotifier 대신 Provider 사용
   - 더 나은 상태 관리

2. **Repository 패턴 추가**
   - Service와 Controller 사이에 Repository 레이어
   - 데이터 소스 추상화

3. **의존성 주입 (DI)**
   - GetIt이나 Provider로 의존성 관리
   - 테스트 용이성 향상

4. **에러 핸들링 강화**
   - 에러 상태 명확히 구분
   - 사용자 친화적 에러 메시지

## 참고 자료

- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Flutter State Management](https://flutter.dev/docs/development/data-and-backend/state-mgmt)
- [MVC Pattern](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller)
