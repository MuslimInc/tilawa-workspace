import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../core/domain/server_action_guard.dart';
import '../entities/email_auth_failure_key.dart';
import '../gateways/email_password_auth_gateway.dart';

@injectable
class SendPasswordResetEmailUseCase {
  SendPasswordResetEmailUseCase(
    this._emailPasswordAuth,
    this._serverActionGuard,
  );

  final EmailPasswordAuthGateway _emailPasswordAuth;
  final ServerActionGuard _serverActionGuard;

  Future<Either<Failure, void>> call({required String email}) async {
    final guardResult = await _serverActionGuard.ensureCanRun(
      ServerActionType.googleSignIn,
    );
    final Failure? blockedFailure = guardResult.fold(
      (failure) => failure,
      (_) => null,
    );
    if (blockedFailure != null) {
      return Left(blockedFailure);
    }

    final Either<Failure, void> result = await _emailPasswordAuth
        .sendPasswordResetEmail(email: email);
    return result.fold(
      (Failure failure) {
        final String? message = failure.message;
        if (message == EmailAuthFailureKey.userNotFound) {
          return const Right(null);
        }
        return Left(failure);
      },
      (_) => const Right(null),
    );
  }
}
