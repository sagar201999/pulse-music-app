import 'package:just_audio/just_audio.dart';
import 'dart:async';
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
    final nextIndex = (_currentIndex + 1) % _playlist.length;
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

  Future<void> dispose() {
    _songController.close();
    return _player.dispose();
  }
}
