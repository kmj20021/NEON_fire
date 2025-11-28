import 'package:firebase_auth/firebase_auth.dart';
import 'package:neon_fire/models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = credential.user;

    // 로그인 실패 시
    if (user == null) return null;

    // ✅ 여기서 User -> AppUser 변환
    return AppUser.fromFirebaseUser(user);
  }

  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AppUser.fromFirebaseUser(user);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
