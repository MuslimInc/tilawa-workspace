import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/get_current_user_use_case.dart';

import '../../helpers/auth_mock_helper.mocks.dart';

void main() {
  late GetCurrentUserUseCase useCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = GetCurrentUserUseCase(mockAuthRepository);
  });

  group('GetCurrentUserUseCase', () {
    test('returns the current user when signed in', () {
      final user = UserEntity(
        id: '123',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'photo.jpg',
        createdAt: DateTime(2026),
      );
      when(mockAuthRepository.currentUser).thenReturn(user);

      final result = useCase();

      expect(result, user);
      verify(mockAuthRepository.currentUser).called(1);
    });

    test('returns null when no user is signed in', () {
      when(mockAuthRepository.currentUser).thenReturn(null);

      final result = useCase();

      expect(result, isNull);
      verify(mockAuthRepository.currentUser).called(1);
    });
  });
}
