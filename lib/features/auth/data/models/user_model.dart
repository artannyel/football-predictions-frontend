class UserModel {
  final String id;
  final String firebaseUid;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.firebaseUid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firebaseUid: json['firebase_uid'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photo_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}