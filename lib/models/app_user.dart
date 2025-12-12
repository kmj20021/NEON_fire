// lib/models/app_user.dart
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String uid;
  final String email;
  final String nickname;
  final String address;
  final String phone;
  final String? profileImageUrl;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.address,
    required this.phone,
    this.profileImageUrl,
    required this.createdAt,
  });

  /// Firebase User -> AppUser 로 변환
  /// (닉네임/주소/전화번호는 나중에 따로 채울 수 있게 기본값 '')
  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      nickname: '',
      address: '',
      phone: '',
      profileImageUrl: null,
      createdAt: DateTime.now(),
    );
  }

  /// Firestore 저장용
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'address': address,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Firestore에서 불러오기용
  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      uid: documentId,
      email: map['email'] as String? ?? '',
      nickname: map['nickname'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      profileImageUrl: map['profileImageUrl'] as String?,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// 복사본 생성 (일부만 변경할 때 사용)
  AppUser copyWith({
    String? uid,
    String? email,
    String? nickname,
    String? address,
    String? phone,
    String? profileImageUrl,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
