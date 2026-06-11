import 'package:dartz_plus/dartz_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../premium/domain/repositories/premium_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import 'sync_device_token_use_case.dart';

@injectable
class DeleteAccount {
  DeleteAccount(
    this._authRepository,
    this._userRepository,
    this._syncDeviceTokenUseCase,
    this._premiumRepository,
  );

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final SyncDeviceTokenUseCase _syncDeviceTokenUseCase;
  final PremiumRepository _premiumRepository;

  Future<Either<Failure, void>> call() async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      return const Left(ValidationFailure('Not signed in'));
    }

    final String userId = currentUser.id;

    try {
      // Re-auth first; if the user cancels, no Firestore data is touched.
      await _authRepository.reauthenticateForAccountDeletion();

      // Firestore rules require an authenticated owner — clean up before
      // deleting the Firebase Auth user.
      await _syncDeviceTokenUseCase.removeCurrentTokenForUser(userId);
      await _userRepository.deleteUserData(userId);
      await _premiumRepository.clearPremiumStatus();

      await _authRepository.deleteAccount();
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      if (_isReauthCancelled(e)) {
        return const Left(UserCancelledFailure());
      }
      return Left(UnexpectedFailure(e.message ?? e.code));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted ||
          e.code == GoogleSignInExceptionCode.uiUnavailable) {
        return const Left(UserCancelledFailure());
      }
      return Left(UnexpectedFailure(e.description ?? e.code.name));
    } on PlatformException catch (e) {
      if (e.code == '204' ||
          (e.message?.contains('No credentials available') ?? false) ||
          (e.message?.contains('Login failed') ?? false)) {
        return const Left(UserCancelledFailure());
      }
      return Left(UnexpectedFailure(e.message ?? e.code));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  bool _isReauthCancelled(FirebaseAuthException e) {
    return e.code == 'requires-recent-login' &&
        (e.message?.contains('cancelled') ?? false);
  }
}
