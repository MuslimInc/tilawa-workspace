import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/auth/domain/usecases/prepare_google_sign_in_use_case.dart';

import 'prepare_google_sign_in_use_case_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late PrepareGoogleSignInUseCase useCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = PrepareGoogleSignInUseCase(mockAuthRepository);
    when(mockAuthRepository.prepareGoogleSignIn()).thenAnswer((_) async {
      return;
    });
  });

  test('call delegates to AuthRepository.prepareGoogleSignIn', () async {
    await useCase();

    verify(mockAuthRepository.prepareGoogleSignIn()).called(1);
  });
}
