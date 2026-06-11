import '../entities/auth_result.dart';
import '../entities/user_entity.dart';

/// Abstract interface for authentication providers
/// This allows us to easily switch between different authentication methods
/// (Google Sign-In, Credential Manager, etc.) without changing the business logic
abstract class AuthProviderInterface {
  /// Sign in with the provider and return an AuthResult
  Future<AuthResult> signIn();

  /// Sign out from the provider
  Future<void> signOut();

  /// Deletes the signed-in Firebase user (call after Firestore cleanup).
  Future<void> deleteAccount();

  /// Get the current user from the provider
  UserEntity? get currentUser;

  /// Stream of authentication state changes
  Stream<UserEntity?> get authStateChanges;
}
