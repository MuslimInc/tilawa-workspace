import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../core/domain/server_action_guard.dart';
import '../entities/auth_result.dart';
import '../entities/email_registration_draft.dart';
import '../entities/register_with_email_result.dart';
import '../entities/user_entity.dart';
import '../gateways/email_password_auth_gateway.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

@injectable
class RegisterWithEmailUseCase {
  RegisterWithEmailUseCase(
    this._authRepository,
    this._userRepository,
    this._emailPasswordAuth,
    this._serverActionGuard,
  );

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final EmailPasswordAuthGateway _emailPasswordAuth;
  final ServerActionGuard _serverActionGuard;

  Future<RegisterWithEmailResult> call({
    required EmailRegistrationDraft draft,
  }) async {
    final guardResult = await _serverActionGuard.ensureCanRun(
      ServerActionType.googleSignIn,
    );
    final Failure? blockedFailure = guardResult.fold(
      (failure) => failure,
      (_) => null,
    );
    if (blockedFailure != null) {
      return RegisterWithEmailResult.authFailed(
        message: blockedFailure.message ?? ServerActionFailureKey.offline,
        code: 'offline',
      );
    }

    final AuthResult result = await _authRepository.registerWithEmailPassword(
      email: draft.email.trim(),
      password: draft.password,
    );

    return result.maybeWhen(
      success: (UserEntity user) => _persistRegistration(user, draft),
      failure: (String message, String? code, String? details) =>
          RegisterWithEmailResult.authFailed(
            message: message,
            code: code,
            details: details,
          ),
      orElse: () => const RegisterWithEmailResult.authFailed(
        message: 'authErrorGenericMessage',
      ),
    );
  }

  Future<RegisterWithEmailResult> retryProfilePersistence({
    required UserEntity user,
    required EmailRegistrationDraft draft,
  }) async {
    return _persistRegistration(user, draft);
  }

  Future<RegisterWithEmailResult> _persistRegistration(
    UserEntity user,
    EmailRegistrationDraft draft,
  ) async {
    try {
      final UserEntity mergedUser = user.copyWith(
        displayName: draft.displayName.trim(),
      );
      await _userRepository.saveCompleteEmailRegistration(
        user: mergedUser,
        draft: draft,
      );
      unawaited(_sendVerificationBestEffort());
      return RegisterWithEmailResult.completed(
        user: mergedUser,
      );
    } catch (error, stackTrace) {
      logger.w(
        'Registered but failed to persist complete profile',
        error: error,
        stackTrace: stackTrace,
      );
      return RegisterWithEmailResult.profilePersistenceFailed(
        user: user.copyWith(displayName: draft.displayName.trim()),
      );
    }
  }

  Future<void> _sendVerificationBestEffort() async {
    try {
      await _emailPasswordAuth.sendEmailVerification();
    } catch (error, stackTrace) {
      logger.w(
        'Failed to send verification email after registration',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
