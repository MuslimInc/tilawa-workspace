// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'athkar_category_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AthkarCategoryModel {

 int get id;@JsonKey(name: 'name_ar') String get nameAr;@JsonKey(name: 'name_en') String get nameEn; String get icon;
/// Create a copy of AthkarCategoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AthkarCategoryModelCopyWith<AthkarCategoryModel> get copyWith => _$AthkarCategoryModelCopyWithImpl<AthkarCategoryModel>(this as AthkarCategoryModel, _$identity);

  /// Serializes this AthkarCategoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AthkarCategoryModel&&super == other&&(identical(other.id, id) || other.id == id)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.icon, icon) || other.icon == icon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,super.hashCode,id,nameAr,nameEn,icon);



}

/// @nodoc
abstract mixin class $AthkarCategoryModelCopyWith<$Res>  {
  factory $AthkarCategoryModelCopyWith(AthkarCategoryModel value, $Res Function(AthkarCategoryModel) _then) = _$AthkarCategoryModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'name_ar') String nameAr,@JsonKey(name: 'name_en') String nameEn, String icon
});




}
/// @nodoc
class _$AthkarCategoryModelCopyWithImpl<$Res>
    implements $AthkarCategoryModelCopyWith<$Res> {
  _$AthkarCategoryModelCopyWithImpl(this._self, this._then);

  final AthkarCategoryModel _self;
  final $Res Function(AthkarCategoryModel) _then;

/// Create a copy of AthkarCategoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nameAr = null,Object? nameEn = null,Object? icon = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AthkarCategoryModel].
extension AthkarCategoryModelPatterns on AthkarCategoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AthkarCategoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AthkarCategoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AthkarCategoryModel value)  $default,){
final _that = this;
switch (_that) {
case _AthkarCategoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AthkarCategoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _AthkarCategoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'name_ar')  String nameAr, @JsonKey(name: 'name_en')  String nameEn,  String icon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AthkarCategoryModel() when $default != null:
return $default(_that.id,_that.nameAr,_that.nameEn,_that.icon);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'name_ar')  String nameAr, @JsonKey(name: 'name_en')  String nameEn,  String icon)  $default,) {final _that = this;
switch (_that) {
case _AthkarCategoryModel():
return $default(_that.id,_that.nameAr,_that.nameEn,_that.icon);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'name_ar')  String nameAr, @JsonKey(name: 'name_en')  String nameEn,  String icon)?  $default,) {final _that = this;
switch (_that) {
case _AthkarCategoryModel() when $default != null:
return $default(_that.id,_that.nameAr,_that.nameEn,_that.icon);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AthkarCategoryModel extends AthkarCategoryModel {
  const _AthkarCategoryModel({required this.id, @JsonKey(name: 'name_ar') required this.nameAr, @JsonKey(name: 'name_en') required this.nameEn, required this.icon}): super._();
  factory _AthkarCategoryModel.fromJson(Map<String, dynamic> json) => _$AthkarCategoryModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'name_ar') final  String nameAr;
@override@JsonKey(name: 'name_en') final  String nameEn;
@override final  String icon;

/// Create a copy of AthkarCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AthkarCategoryModelCopyWith<_AthkarCategoryModel> get copyWith => __$AthkarCategoryModelCopyWithImpl<_AthkarCategoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AthkarCategoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AthkarCategoryModel&&super == other&&(identical(other.id, id) || other.id == id)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.icon, icon) || other.icon == icon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,super.hashCode,id,nameAr,nameEn,icon);



}

/// @nodoc
abstract mixin class _$AthkarCategoryModelCopyWith<$Res> implements $AthkarCategoryModelCopyWith<$Res> {
  factory _$AthkarCategoryModelCopyWith(_AthkarCategoryModel value, $Res Function(_AthkarCategoryModel) _then) = __$AthkarCategoryModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'name_ar') String nameAr,@JsonKey(name: 'name_en') String nameEn, String icon
});




}
/// @nodoc
class __$AthkarCategoryModelCopyWithImpl<$Res>
    implements _$AthkarCategoryModelCopyWith<$Res> {
  __$AthkarCategoryModelCopyWithImpl(this._self, this._then);

  final _AthkarCategoryModel _self;
  final $Res Function(_AthkarCategoryModel) _then;

/// Create a copy of AthkarCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nameAr = null,Object? nameEn = null,Object? icon = null,}) {
  return _then(_AthkarCategoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nameAr: null == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
