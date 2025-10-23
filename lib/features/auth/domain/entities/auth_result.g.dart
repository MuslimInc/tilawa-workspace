// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthSuccess _$AuthSuccessFromJson(Map<String, dynamic> json) => AuthSuccess(
  user: UserEntity.fromJson(json['user'] as Map<String, dynamic>),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$AuthSuccessToJson(AuthSuccess instance) =>
    <String, dynamic>{
      'user': instance.user.toJson(),
      'runtimeType': instance.$type,
    };

AuthFailure _$AuthFailureFromJson(Map<String, dynamic> json) => AuthFailure(
  message: json['message'] as String,
  code: json['code'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$AuthFailureToJson(AuthFailure instance) =>
    <String, dynamic>{
      'message': instance.message,
      'code': instance.code,
      'runtimeType': instance.$type,
    };

AuthCancelled _$AuthCancelledFromJson(Map<String, dynamic> json) =>
    AuthCancelled($type: json['runtimeType'] as String?);

Map<String, dynamic> _$AuthCancelledToJson(AuthCancelled instance) =>
    <String, dynamic>{'runtimeType': instance.$type};
