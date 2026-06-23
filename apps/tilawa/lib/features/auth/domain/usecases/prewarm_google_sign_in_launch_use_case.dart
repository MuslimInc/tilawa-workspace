import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';

import '../gateways/google_sign_in_launch_gateway.dart';
import '../services/google_sign_in_launch_readiness_store.dart';
import 'prepare_google_sign_in_use_case.dart';

/// Initializes Google sign-in and caches launch readiness before user taps.
@injectable
class PrewarmGoogleSignInLaunchUseCase {
  PrewarmGoogleSignInLaunchUseCase(
    this._prepareGoogleSignIn,
    this._readinessStore,
  );

  final PrepareGoogleSignInUseCase _prepareGoogleSignIn;
  final GoogleSignInLaunchReadinessStore _readinessStore;

  Future<void> call({GoogleSignInLaunchGateway? gateway}) async {
    try {
      await _prepareGoogleSignIn();
    } catch (error, stackTrace) {
      logger.w(
        '[GoogleSignInButton] prewarm prepare failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (gateway == null) {
      return;
    }

    try {
      final readiness = await gateway.checkReadiness();
      _readinessStore.cache(readiness);
      logger.d(
        '[GoogleSignInButton] prewarmGoogleSignIn '
        'readiness=${readiness.runtimeType}',
      );
    } catch (error, stackTrace) {
      logger.w(
        '[GoogleSignInButton] prewarm readiness failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
