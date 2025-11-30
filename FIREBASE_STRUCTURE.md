# Firebase Firestore 데이터 구조

## 운동 세션 저장 경로

```
users/{userId}/workout_sessions/{sessionId}
```

### 1. workout_sessions (컬렉션)

각 운동 세션 문서:

```json
{
  "routineName": "루틴 이름 (또는 null)",
  "startedAt": Timestamp,
  "endedAt": Timestamp,
  "duration": 1200,           // 초 단위 (예: 1200초 = 20분)
  "totalVolume": 2450.5,      // kg 단위
  "totalSets": 12,            // 총 세트 수
  "completedSets": 10,        // 완료된 세트 수
  "exerciseCount": 3,         // 운동 종목 수
  "createdAt": ServerTimestamp
}
```

### 2. exercises (서브컬렉션)

경로: `users/{userId}/workout_sessions/{sessionId}/exercises/{exerciseId}`

각 운동 문서:

```json
{
  "exerciseId": 1,            // 운동 ID
  "exerciseName": "벤치프레스",
  "order": 1,                 // 순서
  "createdAt": ServerTimestamp
}
```

### 3. sets (서브서브컬렉션)

경로: `users/{userId}/workout_sessions/{sessionId}/exercises/{exerciseId}/sets/{setId}`

각 세트 문서:

```json
{
  "setNumber": 1,             // 세트 번호
  "weight": 80.0,             // kg
  "reps": 10,                 // 횟수
  "isCompleted": true,        // 완료 여부
  "completedAt": Timestamp,   // 완료 시간 (완료된 경우)
  "createdAt": ServerTimestamp
}
```

---

## Firebase 콘솔에서 테스트 데이터 입력 방법

### 1단계: 메인 세션 문서 생성

1. Firebase Console → Firestore Database
2. `users` 컬렉션 찾기 (없으면 생성)
3. 본인의 userId 문서로 이동 (예: `user123`)
4. `workout_sessions` 컬렉션 추가 (+ 버튼 클릭)
5. **문서 ID**: 자동 생성 (Auto-ID)
6. **필드 추가**:
   - `routineName` (string): "테스트 루틴"
   - `startedAt` (timestamp): 현재 시간
   - `endedAt` (timestamp): 현재 시간
   - `duration` (number): 1200
   - `totalVolume` (number): 1000.0
   - `totalSets` (number): 9
   - `completedSets` (number): 9
   - `exerciseCount` (number): 3
   - `createdAt` (timestamp): 현재 시간

### 2단계: exercises 서브컬렉션 추가

1. 방금 생성한 세션 문서 클릭
2. "컬렉션 시작" 클릭
3. **컬렉션 ID**: `exercises`
4. **문서 ID**: 자동 생성
5. **필드 추가**:
   - `exerciseId` (number): 1
   - `exerciseName` (string): "벤치프레스"
   - `order` (number): 1
   - `createdAt` (timestamp): 현재 시간

### 3단계: sets 서브서브컬렉션 추가

1. 방금 생성한 exercise 문서 클릭
2. "컬렉션 시작" 클릭
3. **컬렉션 ID**: `sets`
4. **문서 ID**: 자동 생성
5. **필드 추가**:
   - `setNumber` (number): 1
   - `weight` (number): 80.0
   - `reps` (number): 10
   - `isCompleted` (boolean): true
   - `completedAt` (timestamp): 현재 시간
   - `createdAt` (timestamp): 현재 시간

6. **추가 세트 2개 더 생성** (setNumber 2, 3으로)

### 4단계: 추가 운동 2개 더 입력

1. 세션 문서로 돌아가서 `exercises` 컬렉션에서 "문서 추가"
2. **운동 2**:
   - exerciseId: 2
   - exerciseName: "스쿼트"
   - order: 2
   - 각각 3개의 sets 추가

3. **운동 3**:
   - exerciseId: 3
   - exerciseName: "데드리프트"
   - order: 3
   - 각각 3개의 sets 추가

---

## 빠른 테스트 체크리스트

✅ **필수 경로 확인**:
- [ ] `users/{userId}` 문서 존재
- [ ] `users/{userId}/workout_sessions` 컬렉션 존재
- [ ] `users/{userId}/workout_sessions/{sessionId}` 문서에 `startedAt` 필드 있음
- [ ] `users/{userId}/workout_sessions/{sessionId}/exercises` 컬렉션 존재
- [ ] `users/{userId}/workout_sessions/{sessionId}/exercises/{exerciseId}/sets` 컬렉션 존재

✅ **필수 필드 확인**:
- [ ] duration이 **숫자(number)** 타입
- [ ] startedAt이 **timestamp** 타입
- [ ] exerciseName이 **문자열(string)** 타입

---

## 현재 문제 진단

주간 운동 요약이 0으로 표시되는 이유:

1. **데이터가 없음**: Firebase에 실제로 저장된 세션이 없을 수 있음
2. **날짜 범위 문제**: `getWeeklyWorkoutSummary`는 **이번 주 월요일~일요일** 데이터만 조회
3. **userId 불일치**: 저장할 때와 조회할 때 userId가 다를 수 있음
4. **timestamp 형식 문제**: startedAt이 올바른 timestamp가 아닐 수 있음

### 확인 방법

앱에서 운동을 완료한 후 로그를 확인하세요:
- ✅ "✅ 운동 세션 저장 완료: {세션ID}" 메시지가 나오는지
- Firebase Console에서 해당 세션ID로 문서가 생성되었는지
- 문서 내부에 `exercises` 컬렉션이 있는지
