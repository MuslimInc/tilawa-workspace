import 'package:firebase_auth/firebase_auth.dart';
import 'package:quran_sessions/quran_sessions.dart';

/// Reads the current Firebase Auth UID without leaking Firebase into domain.
class FirebaseAuthSessionProvider implements AuthSessionProvider {
  FirebaseAuthSessionProvider(this._auth);

  final FirebaseAuth _auth;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Stream<String?> watchUserId() =>
      _auth.authStateChanges().map((user) => user?.uid);
}
