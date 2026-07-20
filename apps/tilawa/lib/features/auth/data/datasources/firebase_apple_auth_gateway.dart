import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:tilawa/core/network/network_error_message.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/email_auth_failure_key.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/gateways/apple_auth_gateway.dart';
import '../mappers/firebase_auth_exception_mapper.dart';

@LazySingleton(as: AppleAuthGateway)
class FirebaseAppleAuthGateway implements AppleAuthGateway {
  FirebaseAppleAuthGateway(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  @override
  Future<AuthResult> signInWithApple() async {
    try {
      final String rawNonce = _generateNonce();
      final String nonce = _sha256ofString(rawNonce);

      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
            scopes: <AppleIDAuthorizationScopes>[
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: nonce,
          );

      final String? idToken = appleCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        return const AuthResult.failure(
          message: EmailAuthFailureKey.generic,
          code: 'missing-apple-id-token',
        );
      }

      final OAuthCredential oauthCredential = OAuthProvider('apple.com')
          .credential(
            idToken: idToken,
            rawNonce: rawNonce,
            accessToken: appleCredential.authorizationCode,
          );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(oauthCredential);
      final User? user = userCredential.user;
      if (user == null) {
        return const AuthResult.failure(
          message: EmailAuthFailureKey.generic,
          code: 'null-user',
        );
      }

      await _maybeApplyAppleDisplayName(user, appleCredential);

      return AuthResult.success(user: _mapUser(user));
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return const AuthResult.cancelled();
      }
      return AuthResult.failure(
        message: EmailAuthFailureKey.generic,
        code: error.code.name,
        details: error.message,
      );
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

  Future<void> _maybeApplyAppleDisplayName(
    User user,
    AuthorizationCredentialAppleID appleCredential,
  ) async {
    final String given = appleCredential.givenName?.trim() ?? '';
    final String family = appleCredential.familyName?.trim() ?? '';
    final String composed = '$given $family'.trim();
    if (composed.isEmpty) {
      return;
    }
    if ((user.displayName ?? '').trim().isNotEmpty) {
      return;
    }
    await user.updateDisplayName(composed);
    await user.reload();
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

  String _generateNonce([int length = 32]) {
    const String charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final Random random = Random.secure();
    return List<String>.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final List<int> bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
