import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../../domain/entities/reel.dart';

/// Keeps at most three [VideoPlayerController]s: previous, current, next.
class ReelPlayerPool extends ChangeNotifier {
  ReelPlayerPool();

  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, Future<void>> _initFutures = {};
  int? _currentReelId;
  List<Reel> _feed = const [];
  int _index = 0;

  VideoPlayerController? controllerFor(int reelId) => _controllers[reelId];

  VideoPlayerController? get currentController =>
      _currentReelId == null ? null : _controllers[_currentReelId!];

  int? get currentReelId => _currentReelId;

  Future<void> syncFeed(List<Reel> feed, int index) async {
    _feed = feed;
    await setIndex(index);
  }

  Future<void> setIndex(int index) async {
    if (_feed.isEmpty) return;
    _index = index.clamp(0, _feed.length - 1);
    final current = _feed[_index];
    _currentReelId = current.id;

    final idsToKeep = <int>{
      current.id,
      if (_index > 0) _feed[_index - 1].id,
      if (_index < _feed.length - 1) _feed[_index + 1].id,
    };

    // Dispose outside window.
    final toRemove = _controllers.keys
        .where((id) => !idsToKeep.contains(id))
        .toList();
    for (final id in toRemove) {
      await _disposeController(id);
    }

    // Ensure window initialized.
    for (final id in idsToKeep) {
      final reel = _feed.firstWhere((r) => r.id == id);
      await _ensure(reel);
    }

    // Pause non-current, play current.
    for (final entry in _controllers.entries) {
      final c = entry.value;
      if (!c.value.isInitialized) continue;
      if (entry.key == current.id) {
        unawaited(c.setLooping(true));
        unawaited(c.play());
      } else {
        unawaited(c.pause());
      }
    }
    notifyListeners();
  }

  Future<void> _ensure(Reel reel) async {
    if (_controllers.containsKey(reel.id)) return;
    if (_initFutures.containsKey(reel.id)) {
      await _initFutures[reel.id];
      return;
    }
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(reel.videoUrl),
    );
    _controllers[reel.id] = controller;
    final future = controller
        .initialize()
        .then((_) {
          unawaited(controller.setLooping(true));
          notifyListeners();
        })
        .catchError((Object e, StackTrace st) {
          debugPrint('ReelPlayerPool init failed for ${reel.id}: $e');
          notifyListeners();
        });
    _initFutures[reel.id] = future;
    await future;
    _initFutures.remove(reel.id);
  }

  Future<void> togglePlayPause() async {
    final c = currentController;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    notifyListeners();
  }

  Future<void> pause() async {
    final c = currentController;
    if (c == null || !c.value.isInitialized) return;
    await c.pause();
    notifyListeners();
  }

  Future<void> play() async {
    final c = currentController;
    if (c == null || !c.value.isInitialized) return;
    await c.play();
    notifyListeners();
  }

  Future<void> retry(Reel reel) async {
    await _disposeController(reel.id);
    await _ensure(reel);
    if (_currentReelId == reel.id) {
      await play();
    }
  }

  Future<void> _disposeController(int id) async {
    final c = _controllers.remove(id);
    _initFutures.remove(id);
    await c?.dispose();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      unawaited(controller.dispose());
    }
    _controllers.clear();
    _initFutures.clear();
    super.dispose();
  }
}
