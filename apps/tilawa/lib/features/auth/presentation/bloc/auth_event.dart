part of 'auth_bloc.dart';

@freezed
abstract class AuthEvent with _$AuthEvent {
  const factory AuthEvent.signInWithGoogle() = SignInWithGoogleEvent;
  const factory AuthEvent.signInWithApple() = SignInWithAppleEvent;
  const factory AuthEvent.signInWithEmail({
    required String email,
    required String password,
  }) = SignInWithEmailEvent;
  const factory AuthEvent.registerWithEmail({
    required EmailRegistrationDraft draft,
  }) = RegisterWithEmailEvent;
  const factory AuthEvent.signOut() = SignOutEvent;
  const factory AuthEvent.deleteAccount() = DeleteAccountEvent;
  const factory AuthEvent.checkAuthStatus() = CheckAuthStatusEvent;

  /// Syncs bloc state after [SessionValidityCubit] revoked the remote session.
  const factory AuthEvent.sessionInvalidated() = SessionInvalidatedEvent;

  /// Drops an in-flight interactive sign-in without signing out of Firebase.
  const factory AuthEvent.abortInteractiveSignIn() =
      AbortInteractiveSignInEvent;

  /// Refreshes the authenticated user after Edit Profile save.
  const factory AuthEvent.accountProfileUpdated({
    required UserEntity user,
  }) = AccountProfileUpdatedEvent;
}
