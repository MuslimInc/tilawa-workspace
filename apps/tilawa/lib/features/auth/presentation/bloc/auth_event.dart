part of 'auth_bloc.dart';

@freezed
abstract class AuthEvent with _$AuthEvent {
  const factory AuthEvent.signInWithGoogle() = SignInWithGoogleEvent;
  const factory AuthEvent.signOut() = SignOutEvent;
  const factory AuthEvent.deleteAccount() = DeleteAccountEvent;
  const factory AuthEvent.checkAuthStatus() = CheckAuthStatusEvent;
}
