import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'dart:math';
import '../models/song_model.dart';

/// Singleton audio player — one instance for the entire app
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        skipNext();
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  List<Song> _playlist = [];
  int _currentIndex = -1;
  
  // Stream to notify UI when the current song changes
  final _songController = StreamController<Song?>.broadcast();
  Stream<Song?> get currentSongStream => _songController.stream;

  final _shuffleModeController = StreamController<bool>.broadcast();
  Stream<bool> get shuffleModeStream => _shuffleModeController.stream;
  bool _isShuffleModeEnabled = false;
  bool get isShuffleModeEnabled => _isShuffleModeEnabled;

  final _loopModeController = StreamController<bool>.broadcast();
  Stream<bool> get loopModeStream => _loopModeController.stream;
  bool _isLoopModeEnabled = false;
  bool get isLoopModeEnabled => _isLoopModeEnabled;

  AudioPlayer get player => _player;
  Song? get currentSong => _currentIndex >= 0 && _currentIndex < _playlist.length ? _playlist[_currentIndex] : null;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  Future<void> loadAndPlay(Song song, {List<Song>? playlist}) async {
    // If same song is already playing, just resume or do nothing
    if (currentSong?.id == song.id) {
      if (!_player.playing) await _player.play();
      return;
    }
    
    // Update playlist if provided, or keep existing one if the song is part of it
    if (playlist != null) {
      _playlist = playlist;
    } else if (!_playlist.any((s) => s.id == song.id)) {
      _playlist = [song];
    }
    
    _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
    _songController.add(song);
    
    await _player.stop();
    await _player.setUrl(song.audioUrl);
    await _player.play();
  }

  Future<void> skipNext() async {
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
    final nextSong = _playlist[nextIndex];
    await loadAndPlay(nextSong, playlist: _playlist);
  }

  Future<void> skipPrevious() async {
    if (_playlist.isEmpty) return;
    // If more than 3 seconds in, restart the song
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    final prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    final prevSong = _playlist[prevIndex];
    await loadAndPlay(prevSong, playlist: _playlist);
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();

  Future<void> seekTo(Duration position) => _player.seek(position);

  Future<void> toggleShuffle() async {
    _isShuffleModeEnabled = !_isShuffleModeEnabled;
    _shuffleModeController.add(_isShuffleModeEnabled);
  }

  Future<void> toggleLoop() async {
    _isLoopModeEnabled = !_isLoopModeEnabled;
    _loopModeController.add(_isLoopModeEnabled);
    await _player.setLoopMode(_isLoopModeEnabled ? LoopMode.one : LoopMode.off);
  }

  Future<void> dispose() {
    _songController.close();
    _shuffleModeController.close();
    _loopModeController.close();
    return _player.dispose();
  }
}
