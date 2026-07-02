import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/auth/domain/entities/session_validity_result.dart';
import 'package:tilawa/features/auth/domain/services/token_sync_cache.dart';
import 'package:tilawa/features/auth/domain/usecases/check_session_validity_use_case.dart';

class MockTokenSyncCache extends Mock implements TokenSyncCache {}

void main() {
  late CheckSessionValidityUseCase useCase;
  late FakeFirebaseFirestore fakeFirestore;
  late MockTokenSyncCache mockCache;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockCache = MockTokenSyncCache();
    useCase = CheckSessionValidityUseCase(fakeFirestore, mockCache);
  });

  test(
    'returns valid when local epoch and active device match server',
    () async {
      when(() => mockCache.getSessionEpoch()).thenAnswer((_) async => 3);
      when(
        () => mockCache.getActiveDeviceId(),
      ).thenAnswer((_) async => 'device_1');
      await fakeFirestore.collection('users').doc('user_1').set({
        'session': {'epoch': 3, 'activeDeviceId': 'device_1'},
      });

      final result = await useCase('user_1');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (validity) {
        expect(validity, SessionValidityResult.valid);
      });
    },
  );

  test('returns stale when local epoch is stale', () async {
    when(() => mockCache.getSessionEpoch()).thenAnswer((_) async => 1);
    when(
      () => mockCache.getActiveDeviceId(),
    ).thenAnswer((_) async => 'device_1');
    await fakeFirestore.collection('users').doc('user_1').set({
      'session': {'epoch': 4, 'activeDeviceId': 'device_1'},
    });

    final result = await useCase('user_1');

    result.fold((_) => fail('expected Right'), (validity) {
      expect(validity, SessionValidityResult.stale);
    });
  });

  test('returns stale when active device differs', () async {
    when(() => mockCache.getSessionEpoch()).thenAnswer((_) async => 4);
    when(
      () => mockCache.getActiveDeviceId(),
    ).thenAnswer((_) async => 'device_1');
    await fakeFirestore.collection('users').doc('user_1').set({
      'session': {'epoch': 4, 'activeDeviceId': 'device_2'},
    });

    final result = await useCase('user_1');

    result.fold((_) => fail('expected Right'), (validity) {
      expect(validity, SessionValidityResult.stale);
    });
  });

  test(
    'returns verificationUnknown when the network is unavailable '
    '(FirebaseException unavailable)',
    () async {
      when(() => mockCache.getSessionEpoch()).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
          message: 'The service is currently unavailable.',
        ),
      );

      final result = await useCase('user_1');

      result.fold((_) => fail('expected Right'), (validity) {
        expect(validity, SessionValidityResult.verificationUnknown);
      });
    },
  );

  test(
    'returns verificationUnknown for raw connectivity errors',
    () async {
      when(() => mockCache.getSessionEpoch()).thenThrow(
        Exception(
          'SocketException: Failed host lookup: firestore.googleapis.com',
        ),
      );

      final result = await useCase('user_1');

      result.fold((_) => fail('expected Right'), (validity) {
        expect(validity, SessionValidityResult.verificationUnknown);
      });
    },
  );

  test(
    'returns a typed ServerFailure for non-network Firestore errors '
    'instead of silently reporting verificationUnknown',
    () async {
      when(() => mockCache.getSessionEpoch()).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Missing or insufficient permissions.',
        ),
      );

      final result = await useCase('user_1');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('permission-denied'));
        },
        (_) => fail('expected Left'),
      );
    },
  );

  test(
    'returns a typed UnexpectedFailure for unknown errors '
    'instead of a silent catch-all',
    () async {
      when(() => mockCache.getSessionEpoch()).thenThrow(
        StateError('schema drift'),
      );

      final result = await useCase('user_1');

      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (_) => fail('expected Left'),
      );
    },
  );
}
