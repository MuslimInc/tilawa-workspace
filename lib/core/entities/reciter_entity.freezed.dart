// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reciter_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReciterEntity {

 int get id; String get name; String get letter; String get date; List<MoshafEntity> get moshaf;
/// Create a copy of ReciterEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReciterEntityCopyWith<ReciterEntity> get copyWith => _$ReciterEntityCopyWithImpl<ReciterEntity>(this as ReciterEntity, _$identity);

  /// Serializes this ReciterEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReciterEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.letter, letter) || other.letter == letter)&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.moshaf, moshaf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,letter,date,const DeepCollectionEquality().hash(moshaf));

@override
String toString() {
  return 'ReciterEntity(id: $id, name: $name, letter: $letter, date: $date, moshaf: $moshaf)';
}


}

/// @nodoc
abstract mixin class $ReciterEntityCopyWith<$Res>  {
  factory $ReciterEntityCopyWith(ReciterEntity value, $Res Function(ReciterEntity) _then) = _$ReciterEntityCopyWithImpl;
@useResult
$Res call({
 int id, String name, String letter, String date, List<MoshafEntity> moshaf
});




}
/// @nodoc
class _$ReciterEntityCopyWithImpl<$Res>
    implements $ReciterEntityCopyWith<$Res> {
  _$ReciterEntityCopyWithImpl(this._self, this._then);

  final ReciterEntity _self;
  final $Res Function(ReciterEntity) _then;

/// Create a copy of ReciterEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? letter = null,Object? date = null,Object? moshaf = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,letter: null == letter ? _self.letter : letter // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,moshaf: null == moshaf ? _self.moshaf : moshaf // ignore: cast_nullable_to_non_nullable
as List<MoshafEntity>,
  ));
}

}


/// Adds pattern-matching-related methods to [ReciterEntity].
extension ReciterEntityPatterns on ReciterEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReciterEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReciterEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReciterEntity value)  $default,){
final _that = this;
switch (_that) {
case _ReciterEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReciterEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ReciterEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String letter,  String date,  List<MoshafEntity> moshaf)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReciterEntity() when $default != null:
return $default(_that.id,_that.name,_that.letter,_that.date,_that.moshaf);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String letter,  String date,  List<MoshafEntity> moshaf)  $default,) {final _that = this;
switch (_that) {
case _ReciterEntity():
return $default(_that.id,_that.name,_that.letter,_that.date,_that.moshaf);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String letter,  String date,  List<MoshafEntity> moshaf)?  $default,) {final _that = this;
switch (_that) {
case _ReciterEntity() when $default != null:
return $default(_that.id,_that.name,_that.letter,_that.date,_that.moshaf);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReciterEntity implements ReciterEntity {
  const _ReciterEntity({required this.id, required this.name, required this.letter, required this.date, required final  List<MoshafEntity> moshaf}): _moshaf = moshaf;
  factory _ReciterEntity.fromJson(Map<String, dynamic> json) => _$ReciterEntityFromJson(json);

@override final  int id;
@override final  String name;
@override final  String letter;
@override final  String date;
 final  List<MoshafEntity> _moshaf;
@override List<MoshafEntity> get moshaf {
  if (_moshaf is EqualUnmodifiableListView) return _moshaf;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moshaf);
}


/// Create a copy of ReciterEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReciterEntityCopyWith<_ReciterEntity> get copyWith => __$ReciterEntityCopyWithImpl<_ReciterEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReciterEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReciterEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.letter, letter) || other.letter == letter)&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._moshaf, _moshaf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,letter,date,const DeepCollectionEquality().hash(_moshaf));

@override
String toString() {
  return 'ReciterEntity(id: $id, name: $name, letter: $letter, date: $date, moshaf: $moshaf)';
}


}

/// @nodoc
abstract mixin class _$ReciterEntityCopyWith<$Res> implements $ReciterEntityCopyWith<$Res> {
  factory _$ReciterEntityCopyWith(_ReciterEntity value, $Res Function(_ReciterEntity) _then) = __$ReciterEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String letter, String date, List<MoshafEntity> moshaf
});




}
/// @nodoc
class __$ReciterEntityCopyWithImpl<$Res>
    implements _$ReciterEntityCopyWith<$Res> {
  __$ReciterEntityCopyWithImpl(this._self, this._then);

  final _ReciterEntity _self;
  final $Res Function(_ReciterEntity) _then;

/// Create a copy of ReciterEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? letter = null,Object? date = null,Object? moshaf = null,}) {
  return _then(_ReciterEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,letter: null == letter ? _self.letter : letter // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,moshaf: null == moshaf ? _self._moshaf : moshaf // ignore: cast_nullable_to_non_nullable
as List<MoshafEntity>,
  ));
}


}

// dart format on
