import 'song_model.dart';

class Album {
  final String id;
  final String title;
  final String artist;
  final String description;
  final String thumbnailUrl;
  final int releaseYear;
  final List<Song> songs;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.description,
    required this.thumbnailUrl,
    required this.releaseYear,
    this.songs = const [],
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    List<Song> parsedSongs = [];
    if (json['songs'] != null && json['songs'] is List) {
      parsedSongs = (json['songs'] as List).map((s) {
        if (s is Map<String, dynamic>) {
          return Song.fromJson(s);
        }
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

    return Album(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Untitled Album',
      artist: json['artist'] ?? 'Unknown Artist',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? 'https://res.cloudinary.com/pulse-music-app/image/upload/v1/default_album.png',
      releaseYear: json['releaseYear'] ?? DateTime.now().year,
      songs: parsedSongs,
    );
  }
}
