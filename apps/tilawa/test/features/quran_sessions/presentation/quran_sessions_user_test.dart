import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_sessions/data/fake_auth_session_provider.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_user.dart';

void main() {
  tearDown(() {
    if (getIt.isRegistered<AuthSessionProvider>()) {
      getIt.unregister<AuthSessionProvider>();
    }
  });

  group('resolveQuranSessionsUserId', () {
    test('returns null when user id is empty', () {
      getIt.registerSingleton<AuthSessionProvider>(
        const FakeAuthSessionProvider(userId: ''),
      );

      expect(resolveQuranSessionsUserId(getIt), isNull);
    });

    test('returns null when user id is absent', () {
      getIt.registerSingleton<AuthSessionProvider>(
        const FakeAuthSessionProvider(userId: ''),
      );

      expect(quranSessionsCurrentUserId(getIt), '');
      expect(resolveQuranSessionsUserId(getIt), isNull);
    });

    test('returns uid when signed in', () {
      getIt.registerSingleton<AuthSessionProvider>(
        const FakeAuthSessionProvider(userId: 'student_1'),
      );

      expect(resolveQuranSessionsUserId(getIt), 'student_1');
    });

    test('never throws for missing auth', () {
      getIt.registerSingleton<AuthSessionProvider>(
        const FakeAuthSessionProvider(userId: ''),
      );

      expect(() => resolveQuranSessionsUserId(getIt), returnsNormally);
    });
  });
}
