import 'song_model.dart';

class Playlist {
  final String id;
  final String name;
  final String description;
  final String thumbnailUrl;
  final bool isAdminPlaylist;
  final String? createdBy;
  final List<Song> songs;
  final int trackCount;

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnailUrl,
    this.isAdminPlaylist = false,
    this.createdBy,
    this.songs = const [],
    this.trackCount = 0,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    List<Song> parsedSongs = [];
    if (json['songs'] != null) {
      if (json['songs'] is List) {
        parsedSongs = (json['songs'] as List).map((s) {
          if (s is Map<String, dynamic>) {
            return Song.fromJson(s);
          }
          // If it's just a string ID, we can't parse it into a full song
          return Song(
            id: s.toString(),
            title: 'Unknown Track',
            artist: '',
            audioUrl: '',
            thumbnailUrl: '',
            duration: 0,
          );
        }).toList();
      }
    }

    return Playlist(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Untitled Playlist',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? 'https://res.cloudinary.com/pulse-music-app/image/upload/v1/default_playlist.png',
      isAdminPlaylist: json['isAdminPlaylist'] ?? false,
      createdBy: json['createdBy']?.toString(),
      songs: parsedSongs,
      trackCount: parsedSongs.isNotEmpty ? parsedSongs.length : (json['songs']?.length ?? 0),
    );
  }
}
