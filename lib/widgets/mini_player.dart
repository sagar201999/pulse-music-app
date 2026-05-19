import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import '../models/song_model.dart';
import '../services/audio_service.dart';
import '../views/player/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService();

    return StreamBuilder<Song?>(
      stream: audioService.currentSongStream,
      initialData: audioService.currentSong,
      builder: (context, songSnapshot) {
        final song = songSnapshot.data;
        if (song == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlayerScreen(song: song)),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: song.thumbnailUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title + Artist
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Controls
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 24),
                              onPressed: () => audioService.skipPrevious(),
                            ),
                            StreamBuilder<PlayerState>(
                              stream: audioService.playerStateStream,
                              builder: (context, stateSnapshot) {
                                final isPlaying = stateSnapshot.data?.playing ?? false;
                                return IconButton(
                                  icon: Icon(
                                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: () {
                                    if (isPlaying) {
                                      audioService.pause();
                                    } else {
                                      audioService.play();
                                    }
                                  },
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 24),
                              onPressed: () => audioService.skipNext(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Progress Bar (Simple line)
                StreamBuilder<Duration>(
                  stream: audioService.positionStream,
                  builder: (context, posSnap) {
                    final position = posSnap.data ?? Duration.zero;
                    final duration = audioService.duration ?? Duration.zero;
                    final progress = duration.inMilliseconds > 0
                        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                        : 0.0;
                    
                    return Container(
                      height: 2,
                      width: double.infinity,
                      alignment: Alignment.centerLeft,
                      color: Colors.white10,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(color: AppColors.primary),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
