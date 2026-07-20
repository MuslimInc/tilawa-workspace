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
  Future<AuthResult> signInWithApple() async => const AuthResult.cancelled();

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

class FakePrepareGoogleSignInUseCase extends PrepareGoogleSignInUseCase {
  FakePrepareGoogleSignInUseCase() : super(_FakeAuthRepository());

  int prepareCalls = 0;
  Object? throwOnCall;

  @override
  Future<void> call() async {
    prepareCalls++;
    if (throwOnCall != null) {
      throw throwOnCall!;
    }
  }
}

class FakeGoogleSignInLaunchGateway implements GoogleSignInLaunchGateway {
  FakeGoogleSignInLaunchGateway({
    this.readiness = const GoogleSignInLaunchReadiness.ready(),
  });

  GoogleSignInLaunchReadiness readiness;
  int readinessCalls = 0;
  int settledCalls = 0;

  @override
  Future<GoogleSignInLaunchReadiness> checkReadiness() async {
    readinessCalls++;
    return readiness;
  }

  @override
  Future<void> runAfterUiSettled(Future<void> Function() action) async {
    settledCalls++;
    await action();
  }
}

void main() {
  late FakePrepareGoogleSignInUseCase prepare;
  late GoogleSignInLaunchReadinessStore store;
  late PrewarmGoogleSignInLaunchUseCase prewarm;
  late ResolveGoogleSignInLaunchUseCase resolve;

  setUp(() {
    prepare = FakePrepareGoogleSignInUseCase();
    store = GoogleSignInLaunchReadinessStore();
    prewarm = PrewarmGoogleSignInLaunchUseCase(prepare, store);
    resolve = ResolveGoogleSignInLaunchUseCase(store);
  });

  group('GoogleSignInLaunchReadinessStore', () {
    test('returns null until cached', () {
      check(store.cached).isNull();
    });

    test('clear removes cached readiness', () {
      store.cache(const GoogleSignInLaunchReadiness.ready());
      store.clear();

      check(store.cached).isNull();
    });
  });

  group('PrewarmGoogleSignInLaunchUseCase', () {
    test('prepares SDK and caches readiness when gateway present', () async {
      final FakeGoogleSignInLaunchGateway gateway =
          FakeGoogleSignInLaunchGateway(
            readiness: const GoogleSignInLaunchUiUnavailable(),
          );

      await prewarm(gateway: gateway);

      check(prepare.prepareCalls).equals(1);
      check(gateway.readinessCalls).equals(1);
      check(store.cached).isA<GoogleSignInLaunchUiUnavailable>();
    });

    test('prepares SDK without gateway', () async {
      await prewarm();

      check(prepare.prepareCalls).equals(1);
      check(store.cached).isNull();
    });

    test('continues when prepare throws', () async {
      prepare.throwOnCall = StateError('init failed');
      final FakeGoogleSignInLaunchGateway gateway =
          FakeGoogleSignInLaunchGateway();

      await prewarm(gateway: gateway);

      check(gateway.readinessCalls).equals(1);
      check(store.cached).isA<GoogleSignInLaunchReady>();
    });

    test('continues when readiness check throws', () async {
      final _ThrowingReadinessGateway gateway = _ThrowingReadinessGateway();

      await prewarm(gateway: gateway);

      check(prepare.prepareCalls).equals(1);
      check(store.cached).isNull();
    });
  });

  group('ResolveGoogleSignInLaunchUseCase', () {
    test('returns ready when gateway is null', () async {
      final GoogleSignInLaunchReadiness result = await resolve(
        trigger: GoogleSignInLaunchTrigger.manual,
      );

      check(result).isA<GoogleSignInLaunchReady>();
    });

    test('manual launch checks gateway when cache is empty', () async {
      final FakeGoogleSignInLaunchGateway gateway =
          FakeGoogleSignInLaunchGateway(
            readiness: const GoogleSignInLaunchUiUnavailable(),
          );

      final GoogleSignInLaunchReadiness result = await resolve(
        trigger: GoogleSignInLaunchTrigger.manual,
        gateway: gateway,
      );

      check(result).isA<GoogleSignInLaunchUiUnavailable>();
      check(gateway.readinessCalls).equals(1);
    });

    test('manual launch uses cached readiness without rechecking', () async {
      store.cache(const GoogleSignInLaunchReadiness.uiUnavailable());
      final FakeGoogleSignInLaunchGateway gateway =
          FakeGoogleSignInLaunchGateway();

      final GoogleSignInLaunchReadiness result = await resolve(
        trigger: GoogleSignInLaunchTrigger.manual,
        gateway: gateway,
      );

      check(result).isA<GoogleSignInLaunchUiUnavailable>();
      check(gateway.readinessCalls).equals(0);
    });

    test('auto launch defers through gateway UI settle', () async {
      final FakeGoogleSignInLaunchGateway gateway =
          FakeGoogleSignInLaunchGateway(
            readiness: const GoogleSignInLaunchPlatformError(
              code: 'blocked',
            ),
          );

      final GoogleSignInLaunchReadiness result = await resolve(
        trigger: GoogleSignInLaunchTrigger.auto,
        gateway: gateway,
      );

      check(gateway.settledCalls).equals(1);
      check(result).isA<GoogleSignInLaunchPlatformError>();
    });

    test('auto launch returns ready when settle skips action', () async {
      final _NoOpSettleGateway gateway = _NoOpSettleGateway();

      final GoogleSignInLaunchReadiness result = await resolve(
        trigger: GoogleSignInLaunchTrigger.auto,
        gateway: gateway,
      );

      check(result).isA<GoogleSignInLaunchReady>();
    });
  });
}

class _ThrowingReadinessGateway implements GoogleSignInLaunchGateway {
  @override
  Future<GoogleSignInLaunchReadiness> checkReadiness() async {
    throw StateError('readiness failed');
  }

  @override
  Future<void> runAfterUiSettled(Future<void> Function() action) async {
    await action();
  }
}

class _NoOpSettleGateway implements GoogleSignInLaunchGateway {
  @override
  Future<GoogleSignInLaunchReadiness> checkReadiness() async {
    return const GoogleSignInLaunchReadiness.uiUnavailable();
  }

  @override
  Future<void> runAfterUiSettled(Future<void> Function() action) async {}
}
