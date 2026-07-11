import 'package:dartz_plus/dartz_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/network/network_error_message.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/email_auth_failure_key.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/gateways/email_password_auth_gateway.dart';
import '../mappers/firebase_auth_exception_mapper.dart';

@LazySingleton(as: EmailPasswordAuthGateway)
class FirebaseEmailPasswordAuthGateway implements EmailPasswordAuthGateway {
  FirebaseEmailPasswordAuthGateway(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  @override
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      final User? user = credential.user;
      if (user == null) {
        return const AuthResult.failure(
          message: EmailAuthFailureKey.generic,
          code: 'null-user',
        );
      }
      return AuthResult.success(user: _mapUser(user));
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(
        message: FirebaseAuthExceptionMapper.mapToFailureKey(error),
        code: error.code,
      );
    } catch (error) {
      if (isNetworkConnectivityErrorMessage(error.toString())) {
        return const AuthResult.failure(
          message: EmailAuthFailureKey.networkError,
          code: 'network',
        );
      }
      return const AuthResult.failure(message: EmailAuthFailureKey.generic);
    }
  }

  @override
  Future<AuthResult> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      final User? user = credential.user;
      if (user == null) {
        return const AuthResult.failure(
          message: EmailAuthFailureKey.generic,
          code: 'null-user',
        );
      }
      return AuthResult.success(user: _mapUser(user));
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(
        message: FirebaseAuthExceptionMapper.mapToFailureKey(error),
        code: error.code,
      );
    } catch (error) {
      if (isNetworkConnectivityErrorMessage(error.toString())) {
        return const AuthResult.failure(
          message: EmailAuthFailureKey.networkError,
          code: 'network',
        );
      }
      return const AuthResult.failure(message: EmailAuthFailureKey.generic);
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return const Right(null);
    } on FirebaseAuthException catch (error) {
      return Left(
        ValidationFailure(
          FirebaseAuthExceptionMapper.mapToFailureKey(error),
        ),
      );
    } catch (error) {
      if (isNetworkConnectivityErrorMessage(error.toString())) {
        return const Left(
          ServerActionFailure.offline(),
        );
      }
      return const Left(
        UnexpectedFailure(EmailAuthFailureKey.generic),
      );
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null || user.emailVerified) {
      return;
    }
    await user.sendEmailVerification();
  }

  UserEntity _mapUser(User firebaseUser) {
    return UserEntity(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }
}
