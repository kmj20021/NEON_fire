// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:neon_fire/models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

  /// 프로필 사진 업로드
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      throw Exception('프로필 사진 업로드 실패: $e');
    }
  }

  /// 사용자 정보 업데이트 (닉네임, 주소, 전화번호, 프로필 이미지)
  Future<void> updateUserProfile({
    required String userId,
    String? nickname,
    String? address,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (nickname != null) updateData['nickname'] = nickname;
      if (address != null) updateData['address'] = address;
      if (phone != null) updateData['phone'] = phone;
      if (profileImageUrl != null)
        updateData['profileImageUrl'] = profileImageUrl;

      await _db.collection('users').doc(userId).update(updateData);
    } catch (e) {
      throw Exception('사용자 정보 업데이트 실패: $e');
    }
  }
}
