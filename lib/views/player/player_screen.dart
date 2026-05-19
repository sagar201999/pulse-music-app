import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../models/song_model.dart';
import '../../services/audio_service.dart' as svc;
import '../../services/api_service.dart';
import '../../models/playlist_model.dart';

class PlayerScreen extends StatefulWidget {
  final Song song;
  final List<Song>? playlist;

  const PlayerScreen({super.key, required this.song, this.playlist});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final svc.AudioPlayerService _audioService = svc.AudioPlayerService();
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  late AnimationController _albumArtController;

  VideoPlayerController? _videoController;
  StreamSubscription? _songSub;
  StreamSubscription? _playerStateSub;
  bool _videoInitTriggered = false;

  @override
  void initState() {
    super.initState();
    _albumArtController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _initPlayer();

    _songSub = _audioService.currentSongStream.listen((song) {
      _videoInitTriggered = false;
      if (_videoController != null) {
        _currentVideoUrl = null;
        final old = _videoController;
        _videoController = null;
        if (mounted) setState(() {});
        old?.dispose();
      }
    });

    _playerStateSub = _audioService.playerStateStream.listen((state) {
      if (!_videoInitTriggered && state.processingState == ProcessingState.ready) {
        final currentVideo = _audioService.currentSong?.videoThumbnail ?? widget.song.videoThumbnail;
        if (currentVideo != null && currentVideo.isNotEmpty) {
          _videoInitTriggered = true;
          _setupVideoPlayer(currentVideo);
        }
      }
    });
  }

  Song get currentSong => _audioService.currentSong ?? widget.song;

  void _showAddToPlaylistSheet(BuildContext context, Song song) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AddToPlaylistSheet(song: song),
    );
  }

  String? _currentVideoUrl;

  Future<void> _setupVideoPlayer(String? videoUrl) async {
    if (_currentVideoUrl == videoUrl) return;
    _currentVideoUrl = videoUrl;

    final oldController = _videoController;
    _videoController = null;
    if (mounted) setState(() {});
    if (oldController != null) await oldController.dispose();

    if (videoUrl == null || videoUrl.isEmpty) {
      return;
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _videoController = controller;
    
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      if (mounted) {
        setState(() {});
        if (_audioService.isPlaying) {
          await controller.play();
        }
      }
    } catch (e) {
      debugPrint("Video error: $e");
    }
  }

  Future<void> _initPlayer() async {
    try {
      // If this song is already the current one, don't reload it
      if (_audioService.currentSong?.id != widget.song.id) {
        await _audioService.loadAndPlay(widget.song, playlist: widget.playlist);
        _api.incrementPlayCount(widget.song.id);
      }
      
      _albumArtController.repeat();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  void dispose() {
    _albumArtController.dispose();
    _songSub?.cancel();
    _playerStateSub?.cancel();
    _videoController?.dispose();
    // Do NOT pause here anymore, so music continues in mini-player
    super.dispose();
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '0:00';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Song?>(
      stream: _audioService.currentSongStream,
      initialData: _audioService.currentSong,
      builder: (context, songSnapshot) {
        final currentSong = songSnapshot.data ?? widget.song;

        return Scaffold(
      backgroundColor: AppColors.playerBg,
      body: Stack(
        children: [
          // ── Video Background ──────────────────────────────────────────────
          if (_videoController != null && _videoController!.value.isInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
          
          if (_videoController != null && _videoController!.value.isInitialized)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5), // Dim overlay for UI contrast
              ),
            ),

          // ── Foreground UI ──────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top Bar ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textPrimary, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Now Playing',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.playlist_add, color: AppColors.textPrimary, size: 28),
                    onPressed: () => _showAddToPlaylistSheet(context, currentSong),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Album Art (rotating circle) ──────────────────────────────────
            if (_videoController == null || !_videoController!.value.isInitialized)
              Center(
                child: StreamBuilder<PlayerState>(
                  stream: _audioService.playerStateStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data?.playing ?? false;
                    if (isPlaying) {
                      _albumArtController.repeat();
                    } else {
                      _albumArtController.stop();
                    }

                    return AnimatedBuilder(
                      animation: _albumArtController,
                      builder: (_, child) => Transform.rotate(
                        angle: _albumArtController.value * 2 * 3.14159265,
                        child: child,
                      ),
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: currentSong.parsedHexColor.withOpacity(0.6),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _loading
                              ? Container(
                                  color: AppColors.cardColor,
                                  child: const Icon(Icons.music_note,
                                      color: AppColors.secondary, size: 60),
                                )
                              : CachedNetworkImage(
                                  imageUrl: currentSong.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Container(
                                    color: AppColors.cardColor,
                                    child: const Icon(Icons.music_note,
                                        color: AppColors.secondary, size: 60),
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              const Spacer(),

            const SizedBox(height: 40),

            // ── Song Info ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentSong.artist,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.favorite_border_rounded,
                      color: AppColors.textSecondary, size: 26),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Progress Bar ─────────────────────────────────────────────────
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text('Error: $_error',
                    style: const TextStyle(color: AppColors.error, fontSize: 12)),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: StreamBuilder<Duration>(
                  stream: _audioService.positionStream,
                  builder: (context, posSnap) {
                    return StreamBuilder<Duration?>(
                      stream: _audioService.durationStream,
                      builder: (context, durSnap) {
                        final position = posSnap.data ?? Duration.zero;
                        final duration = durSnap.data ?? Duration.zero;
                        final progress = duration.inMilliseconds > 0
                            ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                            : 0.0;

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                activeTrackColor: AppColors.textPrimary,
                                inactiveTrackColor: AppColors.secondary,
                                thumbColor: AppColors.textPrimary,
                                overlayColor: AppColors.textPrimary.withOpacity(0.15),
                              ),
                              child: Slider(
                                value: progress,
                                onChanged: (v) {
                                  if (duration.inMilliseconds > 0) {
                                    _audioService.seekTo(
                                      Duration(milliseconds: (v * duration.inMilliseconds).toInt()),
                                    );
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(position),
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  Text(_formatDuration(duration),
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // ── Controls ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shuffle_rounded, color: AppColors.secondary, size: 26),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, color: AppColors.textPrimary, size: 36),
                    onPressed: () => _audioService.skipPrevious(),
                  ),

                  // ▶ / ⏸ — Main play/pause
                  StreamBuilder<PlayerState>(
                    stream: _audioService.playerStateStream,
                    builder: (context, snapshot) {
                      final state = snapshot.data;
                      final isLoading = state?.processingState == ProcessingState.loading
                          || state?.processingState == ProcessingState.buffering;
                      final isPlaying = state?.playing ?? false;

                      return GestureDetector(
                        onTap: () {
                          if (isPlaying) {
                            _audioService.pause();
                            _videoController?.pause();
                          } else {
                            _audioService.play();
                            _videoController?.play();
                          }
                        },
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: const BoxDecoration(
                            color: AppColors.textPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.playerBg,
                                  ),
                                )
                              : Icon(
                                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: AppColors.playerBg,
                                  size: 38,
                                ),
                        ),
                      );
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: AppColors.textPrimary, size: 36),
                    onPressed: () => _audioService.skipNext(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.repeat_rounded, color: AppColors.secondary, size: 26),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      ],
      ),
    );
      },
    );
  }
}

// ── Add To Playlist Bottom Sheet ──────────────────────────────────────────────
class _AddToPlaylistSheet extends StatefulWidget {
  final Song song;
  const _AddToPlaylistSheet({required this.song});

  @override
  State<_AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<_AddToPlaylistSheet> {
  List<Playlist> _userPlaylists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final lists = await ApiService().getUserPlaylists();
      setState(() {
        _userPlaylists = lists;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addToPlaylist(Playlist playlist) async {
    final success = await ApiService().addSongToPlaylist(playlist.id, widget.song.id);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Added to ${playlist.name}' : 'Failed to add to playlist'),
        backgroundColor: success ? AppColors.primary : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Add to Playlist',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (_userPlaylists.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('You have no private playlists yet. Go to the dashboard to create global playlists, or implement mobile creation soon!', 
                style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _userPlaylists.length,
                itemBuilder: (ctx, i) {
                  final p = _userPlaylists[i];
                  return ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        image: DecorationImage(image: NetworkImage(p.thumbnailUrl), fit: BoxFit.cover),
                      ),
                    ),
                    title: Text(p.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text('${p.trackCount} tracks', style: const TextStyle(color: AppColors.textSecondary)),
                    onTap: () => _addToPlaylist(p),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
