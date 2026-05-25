import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../models/song_model.dart';
import '../../services/api_service.dart';
import '../../services/audio_service.dart';
import '../player/player_screen.dart';
import '../../widgets/song_list_tile.dart';

class LikedSongsScreen extends StatefulWidget {
  const LikedSongsScreen({super.key});

  @override
  State<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends State<LikedSongsScreen> {
  final AudioPlayerService _audioService = AudioPlayerService();
  bool _isLoading = true;
  List<Song> _songs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLikedSongs();
  }

  Future<void> _fetchLikedSongs() async {
    try {
      final songs = await ApiService().getLikedSongs();
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _playAll() {
    if (_songs.isNotEmpty) {
      _audioService.loadAndPlay(_songs.first, playlist: _songs);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            song: _songs.first,
            playlist: _songs,
          ),
        ),
      );
    }
  }

  void _playSong(Song song) {
    _audioService.loadAndPlay(song, playlist: _songs);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(song: song, playlist: _songs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Liked Songs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : _songs.isEmpty
                  ? const Center(
                      child: Text(
                        'No liked songs yet.\nStart liking some music!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_songs.length} tracks',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    const Row(
                                      children: [
                                        Icon(CupertinoIcons.heart_fill, color: AppColors.primary, size: 16),
                                        SizedBox(width: 4),
                                        Text(' Playlist • You', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                      ],
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                FloatingActionButton(
                                  onPressed: _playAll,
                                  backgroundColor: AppColors.primary,
                                  child: const Icon(CupertinoIcons.play_fill, color: Colors.black, size: 30),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final song = _songs[index];
                              return SongListTile(
                                song: song,
                                playlist: _songs,
                                onTap: () => _playSong(song),
                              );
                            },
                            childCount: _songs.length,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
    );
  }
}
