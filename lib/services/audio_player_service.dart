import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import 'audio_handler.dart';

/// Singleton facade over [PulseAudioHandler].
///
/// The public API is identical to the old AudioPlayerService, so every
/// screen/widget in the app continues to work without modification.
///
/// Internally all calls are delegated to the handler, which routes
/// play/pause/seek both to just_audio AND to the Android MediaSession
/// (notification, lock screen, quick settings).
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  late PulseAudioHandler _handler;

  /// Called once in main() after AudioService.init() returns the handler.
  void initHandler(PulseAudioHandler handler) {
    _handler = handler;
  }

  // ── Song / Playlist state ─────────────────────────────────────────────────

  Song? get currentSong => _handler.currentSong;

  Stream<Song?> get currentSongStream => _handler.currentSongStream;

  // ── Shuffle / Loop state ──────────────────────────────────────────────────

  Stream<bool> get shuffleModeStream => _handler.shuffleModeStream;
  Stream<bool> get loopModeStream => _handler.loopModeStream;
  bool get isShuffleModeEnabled => _handler.isShuffleModeEnabled;
  bool get isLoopModeEnabled => _handler.isLoopModeEnabled;

  // ── Raw player streams (consumed by UI widgets) ───────────────────────────

  Stream<PlayerState> get playerStateStream => _handler.player.playerStateStream;
  Stream<Duration?> get durationStream => _handler.player.durationStream;
  Stream<Duration> get positionStream => _handler.player.positionStream;

  bool get isPlaying => _handler.player.playing;
  Duration get position => _handler.player.position;
  Duration? get duration => _handler.player.duration;

  // ── Playback commands ─────────────────────────────────────────────────────

  Future<void> loadAndPlay(Song song, {List<Song>? playlist}) =>
      _handler.loadAndPlay(song, playlist: playlist);

  Future<void> play() => _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> seekTo(Duration position) => _handler.seekTo(position);
  Future<void> skipNext() => _handler.skipToNext();
  Future<void> skipPrevious() => _handler.skipToPrevious();
  Future<void> toggleShuffle() => _handler.toggleShuffle();
  Future<void> toggleLoop() => _handler.toggleLoop();

  Future<void> dispose() => _handler.disposeHandler();
}
