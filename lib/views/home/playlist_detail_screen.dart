import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../models/playlist_model.dart';
import '../../models/song_model.dart';
import '../../models/album_model.dart';
import '../../services/audio_service.dart';
import '../player/player_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist? playlist;
  final Album? album;

  const PlaylistDetailScreen({
    super.key,
    this.playlist,
    this.album,
  }) : assert(playlist != null || album != null, 'Either playlist or album must be provided');

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final AudioPlayerService _audioService = AudioPlayerService();

  String get name => widget.playlist?.name ?? widget.album?.title ?? '';
  String get description => widget.playlist?.description ?? widget.album?.description ?? '';
  String get thumbnailUrl => widget.playlist?.thumbnailUrl ?? widget.album?.thumbnailUrl ?? '';
  List<Song> get songs => widget.playlist?.songs ?? widget.album?.songs ?? [];
  int get trackCount => songs.length;
  String get typeLabel => widget.playlist != null
      ? (widget.playlist!.isAdminPlaylist ? 'Global Playlist' : 'Private Playlist')
      : 'Album • ${widget.album?.artist ?? ''}';
  IconData get typeIcon => widget.playlist != null
      ? (widget.playlist!.isAdminPlaylist ? Icons.public : Icons.person)
      : Icons.album;

  void _playAll() {
    final sList = songs;
    if (sList.isNotEmpty) {
      _audioService.loadAndPlay(sList.first, playlist: sList);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            song: sList.first,
            playlist: sList,
          ),
        ),
      );
    }
  }

  void _playSong(Song song) {
    final sList = songs;
    _audioService.loadAndPlay(song, playlist: sList);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(song: song, playlist: sList),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sList = songs;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header / App Bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred Background
                  CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.background.withOpacity(0.3),
                          AppColors.background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Centered Image
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          width: 180,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 30, right: 30),
                          child: Text(
                            description,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Play Button & Info ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$trackCount tracks',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            typeIcon,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            typeLabel,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  FloatingActionButton(
                    onPressed: _playAll,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 36),
                  ),
                ],
              ),
            ),
          ),

          // ── Tracks List ───────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = sList[index];
                return InkWell(
                  onTap: () => _playSong(song),
                  splashColor: AppColors.textPrimary.withOpacity(0.06),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        // Track Number
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                          ),
                        ),
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: song.thumbnailUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Title/Artist
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song.artist,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Options
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: sList.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
