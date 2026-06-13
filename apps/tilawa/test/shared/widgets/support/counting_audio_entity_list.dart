import 'dart:collection';

import 'package:tilawa_core/entities/audio.dart';

/// Tracks [length] and `[]` reads so tests can assert O(1) hot paths.
final class CountingAudioEntityList extends ListBase<AudioEntity> {
  CountingAudioEntityList(List<AudioEntity> inner)
    : _inner = List<AudioEntity>.from(inner);

  final List<AudioEntity> _inner;

  int lengthAccessCount = 0;
  int indexAccessCount = 0;

  int get totalAccessCount => lengthAccessCount + indexAccessCount;

  void resetCounts() {
    lengthAccessCount = 0;
    indexAccessCount = 0;
  }

  @override
  int get length {
    lengthAccessCount++;
    return _inner.length;
  }

  @override
  set length(int newLength) {
    lengthAccessCount++;
    _inner.length = newLength;
  }

  @override
  AudioEntity operator [](int index) {
    indexAccessCount++;
    return _inner[index];
  }

  @override
  void operator []=(int index, AudioEntity value) {
    _inner[index] = value;
  }
}
