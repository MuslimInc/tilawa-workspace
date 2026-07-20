import '../entities/auth_result.dart';

/// Sign in with Apple against Firebase Auth.
///
/// Firebase / Apple SDK types stay in the data implementation.
abstract class AppleAuthGateway {
  Future<AuthResult> signInWithApple();
}
