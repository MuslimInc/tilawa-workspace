import 'package:muzakri/features/auth/domain/entities/auth_result.dart';
import 'package:muzakri/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;

  Future<AuthResult> signInWithGoogle();

  Future<void> signOut();

  User? get currentUser;
}
