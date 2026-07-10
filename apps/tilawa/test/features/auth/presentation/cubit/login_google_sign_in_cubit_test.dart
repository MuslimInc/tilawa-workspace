import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/google_sign_in_launch_readiness.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/gateways/google_sign_in_launch_gateway.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/services/google_sign_in_launch_readiness_store.dart';
import 'package:tilawa/features/auth/domain/usecases/prewarm_google_sign_in_launch_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/prepare_google_sign_in_use_case.dart';
import 'package:tilawa/features/auth/domain/usecases/resolve_google_sign_in_launch_use_case.dart';
import 'package:tilawa/features/auth/presentation/cubit/login_google_sign_in_cubit.dart';

import '../../../../support/fake_network_info.dart';

class _FakeAuthRepository implements AuthRepository {
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
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => const AuthResult.failure(message: 'not-implemented');

  @override
  Future<AuthResult> registerWithEmailPassword({
    required String email,
    required String password,
  }) async => const AuthResult.failure(message: 'not-implemented');

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> hasAdminClaim() async => false;
}

class FakeGoogleSignInLaunchGateway implements GoogleSignInLaunchGateway {
  FakeGoogleSignInLaunchGateway({
    this.readiness = const GoogleSignInLaunchReadiness.ready(),
  });

  GoogleSignInLaunchReadiness readiness;
  int readinessChecks = 0;

  @override
  Future<GoogleSignInLaunchReadiness> checkReadiness() async {
    readinessChecks++;
    return readiness;
  }

  @override
  Future<void> runAfterUiSettled(Future<void> Function() action) async {
    await action();
  }
}

class _ThrowingReadinessGateway implements GoogleSignInLaunchGateway {
  @override
  Future<GoogleSignInLaunchReadiness> checkReadiness() async {
    throw StateError('resolve failed');
  }

  @override
  Future<void> runAfterUiSettled(Future<void> Function() action) async {
    throw StateError('resolve failed');
  }
}

void main() {
  late GoogleSignInLaunchReadinessStore store;
  late LoginGoogleSignInCubit cubit;
  late FakeGoogleSignInLaunchGateway gateway;
  late FakeNetworkInfo networkInfo;

  setUp(() {
    store = GoogleSignInLaunchReadinessStore();
    gateway = FakeGoogleSignInLaunchGateway();
    networkInfo = FakeNetworkInfo();
    cubit = LoginGoogleSignInCubit(
      PrewarmGoogleSignInLaunchUseCase(
        PrepareGoogleSignInUseCase(_FakeAuthRepository()),
        store,
      ),
      ResolveGoogleSignInLaunchUseCase(store),
      ServerActionGuard(networkInfo),
    );
  });

  tearDown(() async {
    await cubit.close();
    await networkInfo.dispose();
  });

  test('prewarm caches readiness from gateway', () async {
    gateway.readiness = const GoogleSignInLaunchUiUnavailable();

    await cubit.prewarm(gateway: gateway);

    check(store.cached).isA<GoogleSignInLaunchUiUnavailable>();
  });

  test('manual launch allows sign-in when readiness is ready', () async {
    await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: gateway,
    );

    check(cubit.state.launchAttempt).isA<LoginGoogleSignInAllowed>();
    check(cubit.state.isLaunchPending).isTrue();
    check(cubit.state.awaitingManualResult).isTrue();
  });

  test('manual launch rejects when readiness is blocked', () async {
    gateway.readiness = const GoogleSignInLaunchReadiness.uiUnavailable();

    await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: gateway,
    );

    check(cubit.state.launchAttempt).isA<LoginGoogleSignInRejected>();
    check(cubit.state.isLaunchPending).isFalse();
  });

  test('manual launch blocks offline before readiness check', () async {
    networkInfo.connected = false;

    await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: gateway,
    );

    check(cubit.state.launchAttempt).isA<LoginGoogleSignInBlocked>();
    check(cubit.state.isLaunchPending).isFalse();
    check(gateway.readinessChecks).equals(0);
  });

  test('rapid offline launch taps share one guard check', () async {
    networkInfo
      ..connected = false
      ..delay = const Duration(milliseconds: 20);

    await Future.wait([
      cubit.attemptLaunch(
        trigger: GoogleSignInLaunchTrigger.manual,
        gateway: gateway,
      ),
      cubit.attemptLaunch(
        trigger: GoogleSignInLaunchTrigger.manual,
        gateway: gateway,
      ),
    ]);

    check(networkInfo.isConnectedCalls).equals(1);
    check(gateway.readinessChecks).equals(0);
  });

  test('auto launch allows sign-in without awaiting manual result', () async {
    await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.auto,
      gateway: gateway,
    );

    final attempt = cubit.state.launchAttempt;
    check(attempt).isA<LoginGoogleSignInAllowed>();
    check((attempt! as LoginGoogleSignInAllowed).manual).isFalse();
    check(cubit.state.awaitingManualResult).isFalse();
  });

  test('attemptLaunch leaves launchAttempt null when resolve throws', () async {
    await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: _ThrowingReadinessGateway(),
    );

    check(cubit.state.launchAttempt).isNull();
    check(cubit.state.isLaunchPending).isFalse();
  });

  test('second launch is ignored while pending', () async {
    await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: gateway,
    );
    final firstAttempt = cubit.state.launchAttempt;

    await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: gateway,
    );

    check(cubit.state.launchAttempt).equals(firstAttempt);
  });

  test('clearLaunchPending clears pending flag', () async {
    await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: gateway,
    );

    cubit.clearLaunchPending();

    check(cubit.state.isLaunchPending).isFalse();
  });

  test('clearLaunchPending is a no-op when idle', () {
    cubit.clearLaunchPending();

    check(cubit.state.isLaunchPending).isFalse();
  });

  test('clearLaunchAttempt clears launchAttempt', () async {
    await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: gateway,
    );

    cubit.clearLaunchAttempt();

    check(cubit.state.launchAttempt).isNull();
  });

  test('onAuthenticated resets launch state', () async {
    await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: gateway,
    );

    cubit.onAuthenticated();

    check(cubit.state.isLaunchPending).isFalse();
    check(cubit.state.awaitingManualResult).isFalse();
  });

  test('onTerminalAuthState clears pending flags', () async {
    await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: gateway,
    );

    cubit.onTerminalAuthState();

    check(cubit.state.isLaunchPending).isFalse();
    check(cubit.state.awaitingManualResult).isFalse();
  });

  test('onManualSignInCancelled clears awaiting manual result', () async {
    await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: gateway,
    );

    cubit.onManualSignInCancelled();

    check(cubit.state.awaitingManualResult).isFalse();
    check(cubit.state.isLaunchPending).isTrue();
  });

  test('onManualSignInCancelled is a no-op when not awaiting manual', () {
    cubit.onManualSignInCancelled();

    check(cubit.state.awaitingManualResult).isFalse();
  });
}
