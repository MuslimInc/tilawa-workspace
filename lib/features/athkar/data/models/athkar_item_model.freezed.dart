// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'athkar_item_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AthkarItemModel {

 int get id;@JsonKey(name: 'category_id') int get categoryId;@JsonKey(name: 'text_ar') String get textAr;@JsonKey(name: 'text_en') String get textEn; int get count; String get reference;
/// Create a copy of AthkarItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AthkarItemModelCopyWith<AthkarItemModel> get copyWith => _$AthkarItemModelCopyWithImpl<AthkarItemModel>(this as AthkarItemModel, _$identity);

  /// Serializes this AthkarItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AthkarItemModel&&super == other&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.textAr, textAr) || other.textAr == textAr)&&(identical(other.textEn, textEn) || other.textEn == textEn)&&(identical(other.count, count) || other.count == count)&&(identical(other.reference, reference) || other.reference == reference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,super.hashCode,id,categoryId,textAr,textEn,count,reference);



}

/// @nodoc
abstract mixin class $AthkarItemModelCopyWith<$Res>  {
  factory $AthkarItemModelCopyWith(AthkarItemModel value, $Res Function(AthkarItemModel) _then) = _$AthkarItemModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'category_id') int categoryId,@JsonKey(name: 'text_ar') String textAr,@JsonKey(name: 'text_en') String textEn, int count, String reference
});




}
/// @nodoc
class _$AthkarItemModelCopyWithImpl<$Res>
    implements $AthkarItemModelCopyWith<$Res> {
  _$AthkarItemModelCopyWithImpl(this._self, this._then);

  final AthkarItemModel _self;
  final $Res Function(AthkarItemModel) _then;

/// Create a copy of AthkarItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? categoryId = null,Object? textAr = null,Object? textEn = null,Object? count = null,Object? reference = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,textAr: null == textAr ? _self.textAr : textAr // ignore: cast_nullable_to_non_nullable
as String,textEn: null == textEn ? _self.textEn : textEn // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AthkarItemModel].
extension AthkarItemModelPatterns on AthkarItemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AthkarItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AthkarItemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AthkarItemModel value)  $default,){
final _that = this;
switch (_that) {
case _AthkarItemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AthkarItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _AthkarItemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'category_id')  int categoryId, @JsonKey(name: 'text_ar')  String textAr, @JsonKey(name: 'text_en')  String textEn,  int count,  String reference)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AthkarItemModel() when $default != null:
return $default(_that.id,_that.categoryId,_that.textAr,_that.textEn,_that.count,_that.reference);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'category_id')  int categoryId, @JsonKey(name: 'text_ar')  String textAr, @JsonKey(name: 'text_en')  String textEn,  int count,  String reference)  $default,) {final _that = this;
switch (_that) {
case _AthkarItemModel():
return $default(_that.id,_that.categoryId,_that.textAr,_that.textEn,_that.count,_that.reference);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'category_id')  int categoryId, @JsonKey(name: 'text_ar')  String textAr, @JsonKey(name: 'text_en')  String textEn,  int count,  String reference)?  $default,) {final _that = this;
switch (_that) {
case _AthkarItemModel() when $default != null:
return $default(_that.id,_that.categoryId,_that.textAr,_that.textEn,_that.count,_that.reference);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AthkarItemModel extends AthkarItemModel {
  const _AthkarItemModel({required this.id, @JsonKey(name: 'category_id') required this.categoryId, @JsonKey(name: 'text_ar') required this.textAr, @JsonKey(name: 'text_en') required this.textEn, required this.count, required this.reference}): super._();
  factory _AthkarItemModel.fromJson(Map<String, dynamic> json) => _$AthkarItemModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'category_id') final  int categoryId;
@override@JsonKey(name: 'text_ar') final  String textAr;
@override@JsonKey(name: 'text_en') final  String textEn;
@override final  int count;
@override final  String reference;

/// Create a copy of AthkarItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AthkarItemModelCopyWith<_AthkarItemModel> get copyWith => __$AthkarItemModelCopyWithImpl<_AthkarItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AthkarItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AthkarItemModel&&super == other&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.textAr, textAr) || other.textAr == textAr)&&(identical(other.textEn, textEn) || other.textEn == textEn)&&(identical(other.count, count) || other.count == count)&&(identical(other.reference, reference) || other.reference == reference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,super.hashCode,id,categoryId,textAr,textEn,count,reference);



}

/// @nodoc
abstract mixin class _$AthkarItemModelCopyWith<$Res> implements $AthkarItemModelCopyWith<$Res> {
  factory _$AthkarItemModelCopyWith(_AthkarItemModel value, $Res Function(_AthkarItemModel) _then) = __$AthkarItemModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'category_id') int categoryId,@JsonKey(name: 'text_ar') String textAr,@JsonKey(name: 'text_en') String textEn, int count, String reference
});




}
/// @nodoc
class __$AthkarItemModelCopyWithImpl<$Res>
    implements _$AthkarItemModelCopyWith<$Res> {
  __$AthkarItemModelCopyWithImpl(this._self, this._then);

  final _AthkarItemModel _self;
  final $Res Function(_AthkarItemModel) _then;

/// Create a copy of AthkarItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? categoryId = null,Object? textAr = null,Object? textEn = null,Object? count = null,Object? reference = null,}) {
  return _then(_AthkarItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,textAr: null == textAr ? _self.textAr : textAr // ignore: cast_nullable_to_non_nullable
as String,textEn: null == textEn ? _self.textEn : textEn // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
