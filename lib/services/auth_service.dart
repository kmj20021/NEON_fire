// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neon_fire/models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 현재 Firebase Auth 유저
  User? get currentUser => _auth.currentUser;

  /// 이메일 + 비밀번호 로그인
  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// 이메일 + 비밀번호 회원가입 + Firestore 프로필 저장
  Future<void> signUp({
    required String email,
    required String password,
    required String nickname,
    required String address,
    required String phone,
  }) async {
    // 1) Firebase Auth 계정 생성
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: '사용자 정보를 가져올 수 없습니다.',
      );
    }

    // 2) Firestore 유저 문서 생성
    final appUser = AppUser(
      uid: user.uid,
      email: email,
      nickname: nickname,
      address: address,
      phone: phone,
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(appUser.uid).set(appUser.toMap());
  }

  /// 비밀번호 재설정 메일 발송
  Future<void> sendPasswordReset({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Firestore에 저장된 현재 유저 정보 가져오기 (필요하면 사용)
  Future<AppUser?> fetchCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;

    return AppUser.fromMap(doc.data()!, doc.id);
  }
}
