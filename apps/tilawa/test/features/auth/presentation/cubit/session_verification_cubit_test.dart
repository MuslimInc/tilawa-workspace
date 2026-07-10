import 'dart:async';

import 'package:checks/checks.dart';
import 'package:fake_async/fake_async.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/presentation/cubit/session_verification_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  final tUser = UserEntity(
    id: 'user_1',
    email: 'user@example.com',
    displayName: 'User',
    createdAt: DateTime.utc(2024),
  );

  const bannerThreshold = Duration(seconds: 4);
  const verifyingCap = Duration(seconds: 45);

  late MockAuthRepository repo;
  late StreamController<UserEntity?> authController;

  setUp(() {
    repo = MockAuthRepository();
    authController = StreamController<UserEntity?>.broadcast();
    when(() => repo.authStateChanges).thenAnswer((_) => authController.stream);
  });

  tearDown(() => authController.close());

  SessionVerificationCubit build({bool enabled = true}) {
    return SessionVerificationCubit(
      repo,
      hardeningEnabled: () => enabled,
      bannerThreshold: bannerThreshold,
      verifyingCap: verifyingCap,
    );
  }

  test('starts verified with no banner', () {
    final cubit = build();
    check(cubit.state.status).equals(SessionVerificationStatus.verified);
    check(cubit.state.showBanner).isFalse();
    cubit.close();
  });

  test('a null before any user (plain logged-out) does not verify', () {
    fakeAsync((async) {
      final cubit = build();
      authController.add(null);
      async.flushMicrotasks();
      check(cubit.state.isVerifying).isFalse();
      cubit.close();
    });
  });

  test('transient drop enters verifying but stays silent under threshold', () {
    fakeAsync((async) {
      final cubit = build();
      authController.add(tUser); // signed in
      async.flushMicrotasks();

      authController.add(null); // transient drop
      async.flushMicrotasks();
      check(cubit.state.isVerifying).isTrue();
      check(cubit.state.showBanner).isFalse();

      async.elapse(const Duration(seconds: 2)); // still under threshold
      check(cubit.state.showBanner).isFalse();
      cubit.close();
    });
  });

  test('quick recovery clears verifying without ever showing the banner', () {
    fakeAsync((async) {
      final cubit = build();
      authController.add(tUser);
      async.flushMicrotasks();
      authController.add(null);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 2));

      authController.add(tUser); // recovered before threshold
      async.flushMicrotasks();

      check(cubit.state.status).equals(SessionVerificationStatus.verified);
      check(cubit.state.showBanner).isFalse();

      async.elapse(bannerThreshold); // banner timer must not fire
      check(cubit.state.showBanner).isFalse();
      cubit.close();
    });
  });

  test('slow verification shows the banner past the threshold', () {
    fakeAsync((async) {
      final cubit = build();
      authController.add(tUser);
      async.flushMicrotasks();
      authController.add(null);
      async.flushMicrotasks();

      async.elapse(bannerThreshold + const Duration(milliseconds: 1));
      check(cubit.state.isVerifying).isTrue();
      check(cubit.state.showBanner).isTrue();
      cubit.close();
    });
  });

  test('banner clears when the session recovers after being shown', () {
    fakeAsync((async) {
      final cubit = build();
      authController.add(tUser);
      async.flushMicrotasks();
      authController.add(null);
      async.flushMicrotasks();
      async.elapse(bannerThreshold + const Duration(seconds: 1));
      check(cubit.state.showBanner).isTrue();

      authController.add(tUser);
      async.flushMicrotasks();
      check(cubit.state.status).equals(SessionVerificationStatus.verified);
      check(cubit.state.showBanner).isFalse();
      cubit.close();
    });
  });

  test('gives up quietly after the cap without forcing a logout', () {
    fakeAsync((async) {
      final cubit = build();
      authController.add(tUser);
      async.flushMicrotasks();
      authController.add(null);
      async.flushMicrotasks();

      async.elapse(verifyingCap + const Duration(seconds: 1));
      // Never signs out; just stops nagging.
      check(cubit.state.status).equals(SessionVerificationStatus.verified);
      check(cubit.state.showBanner).isFalse();
      cubit.close();
    });
  });

  test('does nothing when hardening flag is disabled', () {
    fakeAsync((async) {
      final cubit = build(enabled: false);
      authController.add(tUser);
      async.flushMicrotasks();
      authController.add(null);
      async.flushMicrotasks();
      async.elapse(bannerThreshold + const Duration(seconds: 1));

      check(cubit.state.isVerifying).isFalse();
      check(cubit.state.showBanner).isFalse();
      cubit.close();
    });
  });

  test('noteSessionEnded suppresses verifying on the following null', () {
    fakeAsync((async) {
      final cubit = build();
      authController.add(tUser);
      async.flushMicrotasks();

      cubit.noteSessionEnded(); // intentional sign-out
      authController.add(null);
      async.flushMicrotasks();
      async.elapse(bannerThreshold + const Duration(seconds: 1));

      check(cubit.state.isVerifying).isFalse();
      check(cubit.state.showBanner).isFalse();
      cubit.close();
    });
  });
}
