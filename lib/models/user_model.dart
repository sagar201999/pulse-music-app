
class User {
  final String id;
  final String username;
  final String email;
  final String? profileImage;
  final String gender;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage,
    required this.gender,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
      gender: json['gender'] ?? 'Prefer not to say',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profileImage': profileImage,
      'gender': gender,
    };
  }
}
