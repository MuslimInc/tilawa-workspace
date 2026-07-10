import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_entity.dart';

part 'register_with_email_result.freezed.dart';

/// Outcome of email registration after the final wizard submit.
@freezed
abstract class RegisterWithEmailResult with _$RegisterWithEmailResult {
  const factory RegisterWithEmailResult.completed({
    required UserEntity user,
  }) = RegisterWithEmailCompleted;

  const factory RegisterWithEmailResult.authFailed({
    required String message,
    String? code,
    String? details,
  }) = RegisterWithEmailAuthFailed;

  /// Firebase Auth user exists but Firestore profile write failed.
  const factory RegisterWithEmailResult.profilePersistenceFailed({
    required UserEntity user,
  }) = RegisterWithEmailProfilePersistenceFailed;
}
