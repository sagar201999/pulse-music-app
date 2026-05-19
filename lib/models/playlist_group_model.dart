import 'playlist_model.dart';
import 'album_model.dart';

class PlaylistGroup {
  final String id;
  final String name;
  final String description;
  final String thumbnailUrl;
  final bool isAdminPlaylistGroup;
  final List<Playlist> playlists;
  final List<Album> albums;

  const PlaylistGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnailUrl,
    this.isAdminPlaylistGroup = true,
    this.playlists = const [],
    this.albums = const [],
  });

  factory PlaylistGroup.fromJson(Map<String, dynamic> json) {
    List<Playlist> parsedPlaylists = [];
    if (json['playlists'] != null && json['playlists'] is List) {
      parsedPlaylists = (json['playlists'] as List).map((p) {
        return Playlist.fromJson(p as Map<String, dynamic>);
      }).toList();
    }

    List<Album> parsedAlbums = [];
    if (json['albums'] != null && json['albums'] is List) {
      parsedAlbums = (json['albums'] as List).map((a) {
        return Album.fromJson(a as Map<String, dynamic>);
      }).toList();
    }

    return PlaylistGroup(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Untitled Group',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      isAdminPlaylistGroup: json['isAdminPlaylistGroup'] ?? true,
      playlists: parsedPlaylists,
      albums: parsedAlbums,
    );
  }
}
