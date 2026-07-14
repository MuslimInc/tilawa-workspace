import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/network/network_error_message.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/auth_error_key.dart';
import '../../domain/repositories/account_deletion_repository.dart';
import '../datasources/account_deletion_remote_data_source.dart';

@LazySingleton(as: AccountDeletionRepository)
class AccountDeletionRepositoryImpl implements AccountDeletionRepository {
  AccountDeletionRepositoryImpl(this._remoteDataSource);

  final AccountDeletionRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, void>> requestSelfAccountDeletion({
    required String reason,
    required String confirmEmail,
  }) async {
    try {
      await _remoteDataSource.requestSelfAccountDeletion(
        reason: reason,
        confirmEmail: confirmEmail,
      );
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      logger.d(
        '[DeleteFirebaseUser] Repository: FirebaseFunctionsException '
        'code=${e.code} message=${e.message}',
      );
      return Left(_mapCallableFailure(e));
    } catch (e) {
      logger.d(
        '[DeleteFirebaseUser] Repository: unexpected ${e.runtimeType}: $e',
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
