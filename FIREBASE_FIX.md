# Firebase DEVELOPER_ERROR 해결 가이드

## 문제
```
W/GoogleApiManager: DEVELOPER_ERROR
```

## 원인
1. SHA-1 인증서 지문이 Firebase Console에 등록되지 않음
2. google-services.json에 OAuth 클라이언트 정보 없음

## 해결 단계

### 1. SHA-1 지문 생성
터미널에서 실행:
```powershell
cd android
.\gradlew signingReport
```

출력에서 다음을 찾아 복사:
```
Variant: debug
Config: debug
Store: C:\Users\user\.android\debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA-256: ...
```

### 2. Firebase Console에 SHA-1 등록
1. https://console.firebase.google.com 접속
2. 프로젝트 선택 (neon-fire-6f34c)
3. 프로젝트 설정 (⚙️) → Android 앱
4. "SHA 인증서 지문 추가" 클릭
5. 위에서 복사한 SHA1 값 붙여넣기
6. "저장" 클릭

### 3. google-services.json 재다운로드
1. Firebase Console → 프로젝트 설정 → Android 앱
2. "google-services.json 다운로드" 클릭
3. 다운로드한 파일을 `android/app/google-services.json`에 덮어쓰기

### 4. 앱 재빌드
```powershell
flutter clean
flutter pub get
flutter run
```

## 임시 해결책 (개발 중)
현재 상태에서도 Firestore는 정상 작동하므로, 배포 전까지는 이 경고를 무시해도 됩니다.
단, Google Sign-In이나 Google Play Games 등을 사용할 계획이라면 반드시 수정해야 합니다.

## 확인 방법
SHA-1 등록 후 앱 재실행 시 해당 경고가 사라집니다.
