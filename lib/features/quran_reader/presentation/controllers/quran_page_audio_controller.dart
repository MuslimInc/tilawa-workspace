import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class QuranPageAudioController extends ChangeNotifier {
  QuranPageAudioController() {
    _playerStateSubscription = _globalPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_isDisposed) return;
        _playingWordId = null;
        notifyListeners();
      }
    });
  }
  bool _isDisposed = false;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void dispose() {
    _isDisposed = true;
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  // Actually, keeping one player for the app is usually better to avoid audio overlap.
  // The previous implementation used a static player. Let's stick to that pattern or ensure we dispose correctly.
  // For the `QuranPageWidget`, if it's reused, we might want a single player instance passed down or a static one.
  // Let's use a static instance inside the controller for now to mimic the previous behavior of "one global player for words".

  // Reverting to instance-based for the controller, but the underlying player can be static or managed by a service locator.
  // Given the scope, a static player inside the class is simplest for this refactor to ensure only one word plays at a time across the entire app.

  static final AudioPlayer _globalPlayer = AudioPlayer();

  int? _playingWordId;
  int? get playingWordId => _playingWordId;

  Future<void> playWord(String? url, int wordId) async {
    if (url == null) return;

    if (_playingWordId == wordId && _globalPlayer.playing) {
      await stop();
      return;
    }

    try {
      // If another controller was playing, we might need a way to know.
      // But simpler: just stop whatever is playing.
      await _globalPlayer.stop();

      _playingWordId = wordId;
      notifyListeners();

      final fullUrl = 'https://audio.qurancdn.com/$url';
      await _globalPlayer.setUrl(fullUrl);
      await _globalPlayer.play();
    } catch (e) {
      _playingWordId = null;
      notifyListeners();
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> stop() async {
    await _globalPlayer.stop();
    _playingWordId = null;
    notifyListeners();
  }
}
