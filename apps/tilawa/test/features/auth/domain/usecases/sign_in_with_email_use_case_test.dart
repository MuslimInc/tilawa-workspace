import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/usecases/sign_in_with_email_use_case.dart';

import '../../helpers/auth_mock_helper.mocks.dart';
import '../../../../support/fake_network_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SignInWithEmailUseCase useCase;
  late MockAuthRepository mockAuthRepository;
  late MockUserRepository mockUserRepository;
  late FakeNetworkInfo networkInfo;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUserRepository = MockUserRepository();
    networkInfo = FakeNetworkInfo();
    useCase = SignInWithEmailUseCase(
      mockAuthRepository,
      mockUserRepository,
      ServerActionGuard(networkInfo),
    );
  });

  tearDown(() async {
    await networkInfo.dispose();
  });

  final tUser = UserEntity(
    id: '123',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime.now(),
  );

  test('returns success and saves profile when sign-in succeeds', () async {
    when(
      mockAuthRepository.signInWithEmailPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ),
    ).thenAnswer((_) async => AuthResult.success(user: tUser));
    when(mockUserRepository.saveUserData(any)).thenAnswer((_) async {});

    final AuthResult result = await useCase(
      email: 'test@example.com',
      password: 'secret1',
    );

    expect(result, AuthResult.success(user: tUser));
    verify(
      mockAuthRepository.signInWithEmailPassword(
        email: 'test@example.com',
        password: 'secret1',
      ),
    ).called(1);
  });

  test('returns typed failure when offline', () async {
    networkInfo.connected = false;

    final AuthResult result = await useCase(
      email: 'test@example.com',
      password: 'secret1',
    );

    expect(result, isA<AuthFailure>());
    verifyNever(
      mockAuthRepository.signInWithEmailPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ),
    );
  });
}
