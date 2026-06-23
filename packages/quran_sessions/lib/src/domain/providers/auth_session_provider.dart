/// Backend-agnostic access to the currently authenticated user identity.
///
/// Host apps provide a Firebase, REST-session, or test implementation.
/// Use cases and BLoCs receive a [userId] string — they never call
/// `FirebaseAuth.instance` directly.
abstract interface class AuthSessionProvider {
  /// UID of the signed-in user, or null when unauthenticated.
  String? get currentUserId;

  /// Emits the current UID whenever auth state changes.
  Stream<String?> watchUserId();
}
