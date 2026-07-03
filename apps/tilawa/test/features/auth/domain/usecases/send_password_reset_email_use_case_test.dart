import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/domain/server_action_guard.dart';
import 'package:tilawa/features/auth/domain/entities/auth_result.dart';
import 'package:tilawa/features/auth/domain/entities/email_auth_failure_key.dart';
import 'package:tilawa/features/auth/domain/gateways/email_password_auth_gateway.dart';
import 'package:tilawa/features/auth/domain/usecases/send_password_reset_email_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../support/fake_network_info.dart';

class _FakeEmailPasswordAuthGateway implements EmailPasswordAuthGateway {
  Either<Failure, void>? resetResult;

  @override
  Future<AuthResult> registerWithEmailPassword({
    required String email,
    required String password,
  }) async => const AuthResult.failure(message: 'unused');

  @override
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => const AuthResult.failure(message: 'unused');

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async => resetResult ?? const Right(null);

  @override
  Future<void> sendEmailVerification() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SendPasswordResetEmailUseCase useCase;
  late _FakeEmailPasswordAuthGateway emailGateway;
  late FakeNetworkInfo networkInfo;

  setUp(() {
    emailGateway = _FakeEmailPasswordAuthGateway();
    networkInfo = FakeNetworkInfo();
    useCase = SendPasswordResetEmailUseCase(
      emailGateway,
      ServerActionGuard(networkInfo),
    );
  });

  tearDown(() async {
    await networkInfo.dispose();
  });

  test('returns success for unknown email without enumeration', () async {
    emailGateway.resetResult = const Left(
      ValidationFailure(EmailAuthFailureKey.userNotFound),
    );

    final result = await useCase(email: 'missing@example.com');

    expect(result.isRight(), isTrue);
  });

  test('returns failure for too many requests', () async {
    emailGateway.resetResult = const Left(
      ValidationFailure(EmailAuthFailureKey.tooManyRequests),
    );

    final result = await useCase(email: 'test@example.com');

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure.message, EmailAuthFailureKey.tooManyRequests),
      (_) => fail('expected failure'),
    );
  });
}
