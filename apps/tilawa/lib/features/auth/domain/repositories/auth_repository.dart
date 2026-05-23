import '../entities/auth_result.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;

  Future<AuthResult> signInWithGoogle();

  /// Pre-warms Google account UI (Credential Manager on Android).
  Future<void> prepareGoogleSignIn();

  Future<void> signOut();

  UserEntity? get currentUser;
}
