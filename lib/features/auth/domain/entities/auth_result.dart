import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:muzakri/features/auth/domain/entities/user.dart';

part 'auth_result.freezed.dart';
part 'auth_result.g.dart';

@freezed
abstract class AuthResult with _$AuthResult {
  const factory AuthResult.success({required User user}) = AuthSuccess;

  const factory AuthResult.failure({required String message, String? code}) =
      AuthFailure;

  const factory AuthResult.cancelled() = AuthCancelled;

  factory AuthResult.fromJson(Map<String, dynamic> json) =>
      _$AuthResultFromJson(json);
}
