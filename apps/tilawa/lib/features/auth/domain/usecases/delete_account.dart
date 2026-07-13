import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/network/network_error_message.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../core/domain/server_action_guard.dart';
import '../../../premium/domain/repositories/premium_repository.dart';
import '../../data/datasources/account_deletion_remote_data_source.dart';
import '../entities/auth_error_key.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import 'resolve_authenticated_user_use_case.dart';
import 'sync_device_token_use_case.dart';

const _selfDeletionReason = 'Self-service account deletion from mobile app';

@injectable
class DeleteAccount {
  DeleteAccount(
    this._authRepository,
    this._accountDeletionRemoteDataSource,
    this._syncDeviceTokenUseCase,
    this._premiumRepository,
    this._serverActionGuard,
    this._resolveAuthenticatedUser,
  );

  final AuthRepository _authRepository;
  final AccountDeletionRemoteDataSource _accountDeletionRemoteDataSource;
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

    try {
      final confirmEmail = currentUser.email.isNotEmpty
          ? currentUser.email
          : currentUser.id;
      await _accountDeletionRemoteDataSource.requestSelfAccountDeletion(
        reason: _selfDeletionReason,
        confirmEmail: confirmEmail,
      );
      logger.d('[DeleteFirebaseUser] Usecase: soft-delete requested');

      await _syncDeviceTokenUseCase.removeCurrentTokenForUser(userId);
      logger.d('[DeleteFirebaseUser] Usecase: device token removed');
      await _premiumRepository.clearPremiumStatus();
      logger.d('[DeleteFirebaseUser] Usecase: premium status cleared');

      await _authRepository.signOut();
      logger.d('[DeleteFirebaseUser] Usecase: completed successfully');
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      logger.d(
        '[DeleteFirebaseUser] Usecase: FirebaseFunctionsException '
        'code=${e.code} message=${e.message}',
      );
      return Left(_mapCallableFailure(e));
    } catch (e) {
      logger.d(
        '[DeleteFirebaseUser] Usecase: unexpected ${e.runtimeType}: $e',
      );
      final String errorText = e.toString();
      if (isNetworkConnectivityErrorMessage(errorText)) {
        return const Left(ServerActionFailure.offline());
      }
      return Left(UnexpectedFailure(errorText));
    }
  }

  Failure _mapCallableFailure(FirebaseFunctionsException error) {
    if (error.code == 'not-found' && _isUndeployedCallable(error)) {
      return const ServerFailure(DeleteAccountErrorKey.serviceUnavailable);
    }

    final message =
        _mapServerMessageToKey(error.message) ?? error.message ?? error.code;
    return switch (error.code) {
      'failed-precondition' => ValidationFailure(message),
      'invalid-argument' => ValidationFailure(message),
      'permission-denied' => PermissionFailure(message),
      'unauthenticated' => PermissionFailure(message),
      'not-found' => ValidationFailure(message),
      'unavailable' ||
      'deadline-exceeded' => const ServerActionFailure.offline(),
      'internal' => const ServerFailure(
        DeleteAccountErrorKey.failed,
      ),
      _ => const UnexpectedFailure(DeleteAccountErrorKey.failed),
    };
  }

  String? _mapServerMessageToKey(String? message) {
    if (message == null || message.isEmpty) {
      return null;
    }

    final normalized = message.toLowerCase();
    if (message.contains(
          'Admin accounts must be deleted from the admin panel',
        ) ||
        message.contains('Admin accounts cannot be deleted via self-service')) {
      return DeleteAccountErrorKey.adminMustUseAdminPanel;
    }
    if (normalized.contains('wallet balance is not zero')) {
      return DeleteAccountErrorKey.walletNotEmpty;
    }
    if (message.contains('active bookings as a student')) {
      return DeleteAccountErrorKey.activeBookingsStudent;
    }
    if (message.contains('active bookings as a teacher')) {
      return DeleteAccountErrorKey.activeBookingsTeacher;
    }
    if (message.contains('Deletion is already pending')) {
      return DeleteAccountErrorKey.alreadyPending;
    }
    return null;
  }

  /// Firebase returns generic [NOT_FOUND] when the callable is not deployed.
  /// Backend guard errors use a descriptive message instead.
  bool _isUndeployedCallable(FirebaseFunctionsException error) {
    final message = error.message?.trim();
    return message == null ||
        message.isEmpty ||
        message.toUpperCase() == 'NOT_FOUND';
  }
}
