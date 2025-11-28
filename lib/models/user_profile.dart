// lib/models/app_user.dart
class AppUser {
  final String uid;
  final String email;
  final String nickname;
  final String address;
  final String phone;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.address,
    required this.phone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'address': address,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      uid: documentId,
      email: map['email'] as String? ?? '',
      nickname: map['nickname'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
