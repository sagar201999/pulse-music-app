import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class AuthService {
  // Use your Render URL for production or 10.0.2.2 for Android Emulator local testing
  static const String baseUrl = 'https://pulse-backend-j86c.onrender.com/api/auth';
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // In-memory cache for instantaneous UI checks
  List<String> likedSongIds = [];

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? gender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'gender': gender ?? 'Prefer not to say',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        await _saveAuthData(data['token'], data['user']);
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      print('Auth Error (Register): $e');
      return {'success': false, 'message': 'Network error: Please check your connection'};
    }
  }

  /// Login existing user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await _saveAuthData(data['token'], data['user']);
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      print('Auth Error (Login): $e');
      return {'success': false, 'message': 'Network error: Please check your connection'};
    }
  }

  /// Persist token and user info
  Future<void> _saveAuthData(String token, Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('user_data', jsonEncode(userMap));
    
    final user = User.fromJson(userMap);
    likedSongIds = List<String>.from(user.likedSongIds);
  }

  /// Load cache on app start
  Future<void> loadCache() async {
    final user = await getUser();
    if (user != null) {
      likedSongIds = List<String>.from(user.likedSongIds);
    }
  }

  /// Instant UI Check
  bool isLiked(String songId) => likedSongIds.contains(songId);

  /// Toggle Like Optimistically
  void toggleLikeLocal(String songId) {
    if (likedSongIds.contains(songId)) {
      likedSongIds.remove(songId);
    } else {
      likedSongIds.add(songId);
    }
    _persistLikedSongs();
  }

  /// Persist local liked songs state to SharedPreferences
  Future<void> _persistLikedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        final userMap = jsonDecode(userData);
        userMap['likedSongs'] = likedSongIds;
        await prefs.setString('user_data', jsonEncode(userMap));
      }
    } catch (e) {
      print('Failed to persist liked songs: $e');
    }
  }

  /// Get stored user data
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData == null) return null;
    return User.fromJson(jsonDecode(userData));
  }

  /// Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? gender,
    String? profileImage,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not authenticated'};

      final body = {};
      if (username != null) body['username'] = username;
      if (gender != null) body['gender'] = gender;
      if (profileImage != null) body['profileImage'] = profileImage;

      final response = await http.put(
        Uri.parse(baseUrl.replaceFirst('/auth', '/users/profile')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('Update Profile Status: ${response.statusCode}');
      
      try {
        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          await _saveAuthData(token, data['user']);
          return {'success': true, 'message': 'Profile updated successfully', 'user': data['user']};
        } else {
          return {'success': false, 'message': data['message'] ?? 'Update failed'};
        }
      } on FormatException {
        return {'success': false, 'message': 'Server error: Invalid response format (${response.statusCode})'};
      }
    } catch (e) {
      print('Auth Error (Update Profile): $e');
      return {'success': false, 'message': 'Network error: Please check your connection'};
    }
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      await loadCache();
      return true;
    }
    return false;
  }
}
