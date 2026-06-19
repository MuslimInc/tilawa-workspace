import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_entity.dart';

part 'auth_result.freezed.dart';
part 'auth_result.g.dart';

@freezed
abstract class AuthResult with _$AuthResult {
  const factory AuthResult.success({required UserEntity user}) = AuthSuccess;

  const factory AuthResult.failure({
    required String message,
    String? code,

    /// Provider diagnostics (e.g. the native stack trace carried in
    /// `CredentialException.details`) — for logging, never for UI.
    String? details,
  }) = AuthFailure;

  const factory AuthResult.cancelled() = AuthCancelled;

  /// The device has no Google accounts configured; sign-in cannot proceed
  /// without the user adding an account via device settings.
  const factory AuthResult.noGoogleAccounts() = AuthResultNoGoogleAccounts;

  factory AuthResult.fromJson(Map<String, dynamic> json) =>
      _$AuthResultFromJson(json);
}
