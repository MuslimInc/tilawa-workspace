import 'package:injectable/injectable.dart';

/// Tracks an in-flight interactive Google sign-in so other startup work
/// (e.g. forced-update gate presentation) can defer until CM / HiddenActivity finishes.
@lazySingleton
class GoogleSignInSessionTracker {
  bool _inFlight = false;

  bool get inFlight => _inFlight;

  void markStarted() {
    _inFlight = true;
  }

  void markFinished() {
    _inFlight = false;
  }
}
