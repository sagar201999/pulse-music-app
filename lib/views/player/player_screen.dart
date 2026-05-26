import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../models/song_model.dart';
import '../../services/audio_service.dart' as svc;
import '../../services/api_service.dart';
import '../../models/playlist_model.dart';
import '../../core/services/auth_service.dart';

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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
        await controller.play();
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
              // ── Dark Blue → Light Blue → Violet Multi-Color Gradient ──────
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.38, 0.72, 1.0],
                      colors: [
                        Color(0xFF0A0F2E), // deep dark navy blue (top-left)
                        Color(0xFF1A3A6E), // dark royal blue (upper-mid)
                        Color(0xFF2D6BB5), // electric/light blue (mid)
                        Color(0xFF6B2FA0), // deep violet (bottom-right)
                      ],
                    ),
                  ),
                ),
              ),

              // ── Video Background (full screen when available) ─────────────
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.black.withOpacity(0.65),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Foreground UI ─────────────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    // ── Top Bar ──────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          // Back button — frosted circle
                          _GlassIconButton(
                            icon: CupertinoIcons.chevron_back,
                            onTap: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'Now Playing',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Heart / favourite — frosted circle
                          _GlassIconButton(
                            icon: AuthService().isLiked(currentSong.id)
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            iconColor: AuthService().isLiked(currentSong.id)
                                ? AppColors.accent
                                : AppColors.textPrimary,
                            onTap: () {
                              setState(() {
                                AuthService().toggleLikeLocal(currentSong.id);
                              });
                              _api.toggleLike(currentSong.id).then((success) {
                                if (!success && mounted) {
                                  setState(() {
                                    AuthService().toggleLikeLocal(currentSong.id);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to update liked songs')),
                                  );
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          // Playlist / Add-to-playlist — frosted circle
                          _GlassIconButton(
                            icon: CupertinoIcons.music_note_list,
                            onTap: () => _showAddToPlaylistSheet(context, currentSong),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // ── Album Art (rotating circle) ───────────────────────────
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
                                angle: _albumArtController.value * 2 * math.pi,
                                child: child,
                              ),
                              child: Container(
                                width: 270,
                                height: 270,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.55),
                                      blurRadius: 50,
                                      spreadRadius: 12,
                                    ),
                                    BoxShadow(
                                      color: AppColors.accent.withOpacity(0.25),
                                      blurRadius: 80,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.18),
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _loading
                                      ? Container(
                                          color: AppColors.cardColor,
                                          child: const Icon(CupertinoIcons.music_note,
                                              color: AppColors.secondary, size: 60),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: currentSong.thumbnailUrl,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, _, _) => Container(
                                            color: AppColors.cardColor,
                                            child: const Icon(CupertinoIcons.music_note,
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

                    const SizedBox(height: 36),

                    // ── Song Info ─────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            currentSong.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentSong.artist,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Waveform Progress Bar ─────────────────────────────────
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
                                    // Waveform painter + tap-to-seek
                                    GestureDetector(
                                      onHorizontalDragUpdate: (details) {
                                        final box = context.findRenderObject() as RenderBox?;
                                        if (box == null) return;
                                        final localX = details.localPosition.dx.clamp(0, box.size.width);
                                        final ratio = localX / box.size.width;
                                        if (duration.inMilliseconds > 0) {
                                          _audioService.seekTo(Duration(
                                              milliseconds: (ratio * duration.inMilliseconds).toInt()));
                                        }
                                      },
                                      onTapDown: (details) {
                                        final box = context.findRenderObject() as RenderBox?;
                                        if (box == null) return;
                                        final ratio = (details.localPosition.dx / box.size.width).clamp(0.0, 1.0);
                                        if (duration.inMilliseconds > 0) {
                                          _audioService.seekTo(Duration(
                                              milliseconds: (ratio * duration.inMilliseconds).toInt()));
                                        }
                                      },
                                      child: SizedBox(
                                        height: 48,
                                        child: CustomPaint(
                                          painter: _WaveformPainter(progress: progress),
                                          size: const Size(double.infinity, 48),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_formatDuration(position),
                                            style: const TextStyle(
                                                color: AppColors.textSecondary, fontSize: 12)),
                                        Text(_formatDuration(duration),
                                            style: const TextStyle(
                                                color: AppColors.textSecondary, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 24),

                    // ── Controls ──────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Shuffle
                          StreamBuilder<bool>(
                            stream: _audioService.shuffleModeStream,
                            initialData: _audioService.isShuffleModeEnabled,
                            builder: (context, snapshot) {
                              final isEnabled = snapshot.data ?? false;
                              return IconButton(
                                icon: Icon(
                                  CupertinoIcons.shuffle,
                                  color: isEnabled
                                      ? AppColors.primaryLight
                                      : AppColors.iconInactive,
                                  size: 22,
                                ),
                                onPressed: () => _audioService.toggleShuffle(),
                              );
                            },
                          ),

                          // Skip Previous
                          IconButton(
                            icon: const Icon(CupertinoIcons.backward_end_fill,
                                color: AppColors.textPrimary, size: 28),
                            onPressed: () => _audioService.skipPrevious(),
                          ),

                          // Play / Pause — large frosted circle
                          StreamBuilder<PlayerState>(
                            stream: _audioService.playerStateStream,
                            builder: (context, snapshot) {
                              final state = snapshot.data;
                              final isLoading =
                                  state?.processingState == ProcessingState.loading ||
                                  state?.processingState == ProcessingState.buffering;
                              final isPlaying = state?.playing ?? false;

                                // Play/Pause — true BackdropFilter glass circle
                                return GestureDetector(
                                  onTap: () {
                                    if (isPlaying) {
                                      _audioService.pause();
                                    } else {
                                      _audioService.play();
                                    }
                                  },
                                  child: ClipOval(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                      child: Container(
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.28),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.55),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: isLoading
                                            ? const Padding(
                                                padding: EdgeInsets.all(18),
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Icon(
                                                isPlaying
                                                    ? CupertinoIcons.pause_fill
                                                    : CupertinoIcons.play_fill,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                      ),
                                    ),
                                  ),
                                );
                            },
                          ),

                          // Skip Next
                          IconButton(
                            icon: const Icon(CupertinoIcons.forward_end_fill,
                                color: AppColors.textPrimary, size: 28),
                            onPressed: () => _audioService.skipNext(),
                          ),

                          // Loop
                          StreamBuilder<bool>(
                            stream: _audioService.loopModeStream,
                            initialData: _audioService.isLoopModeEnabled,
                            builder: (context, snapshot) {
                              final isEnabled = snapshot.data ?? false;
                              return IconButton(
                                icon: Icon(
                                  CupertinoIcons.repeat,
                                  color: isEnabled
                                      ? AppColors.primaryLight
                                      : AppColors.iconInactive,
                                  size: 22,
                                ),
                                onPressed: () => _audioService.toggleLoop(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),
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

// ── Frosted Glass Icon Button (true BackdropFilter blur) ──────────────────────
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // white tint over the blurred background
              color: Colors.white.withOpacity(0.18),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }
}

// ── Waveform Painter ──────────────────────────────────────────────────────────
class _WaveformPainter extends CustomPainter {
  final double progress;

  _WaveformPainter({required this.progress});

  // Fixed pseudo-random bar heights so waveform looks the same every frame
  static final List<double> _barHeights = _generateBarHeights(52);

  static List<double> _generateBarHeights(int count) {
    final rng = math.Random(42); // fixed seed → deterministic look
    return List.generate(count, (_) => 0.25 + rng.nextDouble() * 0.75);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = _barHeights.length;
    final barWidth = 3.0;
    final gap = (size.width - barCount * barWidth) / (barCount - 1);
    final maxBarH = size.height;
    final cy = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + gap);
      final barH = maxBarH * _barHeights[i];
      final ratio = i / barCount;

      final isPlayed = ratio <= progress;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = isPlayed
            ? Colors.white
            : Colors.white.withOpacity(0.35);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, cy),
          width: barWidth,
          height: barH,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.progress != progress;
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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.iconInactive.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Add to Playlist',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (_userPlaylists.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'You have no private playlists yet. Go to the dashboard to create global playlists, or implement mobile creation soon!',
                style: TextStyle(color: AppColors.textSecondary),
              ),
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
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                            image: NetworkImage(p.thumbnailUrl), fit: BoxFit.cover),
                      ),
                    ),
                    title: Text(p.name,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text('${p.trackCount} tracks',
                        style: const TextStyle(color: AppColors.textSecondary)),
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
