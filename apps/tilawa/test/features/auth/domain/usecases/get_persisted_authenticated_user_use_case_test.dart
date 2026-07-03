import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:tilawa/features/auth/domain/usecases/get_persisted_authenticated_user_use_case.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';

void main() {
  late GetPersistedAuthenticatedUserUseCase useCase;

  setUpAll(() async {
    await initializeHydratedStorageForTest();
  });

  tearDownAll(() async {
    await clearHydratedStorageForTest();
  });

  setUp(() {
    useCase = GetPersistedAuthenticatedUserUseCase();
  });

  tearDown(() async {
    await HydratedBloc.storage.clear();
  });

  test('returns null when no persisted auth session exists', () async {
    expect(await useCase(), isNull);
  });

  test(
    'returns authenticated user from persisted AuthBloc hydration',
    () async {
      await HydratedBloc.storage.write(
        GetPersistedAuthenticatedUserUseCase.storageKey,
        <String, dynamic>{
          'state': 'authenticated',
          'user': <String, dynamic>{
            'id': 'user-1',
            'email': 'test@example.com',
            'displayName': 'Test User',
            'photoUrl': null,
            'createdAt': '2024-01-01T00:00:00.000Z',
          },
        },
      );

      final user = await useCase();

      expect(user, isNotNull);
      expect(user!.id, 'user-1');
      expect(user.email, 'test@example.com');
    },
  );
}
