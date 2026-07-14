import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../core/domain/server_action_guard.dart';
import '../../../premium/domain/repositories/premium_repository.dart';
import '../entities/auth_error_key.dart';
import '../entities/user_entity.dart';
import '../repositories/account_deletion_repository.dart';
import '../repositories/auth_repository.dart';
import 'resolve_authenticated_user_use_case.dart';
import 'sync_device_token_use_case.dart';

const _selfDeletionReason = 'Self-service account deletion from mobile app';

@injectable
class DeleteAccount {
  DeleteAccount(
    this._authRepository,
    this._accountDeletionRepository,
    this._syncDeviceTokenUseCase,
    this._premiumRepository,
    this._serverActionGuard,
    this._resolveAuthenticatedUser,
  );

  final AuthRepository _authRepository;
  final AccountDeletionRepository _accountDeletionRepository;
  final SyncDeviceTokenUseCase _syncDeviceTokenUseCase;
  final PremiumRepository _premiumRepository;
  final ServerActionGuard _serverActionGuard;
  final ResolveAuthenticatedUserUseCase _resolveAuthenticatedUser;

  Future<Either<Failure, void>> call({UserEntity? sessionUser}) async {
    final UserEntity? currentUser = await _resolveAuthenticatedUser(
      sessionUser: sessionUser,
    );
    if (currentUser == null) {
      logger.d('[DeleteFirebaseUser] Usecase: not signed in, aborting');
      return const Left(
        ValidationFailure(DeleteAccountErrorKey.notSignedIn),
      );
    }

    final String userId = currentUser.id;
    logger.d('[DeleteFirebaseUser] Usecase: start userId=$userId');

    final guardResult = await _serverActionGuard.ensureCanRun(
      ServerActionType.deleteAccount,
    );
    final Failure? blockedFailure = guardResult.fold(
      (failure) => failure,
      (_) => null,
    );
    if (blockedFailure != null) {
      logger.d('[DeleteFirebaseUser] Usecase: blocked by server action guard');
      return Left(blockedFailure);
    }

    final confirmEmail = currentUser.email.isNotEmpty
        ? currentUser.email
        : currentUser.id;
    final deletionResult = await _accountDeletionRepository
        .requestSelfAccountDeletion(
          reason: _selfDeletionReason,
          confirmEmail: confirmEmail,
        );
    final Failure? deletionFailure = deletionResult.fold(
      (failure) => failure,
      (_) => null,
    );
    if (deletionFailure != null) {
      return Left(deletionFailure);
    }
    logger.d('[DeleteFirebaseUser] Usecase: soft-delete requested');

    await _syncDeviceTokenUseCase.removeCurrentTokenForUser(userId);
    logger.d('[DeleteFirebaseUser] Usecase: device token removed');
    await _premiumRepository.clearPremiumStatus();
    logger.d('[DeleteFirebaseUser] Usecase: premium status cleared');

    await _authRepository.signOut();
    logger.d('[DeleteFirebaseUser] Usecase: completed successfully');
    return const Right(null);
  }
}
