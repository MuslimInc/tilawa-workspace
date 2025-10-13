// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'premium_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PremiumState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PremiumState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PremiumState()';
}


}

/// @nodoc
class $PremiumStateCopyWith<$Res>  {
$PremiumStateCopyWith(PremiumState _, $Res Function(PremiumState) __);
}


/// Adds pattern-matching-related methods to [PremiumState].
extension PremiumStatePatterns on PremiumState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PremiumInitial value)?  initial,TResult Function( PremiumLoading value)?  loading,TResult Function( PremiumLoaded value)?  loaded,TResult Function( PremiumError value)?  error,TResult Function( PremiumPurchaseSuccess value)?  purchaseSuccess,TResult Function( PremiumPurchaseFailed value)?  purchaseFailed,TResult Function( PremiumTrialStarted value)?  trialStarted,TResult Function( PremiumTrialNotEligible value)?  trialNotEligible,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PremiumInitial() when initial != null:
return initial(_that);case PremiumLoading() when loading != null:
return loading(_that);case PremiumLoaded() when loaded != null:
return loaded(_that);case PremiumError() when error != null:
return error(_that);case PremiumPurchaseSuccess() when purchaseSuccess != null:
return purchaseSuccess(_that);case PremiumPurchaseFailed() when purchaseFailed != null:
return purchaseFailed(_that);case PremiumTrialStarted() when trialStarted != null:
return trialStarted(_that);case PremiumTrialNotEligible() when trialNotEligible != null:
return trialNotEligible(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PremiumInitial value)  initial,required TResult Function( PremiumLoading value)  loading,required TResult Function( PremiumLoaded value)  loaded,required TResult Function( PremiumError value)  error,required TResult Function( PremiumPurchaseSuccess value)  purchaseSuccess,required TResult Function( PremiumPurchaseFailed value)  purchaseFailed,required TResult Function( PremiumTrialStarted value)  trialStarted,required TResult Function( PremiumTrialNotEligible value)  trialNotEligible,}){
final _that = this;
switch (_that) {
case PremiumInitial():
return initial(_that);case PremiumLoading():
return loading(_that);case PremiumLoaded():
return loaded(_that);case PremiumError():
return error(_that);case PremiumPurchaseSuccess():
return purchaseSuccess(_that);case PremiumPurchaseFailed():
return purchaseFailed(_that);case PremiumTrialStarted():
return trialStarted(_that);case PremiumTrialNotEligible():
return trialNotEligible(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PremiumInitial value)?  initial,TResult? Function( PremiumLoading value)?  loading,TResult? Function( PremiumLoaded value)?  loaded,TResult? Function( PremiumError value)?  error,TResult? Function( PremiumPurchaseSuccess value)?  purchaseSuccess,TResult? Function( PremiumPurchaseFailed value)?  purchaseFailed,TResult? Function( PremiumTrialStarted value)?  trialStarted,TResult? Function( PremiumTrialNotEligible value)?  trialNotEligible,}){
final _that = this;
switch (_that) {
case PremiumInitial() when initial != null:
return initial(_that);case PremiumLoading() when loading != null:
return loading(_that);case PremiumLoaded() when loaded != null:
return loaded(_that);case PremiumError() when error != null:
return error(_that);case PremiumPurchaseSuccess() when purchaseSuccess != null:
return purchaseSuccess(_that);case PremiumPurchaseFailed() when purchaseFailed != null:
return purchaseFailed(_that);case PremiumTrialStarted() when trialStarted != null:
return trialStarted(_that);case PremiumTrialNotEligible() when trialNotEligible != null:
return trialNotEligible(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( PremiumStatus status,  List<SubscriptionPlan> availablePlans,  bool canDownload)?  loaded,TResult Function( String message)?  error,TResult Function( String message)?  purchaseSuccess,TResult Function( String message)?  purchaseFailed,TResult Function( String message)?  trialStarted,TResult Function( String message)?  trialNotEligible,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PremiumInitial() when initial != null:
return initial();case PremiumLoading() when loading != null:
return loading();case PremiumLoaded() when loaded != null:
return loaded(_that.status,_that.availablePlans,_that.canDownload);case PremiumError() when error != null:
return error(_that.message);case PremiumPurchaseSuccess() when purchaseSuccess != null:
return purchaseSuccess(_that.message);case PremiumPurchaseFailed() when purchaseFailed != null:
return purchaseFailed(_that.message);case PremiumTrialStarted() when trialStarted != null:
return trialStarted(_that.message);case PremiumTrialNotEligible() when trialNotEligible != null:
return trialNotEligible(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( PremiumStatus status,  List<SubscriptionPlan> availablePlans,  bool canDownload)  loaded,required TResult Function( String message)  error,required TResult Function( String message)  purchaseSuccess,required TResult Function( String message)  purchaseFailed,required TResult Function( String message)  trialStarted,required TResult Function( String message)  trialNotEligible,}) {final _that = this;
switch (_that) {
case PremiumInitial():
return initial();case PremiumLoading():
return loading();case PremiumLoaded():
return loaded(_that.status,_that.availablePlans,_that.canDownload);case PremiumError():
return error(_that.message);case PremiumPurchaseSuccess():
return purchaseSuccess(_that.message);case PremiumPurchaseFailed():
return purchaseFailed(_that.message);case PremiumTrialStarted():
return trialStarted(_that.message);case PremiumTrialNotEligible():
return trialNotEligible(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( PremiumStatus status,  List<SubscriptionPlan> availablePlans,  bool canDownload)?  loaded,TResult? Function( String message)?  error,TResult? Function( String message)?  purchaseSuccess,TResult? Function( String message)?  purchaseFailed,TResult? Function( String message)?  trialStarted,TResult? Function( String message)?  trialNotEligible,}) {final _that = this;
switch (_that) {
case PremiumInitial() when initial != null:
return initial();case PremiumLoading() when loading != null:
return loading();case PremiumLoaded() when loaded != null:
return loaded(_that.status,_that.availablePlans,_that.canDownload);case PremiumError() when error != null:
return error(_that.message);case PremiumPurchaseSuccess() when purchaseSuccess != null:
return purchaseSuccess(_that.message);case PremiumPurchaseFailed() when purchaseFailed != null:
return purchaseFailed(_that.message);case PremiumTrialStarted() when trialStarted != null:
return trialStarted(_that.message);case PremiumTrialNotEligible() when trialNotEligible != null:
return trialNotEligible(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class PremiumInitial implements PremiumState {
  const PremiumInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PremiumInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PremiumState.initial()';
}


}




/// @nodoc


class PremiumLoading implements PremiumState {
  const PremiumLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PremiumLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PremiumState.loading()';
}


}




/// @nodoc


class PremiumLoaded implements PremiumState {
  const PremiumLoaded({required this.status, required final  List<SubscriptionPlan> availablePlans, required this.canDownload}): _availablePlans = availablePlans;
  

 final  PremiumStatus status;
 final  List<SubscriptionPlan> _availablePlans;
 List<SubscriptionPlan> get availablePlans {
  if (_availablePlans is EqualUnmodifiableListView) return _availablePlans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availablePlans);
}

 final  bool canDownload;

/// Create a copy of PremiumState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PremiumLoadedCopyWith<PremiumLoaded> get copyWith => _$PremiumLoadedCopyWithImpl<PremiumLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PremiumLoaded&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._availablePlans, _availablePlans)&&(identical(other.canDownload, canDownload) || other.canDownload == canDownload));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_availablePlans),canDownload);

@override
String toString() {
  return 'PremiumState.loaded(status: $status, availablePlans: $availablePlans, canDownload: $canDownload)';
}


}

/// @nodoc
abstract mixin class $PremiumLoadedCopyWith<$Res> implements $PremiumStateCopyWith<$Res> {
  factory $PremiumLoadedCopyWith(PremiumLoaded value, $Res Function(PremiumLoaded) _then) = _$PremiumLoadedCopyWithImpl;
@useResult
$Res call({
 PremiumStatus status, List<SubscriptionPlan> availablePlans, bool canDownload
});


$PremiumStatusCopyWith<$Res> get status;

}
/// @nodoc
class _$PremiumLoadedCopyWithImpl<$Res>
    implements $PremiumLoadedCopyWith<$Res> {
  _$PremiumLoadedCopyWithImpl(this._self, this._then);

  final PremiumLoaded _self;
  final $Res Function(PremiumLoaded) _then;

/// Create a copy of PremiumState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? status = null,Object? availablePlans = null,Object? canDownload = null,}) {
  return _then(PremiumLoaded(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PremiumStatus,availablePlans: null == availablePlans ? _self._availablePlans : availablePlans // ignore: cast_nullable_to_non_nullable
as List<SubscriptionPlan>,canDownload: null == canDownload ? _self.canDownload : canDownload // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PremiumState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PremiumStatusCopyWith<$Res> get status {
  
  return $PremiumStatusCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}
}

/// @nodoc


class PremiumError implements PremiumState {
  const PremiumError({required this.message});
  

 final  String message;

/// Create a copy of PremiumState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PremiumErrorCopyWith<PremiumError> get copyWith => _$PremiumErrorCopyWithImpl<PremiumError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PremiumError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PremiumState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $PremiumErrorCopyWith<$Res> implements $PremiumStateCopyWith<$Res> {
  factory $PremiumErrorCopyWith(PremiumError value, $Res Function(PremiumError) _then) = _$PremiumErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$PremiumErrorCopyWithImpl<$Res>
    implements $PremiumErrorCopyWith<$Res> {
  _$PremiumErrorCopyWithImpl(this._self, this._then);

  final PremiumError _self;
  final $Res Function(PremiumError) _then;

/// Create a copy of PremiumState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PremiumError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PremiumPurchaseSuccess implements PremiumState {
  const PremiumPurchaseSuccess({required this.message});
  

 final  String message;

/// Create a copy of PremiumState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PremiumPurchaseSuccessCopyWith<PremiumPurchaseSuccess> get copyWith => _$PremiumPurchaseSuccessCopyWithImpl<PremiumPurchaseSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PremiumPurchaseSuccess&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PremiumState.purchaseSuccess(message: $message)';
}


}

/// @nodoc
abstract mixin class $PremiumPurchaseSuccessCopyWith<$Res> implements $PremiumStateCopyWith<$Res> {
  factory $PremiumPurchaseSuccessCopyWith(PremiumPurchaseSuccess value, $Res Function(PremiumPurchaseSuccess) _then) = _$PremiumPurchaseSuccessCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$PremiumPurchaseSuccessCopyWithImpl<$Res>
    implements $PremiumPurchaseSuccessCopyWith<$Res> {
  _$PremiumPurchaseSuccessCopyWithImpl(this._self, this._then);

  final PremiumPurchaseSuccess _self;
  final $Res Function(PremiumPurchaseSuccess) _then;

/// Create a copy of PremiumState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PremiumPurchaseSuccess(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PremiumPurchaseFailed implements PremiumState {
  const PremiumPurchaseFailed({required this.message});
  

 final  String message;

/// Create a copy of PremiumState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PremiumPurchaseFailedCopyWith<PremiumPurchaseFailed> get copyWith => _$PremiumPurchaseFailedCopyWithImpl<PremiumPurchaseFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PremiumPurchaseFailed&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PremiumState.purchaseFailed(message: $message)';
}


}

/// @nodoc
abstract mixin class $PremiumPurchaseFailedCopyWith<$Res> implements $PremiumStateCopyWith<$Res> {
  factory $PremiumPurchaseFailedCopyWith(PremiumPurchaseFailed value, $Res Function(PremiumPurchaseFailed) _then) = _$PremiumPurchaseFailedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$PremiumPurchaseFailedCopyWithImpl<$Res>
    implements $PremiumPurchaseFailedCopyWith<$Res> {
  _$PremiumPurchaseFailedCopyWithImpl(this._self, this._then);

  final PremiumPurchaseFailed _self;
  final $Res Function(PremiumPurchaseFailed) _then;

/// Create a copy of PremiumState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PremiumPurchaseFailed(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PremiumTrialStarted implements PremiumState {
  const PremiumTrialStarted({required this.message});
  

 final  String message;

/// Create a copy of PremiumState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PremiumTrialStartedCopyWith<PremiumTrialStarted> get copyWith => _$PremiumTrialStartedCopyWithImpl<PremiumTrialStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PremiumTrialStarted&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PremiumState.trialStarted(message: $message)';
}


}

/// @nodoc
abstract mixin class $PremiumTrialStartedCopyWith<$Res> implements $PremiumStateCopyWith<$Res> {
  factory $PremiumTrialStartedCopyWith(PremiumTrialStarted value, $Res Function(PremiumTrialStarted) _then) = _$PremiumTrialStartedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$PremiumTrialStartedCopyWithImpl<$Res>
    implements $PremiumTrialStartedCopyWith<$Res> {
  _$PremiumTrialStartedCopyWithImpl(this._self, this._then);

  final PremiumTrialStarted _self;
  final $Res Function(PremiumTrialStarted) _then;

/// Create a copy of PremiumState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PremiumTrialStarted(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PremiumTrialNotEligible implements PremiumState {
  const PremiumTrialNotEligible({required this.message});
  

 final  String message;

/// Create a copy of PremiumState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PremiumTrialNotEligibleCopyWith<PremiumTrialNotEligible> get copyWith => _$PremiumTrialNotEligibleCopyWithImpl<PremiumTrialNotEligible>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PremiumTrialNotEligible&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PremiumState.trialNotEligible(message: $message)';
}


}

/// @nodoc
abstract mixin class $PremiumTrialNotEligibleCopyWith<$Res> implements $PremiumStateCopyWith<$Res> {
  factory $PremiumTrialNotEligibleCopyWith(PremiumTrialNotEligible value, $Res Function(PremiumTrialNotEligible) _then) = _$PremiumTrialNotEligibleCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$PremiumTrialNotEligibleCopyWithImpl<$Res>
    implements $PremiumTrialNotEligibleCopyWith<$Res> {
  _$PremiumTrialNotEligibleCopyWithImpl(this._self, this._then);

  final PremiumTrialNotEligible _self;
  final $Res Function(PremiumTrialNotEligible) _then;

/// Create a copy of PremiumState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PremiumTrialNotEligible(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
