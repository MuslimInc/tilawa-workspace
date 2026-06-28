import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  test('returns verificationUnknown when local cache read fails', () async {
    when(() => mockCache.getSessionEpoch()).thenThrow(Exception('cache down'));

    final result = await useCase('user_1');

    result.fold((_) => fail('expected Right'), (validity) {
      expect(validity, SessionValidityResult.verificationUnknown);
    });
  });
}
