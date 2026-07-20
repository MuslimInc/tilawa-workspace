import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../core/domain/server_action_guard.dart';
import '../entities/auth_result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

@injectable
class SignInWithAppleUseCase {
  SignInWithAppleUseCase(
    this._authRepository,
    this._userRepository,
    this._serverActionGuard,
  );

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final ServerActionGuard _serverActionGuard;

  Future<AuthResult> call() async {
    final guardResult = await _serverActionGuard.ensureCanRun(
      ServerActionType.googleSignIn,
    );
    final Failure? blockedFailure = guardResult.fold(
      (failure) => failure,
      (_) => null,
    );
    if (blockedFailure != null) {
      return AuthResult.failure(
        message: blockedFailure.message ?? ServerActionFailureKey.offline,
        code: 'offline',
      );
    }

    final AuthResult result = await _authRepository.signInWithApple();

    return result.maybeWhen(
      success: (UserEntity user) {
        unawaited(_persistUserProfile(user));
        return AuthResult.success(user: user);
      },
      orElse: () => result,
    );
  }

  Future<void> _persistUserProfile(UserEntity user) async {
    try {
      final bool generalProfileComplete = user.displayName.trim().isNotEmpty;
      await _userRepository.saveUserData(
        user,
        authProvider: 'apple',
        profileCompleted: generalProfileComplete,
      );
    } catch (error, stackTrace) {
      logger.w(
        'Signed in but failed to persist user profile',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
