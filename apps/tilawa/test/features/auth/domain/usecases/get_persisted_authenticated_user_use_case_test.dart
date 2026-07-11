import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/auth/domain/services/token_sync_cache.dart';
import 'package:tilawa/features/auth/domain/usecases/get_persisted_authenticated_user_use_case.dart';

class MockTokenSyncCache extends Mock implements TokenSyncCache {}

void main() {
  late MockTokenSyncCache tokenSyncCache;
  late GetPersistedAuthenticatedUserUseCase useCase;

  setUp(() {
    tokenSyncCache = MockTokenSyncCache();
    useCase = GetPersistedAuthenticatedUserUseCase(tokenSyncCache);
  });

  test('returns null when no user id was ever persisted', () async {
    when(() => tokenSyncCache.getLastSyncedUserId()).thenAnswer(
      (_) async => null,
    );

    expect(await useCase(), isNull);
  });

  test('returns null when the persisted user id is empty', () async {
    when(() => tokenSyncCache.getLastSyncedUserId()).thenAnswer(
      (_) async => '',
    );

    expect(await useCase(), isNull);
  });

  test('returns an id-only hint when a user id is persisted', () async {
    when(() => tokenSyncCache.getLastSyncedUserId()).thenAnswer(
      (_) async => 'uid-123',
    );

    final hint = await useCase();

    expect(hint, isNotNull);
    expect(hint!.id, 'uid-123');
  });
}
