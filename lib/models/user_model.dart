
class User {
  final String id;
  final String username;
  final String email;
  final String? profileImage;
  final String gender;
  final List<String> likedSongIds;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage,
    required this.gender,
    this.likedSongIds = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImage: (json['profileImage'] != null && json['profileImage'].toString().contains('default_avatar.png')) 
          ? null 
          : json['profileImage'],
      gender: json['gender'] ?? 'Prefer not to say',
      likedSongIds: json['likedSongs'] != null 
          ? List<String>.from(json['likedSongs'].map((x) {
              if (x is Map) return x['_id'] ?? x['id'] ?? '';
              return x.toString();
            }))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profileImage': profileImage,
      'gender': gender,
      'likedSongs': likedSongIds,
    };
  }
}
