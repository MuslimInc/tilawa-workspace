import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../entities/auth_result.dart';

/// Email/password authentication against Firebase Auth.
///
/// Firebase types stay in the data implementation.
abstract class EmailPasswordAuthGateway {
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AuthResult> registerWithEmailPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> sendPasswordResetEmail({required String email});

  /// Best-effort verification email for the current session.
  Future<void> sendEmailVerification();
}
