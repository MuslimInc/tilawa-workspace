// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubscriptionPlan {
  String get id;
  String get name;
  String get description;
  double get price;
  String get currency;
  SubscriptionType get type;
  int get durationInDays;
  List<String> get features;
  bool get isPopular;
  double? get discountPercentage;
  int get order;

  /// Create a copy of SubscriptionPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SubscriptionPlanCopyWith<SubscriptionPlan> get copyWith =>
      _$SubscriptionPlanCopyWithImpl<SubscriptionPlan>(
        this as SubscriptionPlan,
        _$identity,
      );

  /// Serializes this SubscriptionPlan to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SubscriptionPlan &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.durationInDays, durationInDays) ||
                other.durationInDays == durationInDays) &&
            const DeepCollectionEquality().equals(other.features, features) &&
            (identical(other.isPopular, isPopular) ||
                other.isPopular == isPopular) &&
            (identical(other.discountPercentage, discountPercentage) ||
                other.discountPercentage == discountPercentage) &&
            (identical(other.order, order) || other.order == order));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    price,
    currency,
    type,
    durationInDays,
    const DeepCollectionEquality().hash(features),
    isPopular,
    discountPercentage,
    order,
  );

  @override
  String toString() {
    return 'SubscriptionPlan(id: $id, name: $name, description: $description, price: $price, currency: $currency, type: $type, durationInDays: $durationInDays, features: $features, isPopular: $isPopular, discountPercentage: $discountPercentage, order: $order)';
  }
}

/// @nodoc
abstract mixin class $SubscriptionPlanCopyWith<$Res> {
  factory $SubscriptionPlanCopyWith(
    SubscriptionPlan value,
    $Res Function(SubscriptionPlan) _then,
  ) = _$SubscriptionPlanCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    double price,
    String currency,
    SubscriptionType type,
    int durationInDays,
    List<String> features,
    bool isPopular,
    double? discountPercentage,
    int order,
  });
}

/// @nodoc
class _$SubscriptionPlanCopyWithImpl<$Res>
    implements $SubscriptionPlanCopyWith<$Res> {
  _$SubscriptionPlanCopyWithImpl(this._self, this._then);

  final SubscriptionPlan _self;
  final $Res Function(SubscriptionPlan) _then;

  /// Create a copy of SubscriptionPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? price = null,
    Object? currency = null,
    Object? type = null,
    Object? durationInDays = null,
    Object? features = null,
    Object? isPopular = null,
    Object? discountPercentage = freezed,
    Object? order = null,
  }) {
    return _then(
      _self.copyWith(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _self.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _self.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _self.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _self.type
            : type // ignore: cast_nullable_to_non_nullable
                  as SubscriptionType,
        durationInDays: null == durationInDays
            ? _self.durationInDays
            : durationInDays // ignore: cast_nullable_to_non_nullable
                  as int,
        features: null == features
            ? _self.features
            : features // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isPopular: null == isPopular
            ? _self.isPopular
            : isPopular // ignore: cast_nullable_to_non_nullable
                  as bool,
        discountPercentage: freezed == discountPercentage
            ? _self.discountPercentage
            : discountPercentage // ignore: cast_nullable_to_non_nullable
                  as double?,
        order: null == order
            ? _self.order
            : order // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SubscriptionPlan].
extension SubscriptionPlanPatterns on SubscriptionPlan {
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
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_SubscriptionPlan value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SubscriptionPlan() when $default != null:
        return $default(_that);
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
  TResult map<TResult extends Object?>(
    TResult Function(_SubscriptionPlan value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubscriptionPlan():
        return $default(_that);
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
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_SubscriptionPlan value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubscriptionPlan() when $default != null:
        return $default(_that);
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
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      String id,
      String name,
      String description,
      double price,
      String currency,
      SubscriptionType type,
      int durationInDays,
      List<String> features,
      bool isPopular,
      double? discountPercentage,
      int order,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SubscriptionPlan() when $default != null:
        return $default(
          _that.id,
          _that.name,
          _that.description,
          _that.price,
          _that.currency,
          _that.type,
          _that.durationInDays,
          _that.features,
          _that.isPopular,
          _that.discountPercentage,
          _that.order,
        );
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
  TResult when<TResult extends Object?>(
    TResult Function(
      String id,
      String name,
      String description,
      double price,
      String currency,
      SubscriptionType type,
      int durationInDays,
      List<String> features,
      bool isPopular,
      double? discountPercentage,
      int order,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubscriptionPlan():
        return $default(
          _that.id,
          _that.name,
          _that.description,
          _that.price,
          _that.currency,
          _that.type,
          _that.durationInDays,
          _that.features,
          _that.isPopular,
          _that.discountPercentage,
          _that.order,
        );
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
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      String id,
      String name,
      String description,
      double price,
      String currency,
      SubscriptionType type,
      int durationInDays,
      List<String> features,
      bool isPopular,
      double? discountPercentage,
      int order,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubscriptionPlan() when $default != null:
        return $default(
          _that.id,
          _that.name,
          _that.description,
          _that.price,
          _that.currency,
          _that.type,
          _that.durationInDays,
          _that.features,
          _that.isPopular,
          _that.discountPercentage,
          _that.order,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SubscriptionPlan implements SubscriptionPlan {
  const _SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.type,
    required this.durationInDays,
    required final List<String> features,
    required this.isPopular,
    required this.discountPercentage,
    this.order = 0,
  }) : _features = features;
  factory _SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final double price;
  @override
  final String currency;
  @override
  final SubscriptionType type;
  @override
  final int durationInDays;
  final List<String> _features;
  @override
  List<String> get features {
    if (_features is EqualUnmodifiableListView) return _features;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_features);
  }

  @override
  final bool isPopular;
  @override
  final double? discountPercentage;
  @override
  @JsonKey()
  final int order;

  /// Create a copy of SubscriptionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SubscriptionPlanCopyWith<_SubscriptionPlan> get copyWith =>
      __$SubscriptionPlanCopyWithImpl<_SubscriptionPlan>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SubscriptionPlanToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SubscriptionPlan &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.durationInDays, durationInDays) ||
                other.durationInDays == durationInDays) &&
            const DeepCollectionEquality().equals(other._features, _features) &&
            (identical(other.isPopular, isPopular) ||
                other.isPopular == isPopular) &&
            (identical(other.discountPercentage, discountPercentage) ||
                other.discountPercentage == discountPercentage) &&
            (identical(other.order, order) || other.order == order));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    price,
    currency,
    type,
    durationInDays,
    const DeepCollectionEquality().hash(_features),
    isPopular,
    discountPercentage,
    order,
  );

  @override
  String toString() {
    return 'SubscriptionPlan(id: $id, name: $name, description: $description, price: $price, currency: $currency, type: $type, durationInDays: $durationInDays, features: $features, isPopular: $isPopular, discountPercentage: $discountPercentage, order: $order)';
  }
}

/// @nodoc
abstract mixin class _$SubscriptionPlanCopyWith<$Res>
    implements $SubscriptionPlanCopyWith<$Res> {
  factory _$SubscriptionPlanCopyWith(
    _SubscriptionPlan value,
    $Res Function(_SubscriptionPlan) _then,
  ) = __$SubscriptionPlanCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String description,
    double price,
    String currency,
    SubscriptionType type,
    int durationInDays,
    List<String> features,
    bool isPopular,
    double? discountPercentage,
    int order,
  });
}

/// @nodoc
class __$SubscriptionPlanCopyWithImpl<$Res>
    implements _$SubscriptionPlanCopyWith<$Res> {
  __$SubscriptionPlanCopyWithImpl(this._self, this._then);

  final _SubscriptionPlan _self;
  final $Res Function(_SubscriptionPlan) _then;

  /// Create a copy of SubscriptionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? price = null,
    Object? currency = null,
    Object? type = null,
    Object? durationInDays = null,
    Object? features = null,
    Object? isPopular = null,
    Object? discountPercentage = freezed,
    Object? order = null,
  }) {
    return _then(
      _SubscriptionPlan(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _self.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _self.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _self.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _self.type
            : type // ignore: cast_nullable_to_non_nullable
                  as SubscriptionType,
        durationInDays: null == durationInDays
            ? _self.durationInDays
            : durationInDays // ignore: cast_nullable_to_non_nullable
                  as int,
        features: null == features
            ? _self._features
            : features // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isPopular: null == isPopular
            ? _self.isPopular
            : isPopular // ignore: cast_nullable_to_non_nullable
                  as bool,
        discountPercentage: freezed == discountPercentage
            ? _self.discountPercentage
            : discountPercentage // ignore: cast_nullable_to_non_nullable
                  as double?,
        order: null == order
            ? _self.order
            : order // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}
