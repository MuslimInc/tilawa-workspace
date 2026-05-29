import '../entities/tasbeeh_dhikr.dart';
import 'package:injectable/injectable.dart';

/// Decides when a saved-dhikr counter should pulse haptic/visual target feedback.
@lazySingleton
class TasbeehTargetReachedPolicy {
  const TasbeehTargetReachedPolicy();

  bool shouldNotify(TasbeehDhikr dhikr) {
    return dhikr.targetCount > 0 && dhikr.count >= dhikr.targetCount;
  }
}
