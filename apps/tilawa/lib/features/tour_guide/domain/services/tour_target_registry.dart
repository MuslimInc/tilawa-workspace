import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

/// Maps stable target ids to [GlobalKey] instances registered by [TourTarget].
@lazySingleton
class TourTargetRegistry {
  final Map<String, GlobalKey> _keys = <String, GlobalKey>{};

  void register(String targetId, GlobalKey key) {
    _keys[targetId] = key;
  }

  void unregister(String targetId, GlobalKey key) {
    final GlobalKey? existing = _keys[targetId];
    if (identical(existing, key)) {
      _keys.remove(targetId);
    }
  }

  GlobalKey? keyFor(String targetId) => _keys[targetId];

  bool hasTarget(String targetId) => _keys.containsKey(targetId);
}
