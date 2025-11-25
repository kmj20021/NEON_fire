import 'package:neon_fire/core/firebase/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 이메일 + 비밀번호로 회원가입
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential;
  }

  // 현재 로그인한 유저
  User? get currentUser => _auth.currentUser;

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
