import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:muzakri/features/auth/domain/entities/user_entity.dart';

part 'auth_result.freezed.dart';
part 'auth_result.g.dart';

@freezed
abstract class AuthResult with _$AuthResult {
  const factory AuthResult.success({required UserEntity user}) = AuthSuccess;

  const factory AuthResult.failure({required String message, String? code}) =
      AuthFailure;

  const factory AuthResult.cancelled() = AuthCancelled;

  factory AuthResult.fromJson(Map<String, dynamic> json) =>
      _$AuthResultFromJson(json);
}
