// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'premium_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PremiumStatus {

 bool get isPremium; DateTime? get subscriptionStartDate; DateTime? get subscriptionEndDate; String? get subscriptionType; bool get isTrialUsed; DateTime? get trialStartDate; DateTime? get trialEndDate;
/// Create a copy of PremiumStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PremiumStatusCopyWith<PremiumStatus> get copyWith => _$PremiumStatusCopyWithImpl<PremiumStatus>(this as PremiumStatus, _$identity);

  /// Serializes this PremiumStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PremiumStatus&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium)&&(identical(other.subscriptionStartDate, subscriptionStartDate) || other.subscriptionStartDate == subscriptionStartDate)&&(identical(other.subscriptionEndDate, subscriptionEndDate) || other.subscriptionEndDate == subscriptionEndDate)&&(identical(other.subscriptionType, subscriptionType) || other.subscriptionType == subscriptionType)&&(identical(other.isTrialUsed, isTrialUsed) || other.isTrialUsed == isTrialUsed)&&(identical(other.trialStartDate, trialStartDate) || other.trialStartDate == trialStartDate)&&(identical(other.trialEndDate, trialEndDate) || other.trialEndDate == trialEndDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isPremium,subscriptionStartDate,subscriptionEndDate,subscriptionType,isTrialUsed,trialStartDate,trialEndDate);

@override
String toString() {
  return 'PremiumStatus(isPremium: $isPremium, subscriptionStartDate: $subscriptionStartDate, subscriptionEndDate: $subscriptionEndDate, subscriptionType: $subscriptionType, isTrialUsed: $isTrialUsed, trialStartDate: $trialStartDate, trialEndDate: $trialEndDate)';
}


}

/// @nodoc
abstract mixin class $PremiumStatusCopyWith<$Res>  {
  factory $PremiumStatusCopyWith(PremiumStatus value, $Res Function(PremiumStatus) _then) = _$PremiumStatusCopyWithImpl;
@useResult
$Res call({
 bool isPremium, DateTime? subscriptionStartDate, DateTime? subscriptionEndDate, String? subscriptionType, bool isTrialUsed, DateTime? trialStartDate, DateTime? trialEndDate
});




}
/// @nodoc
class _$PremiumStatusCopyWithImpl<$Res>
    implements $PremiumStatusCopyWith<$Res> {
  _$PremiumStatusCopyWithImpl(this._self, this._then);

  final PremiumStatus _self;
  final $Res Function(PremiumStatus) _then;

/// Create a copy of PremiumStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isPremium = null,Object? subscriptionStartDate = freezed,Object? subscriptionEndDate = freezed,Object? subscriptionType = freezed,Object? isTrialUsed = null,Object? trialStartDate = freezed,Object? trialEndDate = freezed,}) {
  return _then(_self.copyWith(
isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,subscriptionStartDate: freezed == subscriptionStartDate ? _self.subscriptionStartDate : subscriptionStartDate // ignore: cast_nullable_to_non_nullable
as DateTime?,subscriptionEndDate: freezed == subscriptionEndDate ? _self.subscriptionEndDate : subscriptionEndDate // ignore: cast_nullable_to_non_nullable
as DateTime?,subscriptionType: freezed == subscriptionType ? _self.subscriptionType : subscriptionType // ignore: cast_nullable_to_non_nullable
as String?,isTrialUsed: null == isTrialUsed ? _self.isTrialUsed : isTrialUsed // ignore: cast_nullable_to_non_nullable
as bool,trialStartDate: freezed == trialStartDate ? _self.trialStartDate : trialStartDate // ignore: cast_nullable_to_non_nullable
as DateTime?,trialEndDate: freezed == trialEndDate ? _self.trialEndDate : trialEndDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PremiumStatus].
extension PremiumStatusPatterns on PremiumStatus {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PremiumStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PremiumStatus() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PremiumStatus value)  $default,){
final _that = this;
switch (_that) {
case _PremiumStatus():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PremiumStatus value)?  $default,){
final _that = this;
switch (_that) {
case _PremiumStatus() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isPremium,  DateTime? subscriptionStartDate,  DateTime? subscriptionEndDate,  String? subscriptionType,  bool isTrialUsed,  DateTime? trialStartDate,  DateTime? trialEndDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PremiumStatus() when $default != null:
return $default(_that.isPremium,_that.subscriptionStartDate,_that.subscriptionEndDate,_that.subscriptionType,_that.isTrialUsed,_that.trialStartDate,_that.trialEndDate);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isPremium,  DateTime? subscriptionStartDate,  DateTime? subscriptionEndDate,  String? subscriptionType,  bool isTrialUsed,  DateTime? trialStartDate,  DateTime? trialEndDate)  $default,) {final _that = this;
switch (_that) {
case _PremiumStatus():
return $default(_that.isPremium,_that.subscriptionStartDate,_that.subscriptionEndDate,_that.subscriptionType,_that.isTrialUsed,_that.trialStartDate,_that.trialEndDate);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isPremium,  DateTime? subscriptionStartDate,  DateTime? subscriptionEndDate,  String? subscriptionType,  bool isTrialUsed,  DateTime? trialStartDate,  DateTime? trialEndDate)?  $default,) {final _that = this;
switch (_that) {
case _PremiumStatus() when $default != null:
return $default(_that.isPremium,_that.subscriptionStartDate,_that.subscriptionEndDate,_that.subscriptionType,_that.isTrialUsed,_that.trialStartDate,_that.trialEndDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PremiumStatus extends PremiumStatus {
  const _PremiumStatus({required this.isPremium, required this.subscriptionStartDate, required this.subscriptionEndDate, required this.subscriptionType, required this.isTrialUsed, required this.trialStartDate, required this.trialEndDate}): super._();
  factory _PremiumStatus.fromJson(Map<String, dynamic> json) => _$PremiumStatusFromJson(json);

@override final  bool isPremium;
@override final  DateTime? subscriptionStartDate;
@override final  DateTime? subscriptionEndDate;
@override final  String? subscriptionType;
@override final  bool isTrialUsed;
@override final  DateTime? trialStartDate;
@override final  DateTime? trialEndDate;

/// Create a copy of PremiumStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PremiumStatusCopyWith<_PremiumStatus> get copyWith => __$PremiumStatusCopyWithImpl<_PremiumStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PremiumStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PremiumStatus&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium)&&(identical(other.subscriptionStartDate, subscriptionStartDate) || other.subscriptionStartDate == subscriptionStartDate)&&(identical(other.subscriptionEndDate, subscriptionEndDate) || other.subscriptionEndDate == subscriptionEndDate)&&(identical(other.subscriptionType, subscriptionType) || other.subscriptionType == subscriptionType)&&(identical(other.isTrialUsed, isTrialUsed) || other.isTrialUsed == isTrialUsed)&&(identical(other.trialStartDate, trialStartDate) || other.trialStartDate == trialStartDate)&&(identical(other.trialEndDate, trialEndDate) || other.trialEndDate == trialEndDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isPremium,subscriptionStartDate,subscriptionEndDate,subscriptionType,isTrialUsed,trialStartDate,trialEndDate);

@override
String toString() {
  return 'PremiumStatus(isPremium: $isPremium, subscriptionStartDate: $subscriptionStartDate, subscriptionEndDate: $subscriptionEndDate, subscriptionType: $subscriptionType, isTrialUsed: $isTrialUsed, trialStartDate: $trialStartDate, trialEndDate: $trialEndDate)';
}


}

/// @nodoc
abstract mixin class _$PremiumStatusCopyWith<$Res> implements $PremiumStatusCopyWith<$Res> {
  factory _$PremiumStatusCopyWith(_PremiumStatus value, $Res Function(_PremiumStatus) _then) = __$PremiumStatusCopyWithImpl;
@override @useResult
$Res call({
 bool isPremium, DateTime? subscriptionStartDate, DateTime? subscriptionEndDate, String? subscriptionType, bool isTrialUsed, DateTime? trialStartDate, DateTime? trialEndDate
});




}
/// @nodoc
class __$PremiumStatusCopyWithImpl<$Res>
    implements _$PremiumStatusCopyWith<$Res> {
  __$PremiumStatusCopyWithImpl(this._self, this._then);

  final _PremiumStatus _self;
  final $Res Function(_PremiumStatus) _then;

/// Create a copy of PremiumStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isPremium = null,Object? subscriptionStartDate = freezed,Object? subscriptionEndDate = freezed,Object? subscriptionType = freezed,Object? isTrialUsed = null,Object? trialStartDate = freezed,Object? trialEndDate = freezed,}) {
  return _then(_PremiumStatus(
isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,subscriptionStartDate: freezed == subscriptionStartDate ? _self.subscriptionStartDate : subscriptionStartDate // ignore: cast_nullable_to_non_nullable
as DateTime?,subscriptionEndDate: freezed == subscriptionEndDate ? _self.subscriptionEndDate : subscriptionEndDate // ignore: cast_nullable_to_non_nullable
as DateTime?,subscriptionType: freezed == subscriptionType ? _self.subscriptionType : subscriptionType // ignore: cast_nullable_to_non_nullable
as String?,isTrialUsed: null == isTrialUsed ? _self.isTrialUsed : isTrialUsed // ignore: cast_nullable_to_non_nullable
as bool,trialStartDate: freezed == trialStartDate ? _self.trialStartDate : trialStartDate // ignore: cast_nullable_to_non_nullable
as DateTime?,trialEndDate: freezed == trialEndDate ? _self.trialEndDate : trialEndDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
