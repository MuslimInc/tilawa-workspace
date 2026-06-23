import 'package:injectable/injectable.dart';

import '../entities/google_sign_in_launch_readiness.dart';

/// In-memory cache of the last prewarm readiness check for login fast-path.
@lazySingleton
class GoogleSignInLaunchReadinessStore {
  GoogleSignInLaunchReadiness? _cached;

  GoogleSignInLaunchReadiness? get cached => _cached;

  void cache(GoogleSignInLaunchReadiness readiness) {
    _cached = readiness;
  }

  void clear() {
    _cached = null;
  }
}
