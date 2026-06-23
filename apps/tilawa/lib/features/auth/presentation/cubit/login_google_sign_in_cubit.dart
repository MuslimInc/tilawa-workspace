import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';

import '../../domain/entities/google_sign_in_launch_readiness.dart';
import '../../domain/gateways/google_sign_in_launch_gateway.dart';
import '../../domain/usecases/prewarm_google_sign_in_launch_use_case.dart';
import '../../domain/usecases/resolve_google_sign_in_launch_use_case.dart';

void _logGoogleSignInButton(String message) {
  logger.d('[GoogleSignInButton] $message');
}

sealed class LoginGoogleSignInAttempt {
  const LoginGoogleSignInAttempt();
}

/// Credential Manager pre-flight passed; caller should dispatch sign-in.
final class LoginGoogleSignInAllowed extends LoginGoogleSignInAttempt {
  const LoginGoogleSignInAllowed({required this.manual});
  final bool manual;
}

/// Launch blocked by readiness or platform error; show feedback in UI.
final class LoginGoogleSignInRejected extends LoginGoogleSignInAttempt {
  const LoginGoogleSignInRejected(this.readiness);
  final GoogleSignInLaunchReadiness readiness;
}

class LoginGoogleSignInState extends Equatable {
  const LoginGoogleSignInState({
    this.isLaunchPending = false,
    this.awaitingManualResult = false,
  });

  final bool isLaunchPending;
  final bool awaitingManualResult;

  LoginGoogleSignInState copyWith({
    bool? isLaunchPending,
    bool? awaitingManualResult,
  }) {
    return LoginGoogleSignInState(
      isLaunchPending: isLaunchPending ?? this.isLaunchPending,
      awaitingManualResult: awaitingManualResult ?? this.awaitingManualResult,
    );
  }

  @override
  List<Object?> get props => [isLaunchPending, awaitingManualResult];
}

/// Login-screen Google sign-in prewarm, readiness cache, and launch gating.
@injectable
class LoginGoogleSignInCubit extends Cubit<LoginGoogleSignInState> {
  LoginGoogleSignInCubit(
    this._prewarmLaunch,
    this._resolveLaunch,
  ) : super(const LoginGoogleSignInState());

  final PrewarmGoogleSignInLaunchUseCase _prewarmLaunch;
  final ResolveGoogleSignInLaunchUseCase _resolveLaunch;

  Future<void> prewarm({GoogleSignInLaunchGateway? gateway}) {
    _logGoogleSignInButton('prewarmGoogleSignIn starting');
    return _prewarmLaunch(gateway: gateway);
  }

  /// Returns null when a launch is already pending.
  Future<LoginGoogleSignInAttempt?> attemptLaunch({
    required GoogleSignInLaunchTrigger trigger,
    GoogleSignInLaunchGateway? gateway,
  }) async {
    if (state.isLaunchPending) {
      _logGoogleSignInButton(
        'launchInteractiveSignIn skipped: already pending',
      );
      return null;
    }

    emit(state.copyWith(isLaunchPending: true));

    try {
      final GoogleSignInLaunchReadiness readiness = await _resolveLaunch(
        trigger: trigger,
        gateway: gateway,
      );

      if (readiness is! GoogleSignInLaunchReady) {
        emit(state.copyWith(isLaunchPending: false));
        return LoginGoogleSignInRejected(readiness);
      }

      final bool manual = trigger == GoogleSignInLaunchTrigger.manual;
      emit(
        state.copyWith(
          isLaunchPending: true,
          awaitingManualResult: manual,
        ),
      );
      return LoginGoogleSignInAllowed(manual: manual);
    } catch (error, stackTrace) {
      emit(state.copyWith(isLaunchPending: false));
      logger.w(
        '[GoogleSignInButton] attemptLaunch failed trigger=$trigger',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  void clearLaunchPending() {
    if (!state.isLaunchPending) {
      return;
    }
    emit(state.copyWith(isLaunchPending: false));
  }

  void onAuthenticated() {
    emit(const LoginGoogleSignInState());
  }

  void onTerminalAuthState() {
    emit(state.copyWith(isLaunchPending: false, awaitingManualResult: false));
  }

  void onManualSignInCancelled() {
    if (!state.awaitingManualResult) {
      return;
    }
    _logGoogleSignInButton(
      'manual sign-in cancelled (invisible picker / back)',
    );
    emit(state.copyWith(awaitingManualResult: false));
  }
}
