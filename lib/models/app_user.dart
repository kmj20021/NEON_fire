class AppUser {
  final String uid;
  final String email;
  final String? displayName; //닉네임 같은 역할

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
  });

  // Map<String, dynamic> 형태에서 AppUser 인스턴스를 생성하는 팩토리 생성자
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
    );
  }

  // AppUser 인스턴스를 Map<String, dynamic> 형태로 변환하는 메서드
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
    };
  }
}
