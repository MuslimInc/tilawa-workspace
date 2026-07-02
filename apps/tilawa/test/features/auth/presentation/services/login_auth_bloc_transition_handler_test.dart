import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/features/auth/domain/entities/auth_error_key.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/services/google_sign_in_launch_readiness_store.dart';
import 'package:tilawa/features/auth/domain/usecases/prewarm_google_sign_in_launch_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/prepare_google_sign_in_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/resolve_google_sign_in_launch_use_case.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/auth/presentation/cubit/login_google_sign_in_cubit.dart';
import 'package:tilawa/features/auth/presentation/services/login_auth_bloc_transition_handler.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../support/fake_network_info.dart';

class _NoopAuthRepository implements AuthRepository {
  @override
  Stream<UserEntity?> get authStateChanges => const Stream.empty();

  @override
  UserEntity? get currentUser => null;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> prepareGoogleSignIn() async {}

  @override
  Future<AuthResult> signInWithGoogle() async => const AuthResult.cancelled();

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> hasAdminClaim() async => false;
}

void main() {
  final UserEntity user = UserEntity(
    id: '1',
    email: 'a@b.com',
    displayName: 'User',
    createdAt: DateTime.utc(2024),
  );

  late LoginGoogleSignInCubit cubit;
  late FakeNetworkInfo networkInfo;
  final List<String> logs = <String>[];
  int navigateCount = 0;
  final List<(String message, TilawaFeedbackVariant variant)> toasts =
      <(String, TilawaFeedbackVariant)>[];

  const LoginAuthBlocTransitionMessages messages =
      LoginAuthBlocTransitionMessages(
        authErrorFallback: 'fallback',
        noGoogleAccounts: 'no accounts',
        serverActionOffline: 'offline action blocked',
      );

  setUp(() {
    final GoogleSignInLaunchReadinessStore store =
        GoogleSignInLaunchReadinessStore();
    networkInfo = FakeNetworkInfo();
    cubit = LoginGoogleSignInCubit(
      PrewarmGoogleSignInLaunchUseCase(
        PrepareGoogleSignInUseCase(_NoopAuthRepository()),
        store,
      ),
      ResolveGoogleSignInLaunchUseCase(store),
      ServerActionGuard(networkInfo),
    );
    logs.clear();
    navigateCount = 0;
    toasts.clear();
  });

  tearDown(() async {
    await cubit.close();
    await networkInfo.dispose();
  });

  void handle(AuthState state, {bool shouldSkipAutoSignIn = false}) {
    handleLoginAuthBlocTransition(
      state: state,
      launchCubit: cubit,
      shouldSkipAutoSignIn: shouldSkipAutoSignIn,
      messages: messages,
      onNavigateToHome: () => navigateCount++,
      showToast: (String message, TilawaFeedbackVariant variant) {
        toasts.add((message, variant));
      },
      log: logs.add,
    );
  }

  group('handleLoginAuthBlocTransition', () {
    test('authenticated clears launch state and navigates home', () {
      cubit.emit(const LoginGoogleSignInState(isLaunchPending: true));

      handle(AuthState.authenticated(user: user));

      check(cubit.state.isLaunchPending).isFalse();
      check(navigateCount).equals(1);
      check(logs.single).contains('authenticated');
    });

    test('unauthenticated clears pending launch', () {
      cubit.emit(const LoginGoogleSignInState(isLaunchPending: true));

      handle(const AuthState.unauthenticated());

      check(cubit.state.isLaunchPending).isFalse();
      check(navigateCount).equals(0);
    });

    test('unauthenticated with skip policy notifies manual cancel', () {
      cubit.emit(
        const LoginGoogleSignInState(
          isLaunchPending: true,
          awaitingManualResult: true,
        ),
      );

      handle(const AuthState.unauthenticated(), shouldSkipAutoSignIn: true);

      check(cubit.state.awaitingManualResult).isFalse();
    });

    test('error shows message toast and clears launch pending', () {
      cubit.emit(const LoginGoogleSignInState(isLaunchPending: true));

      handle(const AuthState.error(message: 'Network down'));

      check(cubit.state.isLaunchPending).isFalse();
      check(toasts.single.$1).equals('Network down');
      check(toasts.single.$2).equals(TilawaFeedbackVariant.error);
    });

    test('raw Firebase network copy maps to offline message', () {
      handle(
        const AuthState.error(
          message:
              'A network error (such as timeout, interrupted connection or '
              'unreachable host) has occurred.',
        ),
      );

      check(toasts.single.$1).equals('offline action blocked');
      check(toasts.single.$2).equals(TilawaFeedbackVariant.error);
    });

    test('error uses fallback when message empty', () {
      handle(const AuthState.error(message: ''));

      check(toasts.single.$1).equals('fallback');
    });

    test('app check key shows dedicated message', () {
      const LoginAuthBlocTransitionMessages appCheckMessages =
          LoginAuthBlocTransitionMessages(
            authErrorFallback: 'fallback',
            noGoogleAccounts: 'no accounts',
            appCheckFailed: 'app check setup hint',
          );

      handleLoginAuthBlocTransition(
        state: const AuthState.error(message: AuthErrorKey.appCheckFailed),
        launchCubit: cubit,
        shouldSkipAutoSignIn: false,
        messages: appCheckMessages,
        onNavigateToHome: () => navigateCount++,
        showToast: (String message, TilawaFeedbackVariant variant) {
          toasts.add((message, variant));
        },
      );

      check(toasts.single.$1).equals('app check setup hint');
      check(toasts.single.$2).equals(TilawaFeedbackVariant.error);
    });

    test('server action offline key shows dedicated message', () {
      handle(const AuthState.error(message: ServerActionFailureKey.offline));

      check(toasts.single.$1).equals('offline action blocked');
      check(toasts.single.$2).equals(TilawaFeedbackVariant.error);
    });

    test('raw App Check Firebase copy maps to app check message', () {
      const LoginAuthBlocTransitionMessages appCheckMessages =
          LoginAuthBlocTransitionMessages(
            authErrorFallback: 'fallback',
            noGoogleAccounts: 'no accounts',
            appCheckFailed: 'app check setup hint',
            deviceRegistrationFailed: 'registration failed',
          );

      handleLoginAuthBlocTransition(
        state: const AuthState.error(
          message: 'App Check token is invalid.',
        ),
        launchCubit: cubit,
        shouldSkipAutoSignIn: false,
        messages: appCheckMessages,
        onNavigateToHome: () => navigateCount++,
        showToast: (String message, TilawaFeedbackVariant variant) {
          toasts.add((message, variant));
        },
      );

      check(toasts.single.$1).equals('app check setup hint');
    });

    test('device registration key still uses dedicated copy', () {
      const LoginAuthBlocTransitionMessages registrationMessages =
          LoginAuthBlocTransitionMessages(
            authErrorFallback: 'fallback',
            noGoogleAccounts: 'no accounts',
            deviceRegistrationFailed: 'registration failed',
            appCheckFailed: 'app check setup hint',
          );

      handleLoginAuthBlocTransition(
        state: const AuthState.error(
          message: AuthErrorKey.deviceRegistrationFailed,
        ),
        launchCubit: cubit,
        shouldSkipAutoSignIn: false,
        messages: registrationMessages,
        onNavigateToHome: () => navigateCount++,
        showToast: (String message, TilawaFeedbackVariant variant) {
          toasts.add((message, variant));
        },
      );

      check(toasts.single.$1).equals('registration failed');
    });

    test('noGoogleAccounts shows info toast', () {
      handle(const AuthState.noGoogleAccounts());

      check(toasts.single.$1).equals('no accounts');
      check(toasts.single.$2).equals(TilawaFeedbackVariant.info);
    });

    test('initial and loading are no-ops', () {
      handle(const AuthState.initial());
      handle(const AuthState.loading());

      check(navigateCount).equals(0);
      check(toasts).isEmpty();
    });
  });
}
