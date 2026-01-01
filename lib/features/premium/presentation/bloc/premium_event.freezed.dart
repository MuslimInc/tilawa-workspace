// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'premium_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PremiumEvent {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is PremiumEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PremiumEvent()';
  }
}

/// @nodoc
class $PremiumEventCopyWith<$Res> {
  $PremiumEventCopyWith(PremiumEvent _, $Res Function(PremiumEvent) __);
}

/// Adds pattern-matching-related methods to [PremiumEvent].
extension PremiumEventPatterns on PremiumEvent {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadPremiumStatus value)? loadPremiumStatus,
    TResult Function(PurchaseSubscription value)? purchaseSubscription,
    TResult Function(CancelSubscription value)? cancelSubscription,
    TResult Function(RestoreSubscription value)? restoreSubscription,
    TResult Function(StartTrial value)? startTrial,
    TResult Function(LoadAvailablePlans value)? loadAvailablePlans,
    TResult Function(CheckFeatureAccess value)? checkFeatureAccess,
    TResult Function(RefreshPremiumStatus value)? refreshPremiumStatus,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case LoadPremiumStatus() when loadPremiumStatus != null:
        return loadPremiumStatus(_that);
      case PurchaseSubscription() when purchaseSubscription != null:
        return purchaseSubscription(_that);
      case CancelSubscription() when cancelSubscription != null:
        return cancelSubscription(_that);
      case RestoreSubscription() when restoreSubscription != null:
        return restoreSubscription(_that);
      case StartTrial() when startTrial != null:
        return startTrial(_that);
      case LoadAvailablePlans() when loadAvailablePlans != null:
        return loadAvailablePlans(_that);
      case CheckFeatureAccess() when checkFeatureAccess != null:
        return checkFeatureAccess(_that);
      case RefreshPremiumStatus() when refreshPremiumStatus != null:
        return refreshPremiumStatus(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadPremiumStatus value) loadPremiumStatus,
    required TResult Function(PurchaseSubscription value) purchaseSubscription,
    required TResult Function(CancelSubscription value) cancelSubscription,
    required TResult Function(RestoreSubscription value) restoreSubscription,
    required TResult Function(StartTrial value) startTrial,
    required TResult Function(LoadAvailablePlans value) loadAvailablePlans,
    required TResult Function(CheckFeatureAccess value) checkFeatureAccess,
    required TResult Function(RefreshPremiumStatus value) refreshPremiumStatus,
  }) {
    final _that = this;
    switch (_that) {
      case LoadPremiumStatus():
        return loadPremiumStatus(_that);
      case PurchaseSubscription():
        return purchaseSubscription(_that);
      case CancelSubscription():
        return cancelSubscription(_that);
      case RestoreSubscription():
        return restoreSubscription(_that);
      case StartTrial():
        return startTrial(_that);
      case LoadAvailablePlans():
        return loadAvailablePlans(_that);
      case CheckFeatureAccess():
        return checkFeatureAccess(_that);
      case RefreshPremiumStatus():
        return refreshPremiumStatus(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadPremiumStatus value)? loadPremiumStatus,
    TResult? Function(PurchaseSubscription value)? purchaseSubscription,
    TResult? Function(CancelSubscription value)? cancelSubscription,
    TResult? Function(RestoreSubscription value)? restoreSubscription,
    TResult? Function(StartTrial value)? startTrial,
    TResult? Function(LoadAvailablePlans value)? loadAvailablePlans,
    TResult? Function(CheckFeatureAccess value)? checkFeatureAccess,
    TResult? Function(RefreshPremiumStatus value)? refreshPremiumStatus,
  }) {
    final _that = this;
    switch (_that) {
      case LoadPremiumStatus() when loadPremiumStatus != null:
        return loadPremiumStatus(_that);
      case PurchaseSubscription() when purchaseSubscription != null:
        return purchaseSubscription(_that);
      case CancelSubscription() when cancelSubscription != null:
        return cancelSubscription(_that);
      case RestoreSubscription() when restoreSubscription != null:
        return restoreSubscription(_that);
      case StartTrial() when startTrial != null:
        return startTrial(_that);
      case LoadAvailablePlans() when loadAvailablePlans != null:
        return loadAvailablePlans(_that);
      case CheckFeatureAccess() when checkFeatureAccess != null:
        return checkFeatureAccess(_that);
      case RefreshPremiumStatus() when refreshPremiumStatus != null:
        return refreshPremiumStatus(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadPremiumStatus,
    TResult Function(String planId)? purchaseSubscription,
    TResult Function()? cancelSubscription,
    TResult Function()? restoreSubscription,
    TResult Function()? startTrial,
    TResult Function()? loadAvailablePlans,
    TResult Function(String featureName)? checkFeatureAccess,
    TResult Function()? refreshPremiumStatus,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case LoadPremiumStatus() when loadPremiumStatus != null:
        return loadPremiumStatus();
      case PurchaseSubscription() when purchaseSubscription != null:
        return purchaseSubscription(_that.planId);
      case CancelSubscription() when cancelSubscription != null:
        return cancelSubscription();
      case RestoreSubscription() when restoreSubscription != null:
        return restoreSubscription();
      case StartTrial() when startTrial != null:
        return startTrial();
      case LoadAvailablePlans() when loadAvailablePlans != null:
        return loadAvailablePlans();
      case CheckFeatureAccess() when checkFeatureAccess != null:
        return checkFeatureAccess(_that.featureName);
      case RefreshPremiumStatus() when refreshPremiumStatus != null:
        return refreshPremiumStatus();
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadPremiumStatus,
    required TResult Function(String planId) purchaseSubscription,
    required TResult Function() cancelSubscription,
    required TResult Function() restoreSubscription,
    required TResult Function() startTrial,
    required TResult Function() loadAvailablePlans,
    required TResult Function(String featureName) checkFeatureAccess,
    required TResult Function() refreshPremiumStatus,
  }) {
    final _that = this;
    switch (_that) {
      case LoadPremiumStatus():
        return loadPremiumStatus();
      case PurchaseSubscription():
        return purchaseSubscription(_that.planId);
      case CancelSubscription():
        return cancelSubscription();
      case RestoreSubscription():
        return restoreSubscription();
      case StartTrial():
        return startTrial();
      case LoadAvailablePlans():
        return loadAvailablePlans();
      case CheckFeatureAccess():
        return checkFeatureAccess(_that.featureName);
      case RefreshPremiumStatus():
        return refreshPremiumStatus();
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadPremiumStatus,
    TResult? Function(String planId)? purchaseSubscription,
    TResult? Function()? cancelSubscription,
    TResult? Function()? restoreSubscription,
    TResult? Function()? startTrial,
    TResult? Function()? loadAvailablePlans,
    TResult? Function(String featureName)? checkFeatureAccess,
    TResult? Function()? refreshPremiumStatus,
  }) {
    final _that = this;
    switch (_that) {
      case LoadPremiumStatus() when loadPremiumStatus != null:
        return loadPremiumStatus();
      case PurchaseSubscription() when purchaseSubscription != null:
        return purchaseSubscription(_that.planId);
      case CancelSubscription() when cancelSubscription != null:
        return cancelSubscription();
      case RestoreSubscription() when restoreSubscription != null:
        return restoreSubscription();
      case StartTrial() when startTrial != null:
        return startTrial();
      case LoadAvailablePlans() when loadAvailablePlans != null:
        return loadAvailablePlans();
      case CheckFeatureAccess() when checkFeatureAccess != null:
        return checkFeatureAccess(_that.featureName);
      case RefreshPremiumStatus() when refreshPremiumStatus != null:
        return refreshPremiumStatus();
      case _:
        return null;
    }
  }
}

/// @nodoc

class LoadPremiumStatus implements PremiumEvent {
  const LoadPremiumStatus();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is LoadPremiumStatus);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PremiumEvent.loadPremiumStatus()';
  }
}

/// @nodoc

class PurchaseSubscription implements PremiumEvent {
  const PurchaseSubscription({required this.planId});

  final String planId;

  /// Create a copy of PremiumEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PurchaseSubscriptionCopyWith<PurchaseSubscription> get copyWith =>
      _$PurchaseSubscriptionCopyWithImpl<PurchaseSubscription>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PurchaseSubscription &&
            (identical(other.planId, planId) || other.planId == planId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, planId);

  @override
  String toString() {
    return 'PremiumEvent.purchaseSubscription(planId: $planId)';
  }
}

/// @nodoc
abstract mixin class $PurchaseSubscriptionCopyWith<$Res>
    implements $PremiumEventCopyWith<$Res> {
  factory $PurchaseSubscriptionCopyWith(
    PurchaseSubscription value,
    $Res Function(PurchaseSubscription) _then,
  ) = _$PurchaseSubscriptionCopyWithImpl;
  @useResult
  $Res call({String planId});
}

/// @nodoc
class _$PurchaseSubscriptionCopyWithImpl<$Res>
    implements $PurchaseSubscriptionCopyWith<$Res> {
  _$PurchaseSubscriptionCopyWithImpl(this._self, this._then);

  final PurchaseSubscription _self;
  final $Res Function(PurchaseSubscription) _then;

  /// Create a copy of PremiumEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? planId = null}) {
    return _then(
      PurchaseSubscription(
        planId: null == planId
            ? _self.planId
            : planId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class CancelSubscription implements PremiumEvent {
  const CancelSubscription();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is CancelSubscription);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PremiumEvent.cancelSubscription()';
  }
}

/// @nodoc

class RestoreSubscription implements PremiumEvent {
  const RestoreSubscription();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is RestoreSubscription);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PremiumEvent.restoreSubscription()';
  }
}

/// @nodoc

class StartTrial implements PremiumEvent {
  const StartTrial();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is StartTrial);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PremiumEvent.startTrial()';
  }
}

/// @nodoc

class LoadAvailablePlans implements PremiumEvent {
  const LoadAvailablePlans();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is LoadAvailablePlans);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PremiumEvent.loadAvailablePlans()';
  }
}

/// @nodoc

class CheckFeatureAccess implements PremiumEvent {
  const CheckFeatureAccess({required this.featureName});

  final String featureName;

  /// Create a copy of PremiumEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CheckFeatureAccessCopyWith<CheckFeatureAccess> get copyWith =>
      _$CheckFeatureAccessCopyWithImpl<CheckFeatureAccess>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CheckFeatureAccess &&
            (identical(other.featureName, featureName) ||
                other.featureName == featureName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, featureName);

  @override
  String toString() {
    return 'PremiumEvent.checkFeatureAccess(featureName: $featureName)';
  }
}

/// @nodoc
abstract mixin class $CheckFeatureAccessCopyWith<$Res>
    implements $PremiumEventCopyWith<$Res> {
  factory $CheckFeatureAccessCopyWith(
    CheckFeatureAccess value,
    $Res Function(CheckFeatureAccess) _then,
  ) = _$CheckFeatureAccessCopyWithImpl;
  @useResult
  $Res call({String featureName});
}

/// @nodoc
class _$CheckFeatureAccessCopyWithImpl<$Res>
    implements $CheckFeatureAccessCopyWith<$Res> {
  _$CheckFeatureAccessCopyWithImpl(this._self, this._then);

  final CheckFeatureAccess _self;
  final $Res Function(CheckFeatureAccess) _then;

  /// Create a copy of PremiumEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? featureName = null}) {
    return _then(
      CheckFeatureAccess(
        featureName: null == featureName
            ? _self.featureName
            : featureName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class RefreshPremiumStatus implements PremiumEvent {
  const RefreshPremiumStatus();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is RefreshPremiumStatus);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'PremiumEvent.refreshPremiumStatus()';
  }
}
