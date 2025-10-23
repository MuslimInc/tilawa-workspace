import 'package:muzakri/features/auth/domain/entities/auth_result.dart';
import 'package:muzakri/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;

  Future<AuthResult> signInWithGoogle();

  Future<void> signOut();

  UserEntity? get currentUser;
}
