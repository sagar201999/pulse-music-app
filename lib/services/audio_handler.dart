import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'dart:math';
import '../models/song_model.dart';

/// The bridge between your app and Android's MediaSession.
///
/// This class:
///  - Wraps the just_audio [AudioPlayer]
///  - Broadcasts [MediaItem] (song info) → OS renders it in notification / lock screen
///  - Broadcasts [PlaybackState] (playing/paused/position) → OS renders progress bar
///  - Handles OS-triggered callbacks (notification buttons, headphone buttons, lock screen)
class PulseAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  List<Song> _playlist = [];
  int _currentIndex = -1;

  bool _isShuffleModeEnabled = false;
  bool _isLoopModeEnabled = false;

  // Internal streams for the UI (same as before)
  final _songController = StreamController<Song?>.broadcast();
  final _shuffleModeController = StreamController<bool>.broadcast();
  final _loopModeController = StreamController<bool>.broadcast();

  Stream<Song?> get currentSongStream => _songController.stream;
  Stream<bool> get shuffleModeStream => _shuffleModeController.stream;
  Stream<bool> get loopModeStream => _loopModeController.stream;

  Song? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : null;

  AudioPlayer get player => _player;
  bool get isShuffleModeEnabled => _isShuffleModeEnabled;
  bool get isLoopModeEnabled => _isLoopModeEnabled;

  PulseAudioHandler() {
    // Auto-advance to next song when current one finishes
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipToNext();
      }
      _updatePlaybackState();
    });

    // Update media item duration dynamically when just_audio loads the song
    _player.durationStream.listen((duration) {
      if (duration != null && mediaItem.value != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });

    // Keep Android MediaSession playback state in sync with player
    _listenToPlaybackEvents();
  }

  /// Unified method to update Android PlaybackState
  void _updatePlaybackState() {
    final processingState = {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState] ??
        AudioProcessingState.idle;

    playbackState.add(PlaybackState(
      // Controls shown in the notification
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      // Actions available but not shown as buttons (e.g., seeking via progress bar)
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      // Which controls appear in the compact notification view (indices into 'controls')
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingState,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      updateTime: DateTime.now(),
    ));
  }

  /// Pushes real-time playback state to Android — this powers the
  /// notification progress bar, play/pause icon, and headphone controls.
  void _listenToPlaybackEvents() {
    _player.playbackEventStream.listen(
      (event) {
        _updatePlaybackState();
      },
      onError: (Object e, StackTrace _) {
        // Silently ignore playback event errors to avoid crashing notification
      },
    );
  }

  /// Pushes song metadata to Android — this populates the notification card
  /// (album art, title, artist) and the lock screen / quick settings widget.
  void _updateMediaItem(Song song) {
    mediaItem.add(MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artUri: Uri.parse(song.thumbnailUrl),
      duration: Duration(seconds: song.duration),
    ));
  }

  // ── Public API (called by AudioPlayerService facade) ──────────────────────

  Future<void> loadAndPlay(Song song, {List<Song>? playlist}) async {
    // Same song already playing → just resume
    if (currentSong?.id == song.id) {
      if (!_player.playing) await _player.play();
      return;
    }

    if (playlist != null) {
      _playlist = playlist;
    } else if (!_playlist.any((s) => s.id == song.id)) {
      _playlist = [song];
    }

    _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
    _songController.add(song);
    _updateMediaItem(song); // ← notifies Android of new song info

    await _player.stop();
    await _player.setUrl(song.audioUrl);
    await _player.play();
  }

  Future<void> seekTo(Duration position) => _player.seek(position);

  Future<void> toggleShuffle() async {
    _isShuffleModeEnabled = !_isShuffleModeEnabled;
    _shuffleModeController.add(_isShuffleModeEnabled);
  }

  Future<void> toggleLoop() async {
    _isLoopModeEnabled = !_isLoopModeEnabled;
    _loopModeController.add(_isLoopModeEnabled);
    await _player.setLoopMode(
        _isLoopModeEnabled ? LoopMode.one : LoopMode.off);
  }

  // ── BaseAudioHandler overrides (called by OS / notification buttons) ───────

  /// Called when user taps ▶ in notification or presses headphone button
  @override
  Future<void> play() => _player.play();

  /// Called when user taps ⏸ in notification
  @override
  Future<void> pause() => _player.pause();

  /// Called when user drags the seek bar in notification
  @override
  Future<void> seek(Duration position) => _player.seek(position);

  /// Called when user taps ⏭ in notification
  @override
  Future<void> skipToNext() async {
    if (_playlist.isEmpty) return;
    int nextIndex;
    if (_isShuffleModeEnabled && _playlist.length > 1) {
      nextIndex = Random().nextInt(_playlist.length);
      if (nextIndex == _currentIndex) {
        nextIndex = (nextIndex + 1) % _playlist.length;
      }
    } else {
      nextIndex = (_currentIndex + 1) % _playlist.length;
    }
    await loadAndPlay(_playlist[nextIndex], playlist: _playlist);
  }

  /// Called when user taps ⏮ in notification
  @override
  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;
    // If more than 3 seconds in → restart current song
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    final prevIndex =
        (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await loadAndPlay(_playlist[prevIndex], playlist: _playlist);
  }

  /// Called when audio_service stops (e.g., user swipes away notification)
  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  Future<void> disposeHandler() async {
    await _songController.close();
    await _shuffleModeController.close();
    await _loopModeController.close();
    await _player.dispose();
  }
}
