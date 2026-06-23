import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  test('returns true when local epoch matches server', () async {
    when(() => mockCache.getSessionEpoch()).thenAnswer((_) async => 3);
    await fakeFirestore.collection('users').doc('user_1').set({
      'session': {'epoch': 3},
    });

    final result = await useCase('user_1');

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected Right'), (isValid) {
      expect(isValid, isTrue);
    });
  });

  test('returns false when local epoch is stale', () async {
    when(() => mockCache.getSessionEpoch()).thenAnswer((_) async => 1);
    await fakeFirestore.collection('users').doc('user_1').set({
      'session': {'epoch': 4},
    });

    final result = await useCase('user_1');

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected Right'), (isValid) {
      expect(isValid, isFalse);
    });
  });
}
