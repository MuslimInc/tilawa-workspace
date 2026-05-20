import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthService {
  AuthService({required this._auth});
  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    // Initialize Google Sign-In (no-op if already initialized)
    await GoogleSignIn.instance.initialize();

    // Interactive auth flow
    final GoogleSignInAccount account = await GoogleSignIn.instance
        .authenticate();

    // Obtain ID token
    final GoogleSignInAuthentication googleAuth = account.authentication;

    if (googleAuth.idToken == null) {
      throw Exception('Failed to obtain Google ID token');
    }

    // Create Firebase credential (ID token is sufficient for Firebase)
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn.instance.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
