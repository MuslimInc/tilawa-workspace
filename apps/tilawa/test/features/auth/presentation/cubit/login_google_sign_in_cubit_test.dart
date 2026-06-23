import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
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
  Future<void> signOut() async {}
}

class FakeGoogleSignInLaunchGateway implements GoogleSignInLaunchGateway {
  FakeGoogleSignInLaunchGateway({
    this.readiness = const GoogleSignInLaunchReadiness.ready(),
  });

  GoogleSignInLaunchReadiness readiness;

  @override
  Future<GoogleSignInLaunchReadiness> checkReadiness() async => readiness;

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

  setUp(() {
    store = GoogleSignInLaunchReadinessStore();
    gateway = FakeGoogleSignInLaunchGateway();
    cubit = LoginGoogleSignInCubit(
      PrewarmGoogleSignInLaunchUseCase(
        PrepareGoogleSignInUseCase(_FakeAuthRepository()),
        store,
      ),
      ResolveGoogleSignInLaunchUseCase(store),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  test('prewarm caches readiness from gateway', () async {
    gateway.readiness = const GoogleSignInLaunchUiUnavailable();

    await cubit.prewarm(gateway: gateway);

    check(store.cached).isA<GoogleSignInLaunchUiUnavailable>();
  });

  test('manual launch allows sign-in when readiness is ready', () async {
    final LoginGoogleSignInAttempt? attempt = await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: gateway,
    );

    check(attempt).isA<LoginGoogleSignInAllowed>();
    check(cubit.state.isLaunchPending).isTrue();
    check(cubit.state.awaitingManualResult).isTrue();
  });

  test('manual launch rejects when readiness is blocked', () async {
    gateway.readiness = const GoogleSignInLaunchReadiness.uiUnavailable();

    final LoginGoogleSignInAttempt? attempt = await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: gateway,
    );

    check(attempt).isA<LoginGoogleSignInRejected>();
    check(cubit.state.isLaunchPending).isFalse();
  });

  test('auto launch allows sign-in without awaiting manual result', () async {
    final LoginGoogleSignInAttempt? attempt = await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.auto,
      gateway: gateway,
    );

    check(attempt).isA<LoginGoogleSignInAllowed>();
    check((attempt! as LoginGoogleSignInAllowed).manual).isFalse();
    check(cubit.state.awaitingManualResult).isFalse();
  });

  test('attemptLaunch returns null when resolve throws', () async {
    final LoginGoogleSignInAttempt? attempt = await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: _ThrowingReadinessGateway(),
    );

    check(attempt).isNull();
    check(cubit.state.isLaunchPending).isFalse();
  });

  test('second launch is ignored while pending', () async {
    await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: gateway,
    );

    final LoginGoogleSignInAttempt? second = await cubit.attemptLaunch(
      trigger: GoogleSignInLaunchTrigger.manual,
      gateway: gateway,
    );

    check(second).isNull();
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
