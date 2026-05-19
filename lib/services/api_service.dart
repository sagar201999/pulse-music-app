import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/services/auth_service.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../models/playlist_group_model.dart';
import '../models/category_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _base = ApiConstants.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getToken();
    if (token != null && token.isNotEmpty) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  // ── Songs ─────────────────────────────────────────────────────────────
  Future<List<Song>> getAllSongs({int limit = 50}) async {
    try {
      final response = await http
          .get(Uri.parse('$_base/songs?limit=$limit'))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List songs = data['songs'] ?? [];
        return songs.map((s) => Song.fromJson(s)).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load songs: $e');
    }
  }

  Future<List<Song>> searchSongs(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final response = await http
          .get(Uri.parse('$_base/songs/search?q=$encoded'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List songs = data['songs'] ?? [];
        return songs.map((s) => Song.fromJson(s)).toList();
      }
      throw Exception('Search failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to search: $e');
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await http
          .get(Uri.parse('$_base/categories'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List cats = data['categories'] ?? [];
        return cats.map((c) => Category.fromJson(c)).toList();
      }
      throw Exception('Failed to load categories');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Song>> getSongsByCategory(String category) async {
    try {
      final encoded = Uri.encodeComponent(category);
      final response = await http
          .get(Uri.parse('$_base/songs/category/$encoded'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List songs = data['songs'] ?? [];
        return songs.map((s) => Song.fromJson(s)).toList();
      }
      throw Exception('Failed to load category songs');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> incrementPlayCount(String songId) async {
    try {
      await http
          .post(Uri.parse('$_base/songs/$songId/play'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Non-critical — ignore silently
    }
  }

  // ── Playlists ─────────────────────────────────────────────────────────

  Future<List<Playlist>> getPublicPlaylists() async {
    try {
      final response = await http.get(Uri.parse('$_base/playlists/public')).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List playlists = data['playlists'] ?? [];
        return playlists.map((p) => Playlist.fromJson(p)).toList();
      }
      throw Exception('Failed to load public playlists');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Song>> getAutoPlaylist(String type) async {
    try {
      final response = await http.get(Uri.parse('$_base/playlists/auto?type=$type')).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List songs = data['songs'] ?? [];
        return songs.map((s) => Song.fromJson(s)).toList();
      }
      throw Exception('Failed to load auto playlist');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Playlist>> getUserPlaylists() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_base/playlists/me'), headers: headers).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List playlists = data['playlists'] ?? [];
        return playlists.map((p) => Playlist.fromJson(p)).toList();
      }
      return []; // Return empty if not authenticated or failed
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> createUserPlaylist(String name, String description) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_base/playlists/user'),
        headers: headers,
        body: jsonEncode({'name': name, 'description': description}),
      ).timeout(const Duration(seconds: 15));
      
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addSongToPlaylist(String playlistId, String songId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$_base/playlists/$playlistId/tracks'),
        headers: headers,
        body: jsonEncode({'songId': songId}),
      ).timeout(const Duration(seconds: 15));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── Playlist Groups ───────────────────────────────────────────────────
  Future<List<PlaylistGroup>> getPlaylistGroups() async {
    try {
      final response = await http.get(Uri.parse('$_base/playlist-groups')).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List groups = data['playlistGroups'] ?? [];
        return groups.map((g) => PlaylistGroup.fromJson(g)).toList();
      }
      throw Exception('Failed to load playlist groups');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
