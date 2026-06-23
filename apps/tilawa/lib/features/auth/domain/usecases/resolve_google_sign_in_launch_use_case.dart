import 'package:injectable/injectable.dart';

import '../entities/google_sign_in_launch_readiness.dart';
import '../gateways/google_sign_in_launch_gateway.dart';
import '../services/google_sign_in_launch_readiness_store.dart';

/// Whether sign-in was triggered by user tap or login auto sign-in.
enum GoogleSignInLaunchTrigger {
  manual,
  auto,
}

/// Resolves launch readiness using the prewarm cache and OEM UI-settle policy.
@injectable
class ResolveGoogleSignInLaunchUseCase {
  ResolveGoogleSignInLaunchUseCase(this._readinessStore);

  final GoogleSignInLaunchReadinessStore _readinessStore;

  /// When [gateway] is null, returns [GoogleSignInLaunchReady] immediately.
  Future<GoogleSignInLaunchReadiness> call({
    required GoogleSignInLaunchTrigger trigger,
    GoogleSignInLaunchGateway? gateway,
  }) async {
    if (gateway == null) {
      return const GoogleSignInLaunchReadiness.ready();
    }

    Future<GoogleSignInLaunchReadiness> readReadiness() {
      final GoogleSignInLaunchReadiness? cached = _readinessStore.cached;
      if (cached != null) {
        return Future<GoogleSignInLaunchReadiness>.value(cached);
      }
      return gateway.checkReadiness();
    }

    if (trigger == GoogleSignInLaunchTrigger.manual) {
      return readReadiness();
    }

    GoogleSignInLaunchReadiness? resolved;
    await gateway.runAfterUiSettled(() async {
      resolved = await readReadiness();
    });
    return resolved ?? const GoogleSignInLaunchReadiness.ready();
  }
}
