import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:muzakri/queue_state.dart';
import 'package:rxdart/rxdart.dart';

abstract class AudioPlayerHandler implements AudioHandler {
  Stream<QueueState> get queueState;
  Future<void> moveQueueItem(int currentIndex, int newIndex);
  ValueStream<double> get volume;
  Future<void> setVolume(double volume);
  ValueStream<double> get speed;
}
