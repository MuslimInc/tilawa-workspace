// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlists_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaylistsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistsEvent()';
}


}

/// @nodoc
class $PlaylistsEventCopyWith<$Res>  {
$PlaylistsEventCopyWith(PlaylistsEvent _, $Res Function(PlaylistsEvent) __);
}


/// Adds pattern-matching-related methods to [PlaylistsEvent].
extension PlaylistsEventPatterns on PlaylistsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LoadPlaylistsEvent value)?  loadPlaylists,TResult Function( CreatePlaylistEvent value)?  createPlaylist,TResult Function( UpdatePlaylistEvent value)?  updatePlaylist,TResult Function( DeletePlaylistEvent value)?  deletePlaylist,TResult Function( AddItemToPlaylistEvent value)?  addItemToPlaylist,TResult Function( RemoveItemFromPlaylistEvent value)?  removeItemFromPlaylist,TResult Function( ReorderPlaylistItemsEvent value)?  reorderPlaylistItems,TResult Function( SearchPlaylistsEvent value)?  searchPlaylists,TResult Function( ToggleFavoriteEvent value)?  toggleFavorite,TResult Function( DuplicatePlaylistEvent value)?  duplicatePlaylist,TResult Function( ClearSearchEvent value)?  clearSearch,TResult Function( RefreshPlaylistsEvent value)?  refreshPlaylists,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LoadPlaylistsEvent() when loadPlaylists != null:
return loadPlaylists(_that);case CreatePlaylistEvent() when createPlaylist != null:
return createPlaylist(_that);case UpdatePlaylistEvent() when updatePlaylist != null:
return updatePlaylist(_that);case DeletePlaylistEvent() when deletePlaylist != null:
return deletePlaylist(_that);case AddItemToPlaylistEvent() when addItemToPlaylist != null:
return addItemToPlaylist(_that);case RemoveItemFromPlaylistEvent() when removeItemFromPlaylist != null:
return removeItemFromPlaylist(_that);case ReorderPlaylistItemsEvent() when reorderPlaylistItems != null:
return reorderPlaylistItems(_that);case SearchPlaylistsEvent() when searchPlaylists != null:
return searchPlaylists(_that);case ToggleFavoriteEvent() when toggleFavorite != null:
return toggleFavorite(_that);case DuplicatePlaylistEvent() when duplicatePlaylist != null:
return duplicatePlaylist(_that);case ClearSearchEvent() when clearSearch != null:
return clearSearch(_that);case RefreshPlaylistsEvent() when refreshPlaylists != null:
return refreshPlaylists(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LoadPlaylistsEvent value)  loadPlaylists,required TResult Function( CreatePlaylistEvent value)  createPlaylist,required TResult Function( UpdatePlaylistEvent value)  updatePlaylist,required TResult Function( DeletePlaylistEvent value)  deletePlaylist,required TResult Function( AddItemToPlaylistEvent value)  addItemToPlaylist,required TResult Function( RemoveItemFromPlaylistEvent value)  removeItemFromPlaylist,required TResult Function( ReorderPlaylistItemsEvent value)  reorderPlaylistItems,required TResult Function( SearchPlaylistsEvent value)  searchPlaylists,required TResult Function( ToggleFavoriteEvent value)  toggleFavorite,required TResult Function( DuplicatePlaylistEvent value)  duplicatePlaylist,required TResult Function( ClearSearchEvent value)  clearSearch,required TResult Function( RefreshPlaylistsEvent value)  refreshPlaylists,}){
final _that = this;
switch (_that) {
case LoadPlaylistsEvent():
return loadPlaylists(_that);case CreatePlaylistEvent():
return createPlaylist(_that);case UpdatePlaylistEvent():
return updatePlaylist(_that);case DeletePlaylistEvent():
return deletePlaylist(_that);case AddItemToPlaylistEvent():
return addItemToPlaylist(_that);case RemoveItemFromPlaylistEvent():
return removeItemFromPlaylist(_that);case ReorderPlaylistItemsEvent():
return reorderPlaylistItems(_that);case SearchPlaylistsEvent():
return searchPlaylists(_that);case ToggleFavoriteEvent():
return toggleFavorite(_that);case DuplicatePlaylistEvent():
return duplicatePlaylist(_that);case ClearSearchEvent():
return clearSearch(_that);case RefreshPlaylistsEvent():
return refreshPlaylists(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LoadPlaylistsEvent value)?  loadPlaylists,TResult? Function( CreatePlaylistEvent value)?  createPlaylist,TResult? Function( UpdatePlaylistEvent value)?  updatePlaylist,TResult? Function( DeletePlaylistEvent value)?  deletePlaylist,TResult? Function( AddItemToPlaylistEvent value)?  addItemToPlaylist,TResult? Function( RemoveItemFromPlaylistEvent value)?  removeItemFromPlaylist,TResult? Function( ReorderPlaylistItemsEvent value)?  reorderPlaylistItems,TResult? Function( SearchPlaylistsEvent value)?  searchPlaylists,TResult? Function( ToggleFavoriteEvent value)?  toggleFavorite,TResult? Function( DuplicatePlaylistEvent value)?  duplicatePlaylist,TResult? Function( ClearSearchEvent value)?  clearSearch,TResult? Function( RefreshPlaylistsEvent value)?  refreshPlaylists,}){
final _that = this;
switch (_that) {
case LoadPlaylistsEvent() when loadPlaylists != null:
return loadPlaylists(_that);case CreatePlaylistEvent() when createPlaylist != null:
return createPlaylist(_that);case UpdatePlaylistEvent() when updatePlaylist != null:
return updatePlaylist(_that);case DeletePlaylistEvent() when deletePlaylist != null:
return deletePlaylist(_that);case AddItemToPlaylistEvent() when addItemToPlaylist != null:
return addItemToPlaylist(_that);case RemoveItemFromPlaylistEvent() when removeItemFromPlaylist != null:
return removeItemFromPlaylist(_that);case ReorderPlaylistItemsEvent() when reorderPlaylistItems != null:
return reorderPlaylistItems(_that);case SearchPlaylistsEvent() when searchPlaylists != null:
return searchPlaylists(_that);case ToggleFavoriteEvent() when toggleFavorite != null:
return toggleFavorite(_that);case DuplicatePlaylistEvent() when duplicatePlaylist != null:
return duplicatePlaylist(_that);case ClearSearchEvent() when clearSearch != null:
return clearSearch(_that);case RefreshPlaylistsEvent() when refreshPlaylists != null:
return refreshPlaylists(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadPlaylists,TResult Function( String name,  String description,  String? coverImageUrl,  bool isPublic)?  createPlaylist,TResult Function( String id,  String name,  String description,  String? coverImageUrl,  bool isPublic)?  updatePlaylist,TResult Function( String id)?  deletePlaylist,TResult Function( String playlistId,  PlaylistItem item)?  addItemToPlaylist,TResult Function( String playlistId,  String itemId)?  removeItemFromPlaylist,TResult Function( String playlistId,  int oldIndex,  int newIndex)?  reorderPlaylistItems,TResult Function( String query)?  searchPlaylists,TResult Function( String playlistId)?  toggleFavorite,TResult Function( String playlistId,  String newName)?  duplicatePlaylist,TResult Function()?  clearSearch,TResult Function()?  refreshPlaylists,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LoadPlaylistsEvent() when loadPlaylists != null:
return loadPlaylists();case CreatePlaylistEvent() when createPlaylist != null:
return createPlaylist(_that.name,_that.description,_that.coverImageUrl,_that.isPublic);case UpdatePlaylistEvent() when updatePlaylist != null:
return updatePlaylist(_that.id,_that.name,_that.description,_that.coverImageUrl,_that.isPublic);case DeletePlaylistEvent() when deletePlaylist != null:
return deletePlaylist(_that.id);case AddItemToPlaylistEvent() when addItemToPlaylist != null:
return addItemToPlaylist(_that.playlistId,_that.item);case RemoveItemFromPlaylistEvent() when removeItemFromPlaylist != null:
return removeItemFromPlaylist(_that.playlistId,_that.itemId);case ReorderPlaylistItemsEvent() when reorderPlaylistItems != null:
return reorderPlaylistItems(_that.playlistId,_that.oldIndex,_that.newIndex);case SearchPlaylistsEvent() when searchPlaylists != null:
return searchPlaylists(_that.query);case ToggleFavoriteEvent() when toggleFavorite != null:
return toggleFavorite(_that.playlistId);case DuplicatePlaylistEvent() when duplicatePlaylist != null:
return duplicatePlaylist(_that.playlistId,_that.newName);case ClearSearchEvent() when clearSearch != null:
return clearSearch();case RefreshPlaylistsEvent() when refreshPlaylists != null:
return refreshPlaylists();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadPlaylists,required TResult Function( String name,  String description,  String? coverImageUrl,  bool isPublic)  createPlaylist,required TResult Function( String id,  String name,  String description,  String? coverImageUrl,  bool isPublic)  updatePlaylist,required TResult Function( String id)  deletePlaylist,required TResult Function( String playlistId,  PlaylistItem item)  addItemToPlaylist,required TResult Function( String playlistId,  String itemId)  removeItemFromPlaylist,required TResult Function( String playlistId,  int oldIndex,  int newIndex)  reorderPlaylistItems,required TResult Function( String query)  searchPlaylists,required TResult Function( String playlistId)  toggleFavorite,required TResult Function( String playlistId,  String newName)  duplicatePlaylist,required TResult Function()  clearSearch,required TResult Function()  refreshPlaylists,}) {final _that = this;
switch (_that) {
case LoadPlaylistsEvent():
return loadPlaylists();case CreatePlaylistEvent():
return createPlaylist(_that.name,_that.description,_that.coverImageUrl,_that.isPublic);case UpdatePlaylistEvent():
return updatePlaylist(_that.id,_that.name,_that.description,_that.coverImageUrl,_that.isPublic);case DeletePlaylistEvent():
return deletePlaylist(_that.id);case AddItemToPlaylistEvent():
return addItemToPlaylist(_that.playlistId,_that.item);case RemoveItemFromPlaylistEvent():
return removeItemFromPlaylist(_that.playlistId,_that.itemId);case ReorderPlaylistItemsEvent():
return reorderPlaylistItems(_that.playlistId,_that.oldIndex,_that.newIndex);case SearchPlaylistsEvent():
return searchPlaylists(_that.query);case ToggleFavoriteEvent():
return toggleFavorite(_that.playlistId);case DuplicatePlaylistEvent():
return duplicatePlaylist(_that.playlistId,_that.newName);case ClearSearchEvent():
return clearSearch();case RefreshPlaylistsEvent():
return refreshPlaylists();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadPlaylists,TResult? Function( String name,  String description,  String? coverImageUrl,  bool isPublic)?  createPlaylist,TResult? Function( String id,  String name,  String description,  String? coverImageUrl,  bool isPublic)?  updatePlaylist,TResult? Function( String id)?  deletePlaylist,TResult? Function( String playlistId,  PlaylistItem item)?  addItemToPlaylist,TResult? Function( String playlistId,  String itemId)?  removeItemFromPlaylist,TResult? Function( String playlistId,  int oldIndex,  int newIndex)?  reorderPlaylistItems,TResult? Function( String query)?  searchPlaylists,TResult? Function( String playlistId)?  toggleFavorite,TResult? Function( String playlistId,  String newName)?  duplicatePlaylist,TResult? Function()?  clearSearch,TResult? Function()?  refreshPlaylists,}) {final _that = this;
switch (_that) {
case LoadPlaylistsEvent() when loadPlaylists != null:
return loadPlaylists();case CreatePlaylistEvent() when createPlaylist != null:
return createPlaylist(_that.name,_that.description,_that.coverImageUrl,_that.isPublic);case UpdatePlaylistEvent() when updatePlaylist != null:
return updatePlaylist(_that.id,_that.name,_that.description,_that.coverImageUrl,_that.isPublic);case DeletePlaylistEvent() when deletePlaylist != null:
return deletePlaylist(_that.id);case AddItemToPlaylistEvent() when addItemToPlaylist != null:
return addItemToPlaylist(_that.playlistId,_that.item);case RemoveItemFromPlaylistEvent() when removeItemFromPlaylist != null:
return removeItemFromPlaylist(_that.playlistId,_that.itemId);case ReorderPlaylistItemsEvent() when reorderPlaylistItems != null:
return reorderPlaylistItems(_that.playlistId,_that.oldIndex,_that.newIndex);case SearchPlaylistsEvent() when searchPlaylists != null:
return searchPlaylists(_that.query);case ToggleFavoriteEvent() when toggleFavorite != null:
return toggleFavorite(_that.playlistId);case DuplicatePlaylistEvent() when duplicatePlaylist != null:
return duplicatePlaylist(_that.playlistId,_that.newName);case ClearSearchEvent() when clearSearch != null:
return clearSearch();case RefreshPlaylistsEvent() when refreshPlaylists != null:
return refreshPlaylists();case _:
  return null;

}
}

}

/// @nodoc


class LoadPlaylistsEvent implements PlaylistsEvent {
  const LoadPlaylistsEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadPlaylistsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistsEvent.loadPlaylists()';
}


}




/// @nodoc


class CreatePlaylistEvent implements PlaylistsEvent {
  const CreatePlaylistEvent({required this.name, required this.description, this.coverImageUrl, this.isPublic = false});
  

 final  String name;
 final  String description;
 final  String? coverImageUrl;
@JsonKey() final  bool isPublic;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatePlaylistEventCopyWith<CreatePlaylistEvent> get copyWith => _$CreatePlaylistEventCopyWithImpl<CreatePlaylistEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatePlaylistEvent&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,coverImageUrl,isPublic);

@override
String toString() {
  return 'PlaylistsEvent.createPlaylist(name: $name, description: $description, coverImageUrl: $coverImageUrl, isPublic: $isPublic)';
}


}

/// @nodoc
abstract mixin class $CreatePlaylistEventCopyWith<$Res> implements $PlaylistsEventCopyWith<$Res> {
  factory $CreatePlaylistEventCopyWith(CreatePlaylistEvent value, $Res Function(CreatePlaylistEvent) _then) = _$CreatePlaylistEventCopyWithImpl;
@useResult
$Res call({
 String name, String description, String? coverImageUrl, bool isPublic
});




}
/// @nodoc
class _$CreatePlaylistEventCopyWithImpl<$Res>
    implements $CreatePlaylistEventCopyWith<$Res> {
  _$CreatePlaylistEventCopyWithImpl(this._self, this._then);

  final CreatePlaylistEvent _self;
  final $Res Function(CreatePlaylistEvent) _then;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,Object? coverImageUrl = freezed,Object? isPublic = null,}) {
  return _then(CreatePlaylistEvent(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class UpdatePlaylistEvent implements PlaylistsEvent {
  const UpdatePlaylistEvent({required this.id, required this.name, required this.description, this.coverImageUrl, this.isPublic = false});
  

 final  String id;
 final  String name;
 final  String description;
 final  String? coverImageUrl;
@JsonKey() final  bool isPublic;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdatePlaylistEventCopyWith<UpdatePlaylistEvent> get copyWith => _$UpdatePlaylistEventCopyWithImpl<UpdatePlaylistEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdatePlaylistEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,coverImageUrl,isPublic);

@override
String toString() {
  return 'PlaylistsEvent.updatePlaylist(id: $id, name: $name, description: $description, coverImageUrl: $coverImageUrl, isPublic: $isPublic)';
}


}

/// @nodoc
abstract mixin class $UpdatePlaylistEventCopyWith<$Res> implements $PlaylistsEventCopyWith<$Res> {
  factory $UpdatePlaylistEventCopyWith(UpdatePlaylistEvent value, $Res Function(UpdatePlaylistEvent) _then) = _$UpdatePlaylistEventCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, String? coverImageUrl, bool isPublic
});




}
/// @nodoc
class _$UpdatePlaylistEventCopyWithImpl<$Res>
    implements $UpdatePlaylistEventCopyWith<$Res> {
  _$UpdatePlaylistEventCopyWithImpl(this._self, this._then);

  final UpdatePlaylistEvent _self;
  final $Res Function(UpdatePlaylistEvent) _then;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? coverImageUrl = freezed,Object? isPublic = null,}) {
  return _then(UpdatePlaylistEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,isPublic: null == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class DeletePlaylistEvent implements PlaylistsEvent {
  const DeletePlaylistEvent(this.id);
  

 final  String id;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeletePlaylistEventCopyWith<DeletePlaylistEvent> get copyWith => _$DeletePlaylistEventCopyWithImpl<DeletePlaylistEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeletePlaylistEvent&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'PlaylistsEvent.deletePlaylist(id: $id)';
}


}

/// @nodoc
abstract mixin class $DeletePlaylistEventCopyWith<$Res> implements $PlaylistsEventCopyWith<$Res> {
  factory $DeletePlaylistEventCopyWith(DeletePlaylistEvent value, $Res Function(DeletePlaylistEvent) _then) = _$DeletePlaylistEventCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$DeletePlaylistEventCopyWithImpl<$Res>
    implements $DeletePlaylistEventCopyWith<$Res> {
  _$DeletePlaylistEventCopyWithImpl(this._self, this._then);

  final DeletePlaylistEvent _self;
  final $Res Function(DeletePlaylistEvent) _then;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(DeletePlaylistEvent(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AddItemToPlaylistEvent implements PlaylistsEvent {
  const AddItemToPlaylistEvent({required this.playlistId, required this.item});
  

 final  String playlistId;
 final  PlaylistItem item;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddItemToPlaylistEventCopyWith<AddItemToPlaylistEvent> get copyWith => _$AddItemToPlaylistEventCopyWithImpl<AddItemToPlaylistEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddItemToPlaylistEvent&&(identical(other.playlistId, playlistId) || other.playlistId == playlistId)&&(identical(other.item, item) || other.item == item));
}


@override
int get hashCode => Object.hash(runtimeType,playlistId,item);

@override
String toString() {
  return 'PlaylistsEvent.addItemToPlaylist(playlistId: $playlistId, item: $item)';
}


}

/// @nodoc
abstract mixin class $AddItemToPlaylistEventCopyWith<$Res> implements $PlaylistsEventCopyWith<$Res> {
  factory $AddItemToPlaylistEventCopyWith(AddItemToPlaylistEvent value, $Res Function(AddItemToPlaylistEvent) _then) = _$AddItemToPlaylistEventCopyWithImpl;
@useResult
$Res call({
 String playlistId, PlaylistItem item
});




}
/// @nodoc
class _$AddItemToPlaylistEventCopyWithImpl<$Res>
    implements $AddItemToPlaylistEventCopyWith<$Res> {
  _$AddItemToPlaylistEventCopyWithImpl(this._self, this._then);

  final AddItemToPlaylistEvent _self;
  final $Res Function(AddItemToPlaylistEvent) _then;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlistId = null,Object? item = null,}) {
  return _then(AddItemToPlaylistEvent(
playlistId: null == playlistId ? _self.playlistId : playlistId // ignore: cast_nullable_to_non_nullable
as String,item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as PlaylistItem,
  ));
}


}

/// @nodoc


class RemoveItemFromPlaylistEvent implements PlaylistsEvent {
  const RemoveItemFromPlaylistEvent({required this.playlistId, required this.itemId});
  

 final  String playlistId;
 final  String itemId;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RemoveItemFromPlaylistEventCopyWith<RemoveItemFromPlaylistEvent> get copyWith => _$RemoveItemFromPlaylistEventCopyWithImpl<RemoveItemFromPlaylistEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RemoveItemFromPlaylistEvent&&(identical(other.playlistId, playlistId) || other.playlistId == playlistId)&&(identical(other.itemId, itemId) || other.itemId == itemId));
}


@override
int get hashCode => Object.hash(runtimeType,playlistId,itemId);

@override
String toString() {
  return 'PlaylistsEvent.removeItemFromPlaylist(playlistId: $playlistId, itemId: $itemId)';
}


}

/// @nodoc
abstract mixin class $RemoveItemFromPlaylistEventCopyWith<$Res> implements $PlaylistsEventCopyWith<$Res> {
  factory $RemoveItemFromPlaylistEventCopyWith(RemoveItemFromPlaylistEvent value, $Res Function(RemoveItemFromPlaylistEvent) _then) = _$RemoveItemFromPlaylistEventCopyWithImpl;
@useResult
$Res call({
 String playlistId, String itemId
});




}
/// @nodoc
class _$RemoveItemFromPlaylistEventCopyWithImpl<$Res>
    implements $RemoveItemFromPlaylistEventCopyWith<$Res> {
  _$RemoveItemFromPlaylistEventCopyWithImpl(this._self, this._then);

  final RemoveItemFromPlaylistEvent _self;
  final $Res Function(RemoveItemFromPlaylistEvent) _then;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlistId = null,Object? itemId = null,}) {
  return _then(RemoveItemFromPlaylistEvent(
playlistId: null == playlistId ? _self.playlistId : playlistId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ReorderPlaylistItemsEvent implements PlaylistsEvent {
  const ReorderPlaylistItemsEvent({required this.playlistId, required this.oldIndex, required this.newIndex});
  

 final  String playlistId;
 final  int oldIndex;
 final  int newIndex;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReorderPlaylistItemsEventCopyWith<ReorderPlaylistItemsEvent> get copyWith => _$ReorderPlaylistItemsEventCopyWithImpl<ReorderPlaylistItemsEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReorderPlaylistItemsEvent&&(identical(other.playlistId, playlistId) || other.playlistId == playlistId)&&(identical(other.oldIndex, oldIndex) || other.oldIndex == oldIndex)&&(identical(other.newIndex, newIndex) || other.newIndex == newIndex));
}


@override
int get hashCode => Object.hash(runtimeType,playlistId,oldIndex,newIndex);

@override
String toString() {
  return 'PlaylistsEvent.reorderPlaylistItems(playlistId: $playlistId, oldIndex: $oldIndex, newIndex: $newIndex)';
}


}

/// @nodoc
abstract mixin class $ReorderPlaylistItemsEventCopyWith<$Res> implements $PlaylistsEventCopyWith<$Res> {
  factory $ReorderPlaylistItemsEventCopyWith(ReorderPlaylistItemsEvent value, $Res Function(ReorderPlaylistItemsEvent) _then) = _$ReorderPlaylistItemsEventCopyWithImpl;
@useResult
$Res call({
 String playlistId, int oldIndex, int newIndex
});




}
/// @nodoc
class _$ReorderPlaylistItemsEventCopyWithImpl<$Res>
    implements $ReorderPlaylistItemsEventCopyWith<$Res> {
  _$ReorderPlaylistItemsEventCopyWithImpl(this._self, this._then);

  final ReorderPlaylistItemsEvent _self;
  final $Res Function(ReorderPlaylistItemsEvent) _then;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlistId = null,Object? oldIndex = null,Object? newIndex = null,}) {
  return _then(ReorderPlaylistItemsEvent(
playlistId: null == playlistId ? _self.playlistId : playlistId // ignore: cast_nullable_to_non_nullable
as String,oldIndex: null == oldIndex ? _self.oldIndex : oldIndex // ignore: cast_nullable_to_non_nullable
as int,newIndex: null == newIndex ? _self.newIndex : newIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class SearchPlaylistsEvent implements PlaylistsEvent {
  const SearchPlaylistsEvent(this.query);
  

 final  String query;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchPlaylistsEventCopyWith<SearchPlaylistsEvent> get copyWith => _$SearchPlaylistsEventCopyWithImpl<SearchPlaylistsEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchPlaylistsEvent&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'PlaylistsEvent.searchPlaylists(query: $query)';
}


}

/// @nodoc
abstract mixin class $SearchPlaylistsEventCopyWith<$Res> implements $PlaylistsEventCopyWith<$Res> {
  factory $SearchPlaylistsEventCopyWith(SearchPlaylistsEvent value, $Res Function(SearchPlaylistsEvent) _then) = _$SearchPlaylistsEventCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class _$SearchPlaylistsEventCopyWithImpl<$Res>
    implements $SearchPlaylistsEventCopyWith<$Res> {
  _$SearchPlaylistsEventCopyWithImpl(this._self, this._then);

  final SearchPlaylistsEvent _self;
  final $Res Function(SearchPlaylistsEvent) _then;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(SearchPlaylistsEvent(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ToggleFavoriteEvent implements PlaylistsEvent {
  const ToggleFavoriteEvent(this.playlistId);
  

 final  String playlistId;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToggleFavoriteEventCopyWith<ToggleFavoriteEvent> get copyWith => _$ToggleFavoriteEventCopyWithImpl<ToggleFavoriteEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToggleFavoriteEvent&&(identical(other.playlistId, playlistId) || other.playlistId == playlistId));
}


@override
int get hashCode => Object.hash(runtimeType,playlistId);

@override
String toString() {
  return 'PlaylistsEvent.toggleFavorite(playlistId: $playlistId)';
}


}

/// @nodoc
abstract mixin class $ToggleFavoriteEventCopyWith<$Res> implements $PlaylistsEventCopyWith<$Res> {
  factory $ToggleFavoriteEventCopyWith(ToggleFavoriteEvent value, $Res Function(ToggleFavoriteEvent) _then) = _$ToggleFavoriteEventCopyWithImpl;
@useResult
$Res call({
 String playlistId
});




}
/// @nodoc
class _$ToggleFavoriteEventCopyWithImpl<$Res>
    implements $ToggleFavoriteEventCopyWith<$Res> {
  _$ToggleFavoriteEventCopyWithImpl(this._self, this._then);

  final ToggleFavoriteEvent _self;
  final $Res Function(ToggleFavoriteEvent) _then;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlistId = null,}) {
  return _then(ToggleFavoriteEvent(
null == playlistId ? _self.playlistId : playlistId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DuplicatePlaylistEvent implements PlaylistsEvent {
  const DuplicatePlaylistEvent({required this.playlistId, required this.newName});
  

 final  String playlistId;
 final  String newName;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuplicatePlaylistEventCopyWith<DuplicatePlaylistEvent> get copyWith => _$DuplicatePlaylistEventCopyWithImpl<DuplicatePlaylistEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DuplicatePlaylistEvent&&(identical(other.playlistId, playlistId) || other.playlistId == playlistId)&&(identical(other.newName, newName) || other.newName == newName));
}


@override
int get hashCode => Object.hash(runtimeType,playlistId,newName);

@override
String toString() {
  return 'PlaylistsEvent.duplicatePlaylist(playlistId: $playlistId, newName: $newName)';
}


}

/// @nodoc
abstract mixin class $DuplicatePlaylistEventCopyWith<$Res> implements $PlaylistsEventCopyWith<$Res> {
  factory $DuplicatePlaylistEventCopyWith(DuplicatePlaylistEvent value, $Res Function(DuplicatePlaylistEvent) _then) = _$DuplicatePlaylistEventCopyWithImpl;
@useResult
$Res call({
 String playlistId, String newName
});




}
/// @nodoc
class _$DuplicatePlaylistEventCopyWithImpl<$Res>
    implements $DuplicatePlaylistEventCopyWith<$Res> {
  _$DuplicatePlaylistEventCopyWithImpl(this._self, this._then);

  final DuplicatePlaylistEvent _self;
  final $Res Function(DuplicatePlaylistEvent) _then;

/// Create a copy of PlaylistsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlistId = null,Object? newName = null,}) {
  return _then(DuplicatePlaylistEvent(
playlistId: null == playlistId ? _self.playlistId : playlistId // ignore: cast_nullable_to_non_nullable
as String,newName: null == newName ? _self.newName : newName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ClearSearchEvent implements PlaylistsEvent {
  const ClearSearchEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClearSearchEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistsEvent.clearSearch()';
}


}




/// @nodoc


class RefreshPlaylistsEvent implements PlaylistsEvent {
  const RefreshPlaylistsEvent();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefreshPlaylistsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistsEvent.refreshPlaylists()';
}


}




/// @nodoc
mixin _$PlaylistsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistsState()';
}


}

/// @nodoc
class $PlaylistsStateCopyWith<$Res>  {
$PlaylistsStateCopyWith(PlaylistsState _, $Res Function(PlaylistsState) __);
}


/// Adds pattern-matching-related methods to [PlaylistsState].
extension PlaylistsStatePatterns on PlaylistsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlaylistsInitial value)?  initial,TResult Function( PlaylistsLoading value)?  loading,TResult Function( PlaylistsLoaded value)?  loaded,TResult Function( PlaylistsError value)?  error,TResult Function( PlaylistCreated value)?  playlistCreated,TResult Function( PlaylistUpdated value)?  playlistUpdated,TResult Function( PlaylistDeleted value)?  playlistDeleted,TResult Function( ItemAdded value)?  itemAdded,TResult Function( ItemRemoved value)?  itemRemoved,TResult Function( ItemsReordered value)?  itemsReordered,TResult Function( PlaylistDuplicated value)?  playlistDuplicated,TResult Function( FavoriteToggled value)?  favoriteToggled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlaylistsInitial() when initial != null:
return initial(_that);case PlaylistsLoading() when loading != null:
return loading(_that);case PlaylistsLoaded() when loaded != null:
return loaded(_that);case PlaylistsError() when error != null:
return error(_that);case PlaylistCreated() when playlistCreated != null:
return playlistCreated(_that);case PlaylistUpdated() when playlistUpdated != null:
return playlistUpdated(_that);case PlaylistDeleted() when playlistDeleted != null:
return playlistDeleted(_that);case ItemAdded() when itemAdded != null:
return itemAdded(_that);case ItemRemoved() when itemRemoved != null:
return itemRemoved(_that);case ItemsReordered() when itemsReordered != null:
return itemsReordered(_that);case PlaylistDuplicated() when playlistDuplicated != null:
return playlistDuplicated(_that);case FavoriteToggled() when favoriteToggled != null:
return favoriteToggled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlaylistsInitial value)  initial,required TResult Function( PlaylistsLoading value)  loading,required TResult Function( PlaylistsLoaded value)  loaded,required TResult Function( PlaylistsError value)  error,required TResult Function( PlaylistCreated value)  playlistCreated,required TResult Function( PlaylistUpdated value)  playlistUpdated,required TResult Function( PlaylistDeleted value)  playlistDeleted,required TResult Function( ItemAdded value)  itemAdded,required TResult Function( ItemRemoved value)  itemRemoved,required TResult Function( ItemsReordered value)  itemsReordered,required TResult Function( PlaylistDuplicated value)  playlistDuplicated,required TResult Function( FavoriteToggled value)  favoriteToggled,}){
final _that = this;
switch (_that) {
case PlaylistsInitial():
return initial(_that);case PlaylistsLoading():
return loading(_that);case PlaylistsLoaded():
return loaded(_that);case PlaylistsError():
return error(_that);case PlaylistCreated():
return playlistCreated(_that);case PlaylistUpdated():
return playlistUpdated(_that);case PlaylistDeleted():
return playlistDeleted(_that);case ItemAdded():
return itemAdded(_that);case ItemRemoved():
return itemRemoved(_that);case ItemsReordered():
return itemsReordered(_that);case PlaylistDuplicated():
return playlistDuplicated(_that);case FavoriteToggled():
return favoriteToggled(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlaylistsInitial value)?  initial,TResult? Function( PlaylistsLoading value)?  loading,TResult? Function( PlaylistsLoaded value)?  loaded,TResult? Function( PlaylistsError value)?  error,TResult? Function( PlaylistCreated value)?  playlistCreated,TResult? Function( PlaylistUpdated value)?  playlistUpdated,TResult? Function( PlaylistDeleted value)?  playlistDeleted,TResult? Function( ItemAdded value)?  itemAdded,TResult? Function( ItemRemoved value)?  itemRemoved,TResult? Function( ItemsReordered value)?  itemsReordered,TResult? Function( PlaylistDuplicated value)?  playlistDuplicated,TResult? Function( FavoriteToggled value)?  favoriteToggled,}){
final _that = this;
switch (_that) {
case PlaylistsInitial() when initial != null:
return initial(_that);case PlaylistsLoading() when loading != null:
return loading(_that);case PlaylistsLoaded() when loaded != null:
return loaded(_that);case PlaylistsError() when error != null:
return error(_that);case PlaylistCreated() when playlistCreated != null:
return playlistCreated(_that);case PlaylistUpdated() when playlistUpdated != null:
return playlistUpdated(_that);case PlaylistDeleted() when playlistDeleted != null:
return playlistDeleted(_that);case ItemAdded() when itemAdded != null:
return itemAdded(_that);case ItemRemoved() when itemRemoved != null:
return itemRemoved(_that);case ItemsReordered() when itemsReordered != null:
return itemsReordered(_that);case PlaylistDuplicated() when playlistDuplicated != null:
return playlistDuplicated(_that);case FavoriteToggled() when favoriteToggled != null:
return favoriteToggled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Playlist> playlists,  String searchQuery,  List<Playlist> filteredPlaylists)?  loaded,TResult Function( String message)?  error,TResult Function( Playlist playlist,  List<Playlist> playlists)?  playlistCreated,TResult Function( Playlist playlist,  List<Playlist> playlists)?  playlistUpdated,TResult Function( String playlistId,  List<Playlist> playlists)?  playlistDeleted,TResult Function( Playlist playlist,  List<Playlist> playlists)?  itemAdded,TResult Function( Playlist playlist,  List<Playlist> playlists)?  itemRemoved,TResult Function( Playlist playlist,  List<Playlist> playlists)?  itemsReordered,TResult Function( Playlist playlist,  List<Playlist> playlists)?  playlistDuplicated,TResult Function( Playlist playlist,  List<Playlist> playlists)?  favoriteToggled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlaylistsInitial() when initial != null:
return initial();case PlaylistsLoading() when loading != null:
return loading();case PlaylistsLoaded() when loaded != null:
return loaded(_that.playlists,_that.searchQuery,_that.filteredPlaylists);case PlaylistsError() when error != null:
return error(_that.message);case PlaylistCreated() when playlistCreated != null:
return playlistCreated(_that.playlist,_that.playlists);case PlaylistUpdated() when playlistUpdated != null:
return playlistUpdated(_that.playlist,_that.playlists);case PlaylistDeleted() when playlistDeleted != null:
return playlistDeleted(_that.playlistId,_that.playlists);case ItemAdded() when itemAdded != null:
return itemAdded(_that.playlist,_that.playlists);case ItemRemoved() when itemRemoved != null:
return itemRemoved(_that.playlist,_that.playlists);case ItemsReordered() when itemsReordered != null:
return itemsReordered(_that.playlist,_that.playlists);case PlaylistDuplicated() when playlistDuplicated != null:
return playlistDuplicated(_that.playlist,_that.playlists);case FavoriteToggled() when favoriteToggled != null:
return favoriteToggled(_that.playlist,_that.playlists);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Playlist> playlists,  String searchQuery,  List<Playlist> filteredPlaylists)  loaded,required TResult Function( String message)  error,required TResult Function( Playlist playlist,  List<Playlist> playlists)  playlistCreated,required TResult Function( Playlist playlist,  List<Playlist> playlists)  playlistUpdated,required TResult Function( String playlistId,  List<Playlist> playlists)  playlistDeleted,required TResult Function( Playlist playlist,  List<Playlist> playlists)  itemAdded,required TResult Function( Playlist playlist,  List<Playlist> playlists)  itemRemoved,required TResult Function( Playlist playlist,  List<Playlist> playlists)  itemsReordered,required TResult Function( Playlist playlist,  List<Playlist> playlists)  playlistDuplicated,required TResult Function( Playlist playlist,  List<Playlist> playlists)  favoriteToggled,}) {final _that = this;
switch (_that) {
case PlaylistsInitial():
return initial();case PlaylistsLoading():
return loading();case PlaylistsLoaded():
return loaded(_that.playlists,_that.searchQuery,_that.filteredPlaylists);case PlaylistsError():
return error(_that.message);case PlaylistCreated():
return playlistCreated(_that.playlist,_that.playlists);case PlaylistUpdated():
return playlistUpdated(_that.playlist,_that.playlists);case PlaylistDeleted():
return playlistDeleted(_that.playlistId,_that.playlists);case ItemAdded():
return itemAdded(_that.playlist,_that.playlists);case ItemRemoved():
return itemRemoved(_that.playlist,_that.playlists);case ItemsReordered():
return itemsReordered(_that.playlist,_that.playlists);case PlaylistDuplicated():
return playlistDuplicated(_that.playlist,_that.playlists);case FavoriteToggled():
return favoriteToggled(_that.playlist,_that.playlists);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Playlist> playlists,  String searchQuery,  List<Playlist> filteredPlaylists)?  loaded,TResult? Function( String message)?  error,TResult? Function( Playlist playlist,  List<Playlist> playlists)?  playlistCreated,TResult? Function( Playlist playlist,  List<Playlist> playlists)?  playlistUpdated,TResult? Function( String playlistId,  List<Playlist> playlists)?  playlistDeleted,TResult? Function( Playlist playlist,  List<Playlist> playlists)?  itemAdded,TResult? Function( Playlist playlist,  List<Playlist> playlists)?  itemRemoved,TResult? Function( Playlist playlist,  List<Playlist> playlists)?  itemsReordered,TResult? Function( Playlist playlist,  List<Playlist> playlists)?  playlistDuplicated,TResult? Function( Playlist playlist,  List<Playlist> playlists)?  favoriteToggled,}) {final _that = this;
switch (_that) {
case PlaylistsInitial() when initial != null:
return initial();case PlaylistsLoading() when loading != null:
return loading();case PlaylistsLoaded() when loaded != null:
return loaded(_that.playlists,_that.searchQuery,_that.filteredPlaylists);case PlaylistsError() when error != null:
return error(_that.message);case PlaylistCreated() when playlistCreated != null:
return playlistCreated(_that.playlist,_that.playlists);case PlaylistUpdated() when playlistUpdated != null:
return playlistUpdated(_that.playlist,_that.playlists);case PlaylistDeleted() when playlistDeleted != null:
return playlistDeleted(_that.playlistId,_that.playlists);case ItemAdded() when itemAdded != null:
return itemAdded(_that.playlist,_that.playlists);case ItemRemoved() when itemRemoved != null:
return itemRemoved(_that.playlist,_that.playlists);case ItemsReordered() when itemsReordered != null:
return itemsReordered(_that.playlist,_that.playlists);case PlaylistDuplicated() when playlistDuplicated != null:
return playlistDuplicated(_that.playlist,_that.playlists);case FavoriteToggled() when favoriteToggled != null:
return favoriteToggled(_that.playlist,_that.playlists);case _:
  return null;

}
}

}

/// @nodoc


class PlaylistsInitial implements PlaylistsState {
  const PlaylistsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistsState.initial()';
}


}




/// @nodoc


class PlaylistsLoading implements PlaylistsState {
  const PlaylistsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistsState.loading()';
}


}




/// @nodoc


class PlaylistsLoaded implements PlaylistsState {
  const PlaylistsLoaded({required final  List<Playlist> playlists, this.searchQuery = '', final  List<Playlist> filteredPlaylists = const []}): _playlists = playlists,_filteredPlaylists = filteredPlaylists;
  

 final  List<Playlist> _playlists;
 List<Playlist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}

@JsonKey() final  String searchQuery;
 final  List<Playlist> _filteredPlaylists;
@JsonKey() List<Playlist> get filteredPlaylists {
  if (_filteredPlaylists is EqualUnmodifiableListView) return _filteredPlaylists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_filteredPlaylists);
}


/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistsLoadedCopyWith<PlaylistsLoaded> get copyWith => _$PlaylistsLoadedCopyWithImpl<PlaylistsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistsLoaded&&const DeepCollectionEquality().equals(other._playlists, _playlists)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&const DeepCollectionEquality().equals(other._filteredPlaylists, _filteredPlaylists));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_playlists),searchQuery,const DeepCollectionEquality().hash(_filteredPlaylists));

@override
String toString() {
  return 'PlaylistsState.loaded(playlists: $playlists, searchQuery: $searchQuery, filteredPlaylists: $filteredPlaylists)';
}


}

/// @nodoc
abstract mixin class $PlaylistsLoadedCopyWith<$Res> implements $PlaylistsStateCopyWith<$Res> {
  factory $PlaylistsLoadedCopyWith(PlaylistsLoaded value, $Res Function(PlaylistsLoaded) _then) = _$PlaylistsLoadedCopyWithImpl;
@useResult
$Res call({
 List<Playlist> playlists, String searchQuery, List<Playlist> filteredPlaylists
});




}
/// @nodoc
class _$PlaylistsLoadedCopyWithImpl<$Res>
    implements $PlaylistsLoadedCopyWith<$Res> {
  _$PlaylistsLoadedCopyWithImpl(this._self, this._then);

  final PlaylistsLoaded _self;
  final $Res Function(PlaylistsLoaded) _then;

/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlists = null,Object? searchQuery = null,Object? filteredPlaylists = null,}) {
  return _then(PlaylistsLoaded(
playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,filteredPlaylists: null == filteredPlaylists ? _self._filteredPlaylists : filteredPlaylists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}


}

/// @nodoc


class PlaylistsError implements PlaylistsState {
  const PlaylistsError(this.message);
  

 final  String message;

/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistsErrorCopyWith<PlaylistsError> get copyWith => _$PlaylistsErrorCopyWithImpl<PlaylistsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistsError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PlaylistsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $PlaylistsErrorCopyWith<$Res> implements $PlaylistsStateCopyWith<$Res> {
  factory $PlaylistsErrorCopyWith(PlaylistsError value, $Res Function(PlaylistsError) _then) = _$PlaylistsErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$PlaylistsErrorCopyWithImpl<$Res>
    implements $PlaylistsErrorCopyWith<$Res> {
  _$PlaylistsErrorCopyWithImpl(this._self, this._then);

  final PlaylistsError _self;
  final $Res Function(PlaylistsError) _then;

/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(PlaylistsError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class PlaylistCreated implements PlaylistsState {
  const PlaylistCreated({required this.playlist, required final  List<Playlist> playlists}): _playlists = playlists;
  

 final  Playlist playlist;
 final  List<Playlist> _playlists;
 List<Playlist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}


/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistCreatedCopyWith<PlaylistCreated> get copyWith => _$PlaylistCreatedCopyWithImpl<PlaylistCreated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistCreated&&(identical(other.playlist, playlist) || other.playlist == playlist)&&const DeepCollectionEquality().equals(other._playlists, _playlists));
}


@override
int get hashCode => Object.hash(runtimeType,playlist,const DeepCollectionEquality().hash(_playlists));

@override
String toString() {
  return 'PlaylistsState.playlistCreated(playlist: $playlist, playlists: $playlists)';
}


}

/// @nodoc
abstract mixin class $PlaylistCreatedCopyWith<$Res> implements $PlaylistsStateCopyWith<$Res> {
  factory $PlaylistCreatedCopyWith(PlaylistCreated value, $Res Function(PlaylistCreated) _then) = _$PlaylistCreatedCopyWithImpl;
@useResult
$Res call({
 Playlist playlist, List<Playlist> playlists
});




}
/// @nodoc
class _$PlaylistCreatedCopyWithImpl<$Res>
    implements $PlaylistCreatedCopyWith<$Res> {
  _$PlaylistCreatedCopyWithImpl(this._self, this._then);

  final PlaylistCreated _self;
  final $Res Function(PlaylistCreated) _then;

/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlist = null,Object? playlists = null,}) {
  return _then(PlaylistCreated(
playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as Playlist,playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}


}

/// @nodoc


class PlaylistUpdated implements PlaylistsState {
  const PlaylistUpdated({required this.playlist, required final  List<Playlist> playlists}): _playlists = playlists;
  

 final  Playlist playlist;
 final  List<Playlist> _playlists;
 List<Playlist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}


/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistUpdatedCopyWith<PlaylistUpdated> get copyWith => _$PlaylistUpdatedCopyWithImpl<PlaylistUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistUpdated&&(identical(other.playlist, playlist) || other.playlist == playlist)&&const DeepCollectionEquality().equals(other._playlists, _playlists));
}


@override
int get hashCode => Object.hash(runtimeType,playlist,const DeepCollectionEquality().hash(_playlists));

@override
String toString() {
  return 'PlaylistsState.playlistUpdated(playlist: $playlist, playlists: $playlists)';
}


}

/// @nodoc
abstract mixin class $PlaylistUpdatedCopyWith<$Res> implements $PlaylistsStateCopyWith<$Res> {
  factory $PlaylistUpdatedCopyWith(PlaylistUpdated value, $Res Function(PlaylistUpdated) _then) = _$PlaylistUpdatedCopyWithImpl;
@useResult
$Res call({
 Playlist playlist, List<Playlist> playlists
});




}
/// @nodoc
class _$PlaylistUpdatedCopyWithImpl<$Res>
    implements $PlaylistUpdatedCopyWith<$Res> {
  _$PlaylistUpdatedCopyWithImpl(this._self, this._then);

  final PlaylistUpdated _self;
  final $Res Function(PlaylistUpdated) _then;

/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlist = null,Object? playlists = null,}) {
  return _then(PlaylistUpdated(
playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as Playlist,playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}


}

/// @nodoc


class PlaylistDeleted implements PlaylistsState {
  const PlaylistDeleted({required this.playlistId, required final  List<Playlist> playlists}): _playlists = playlists;
  

 final  String playlistId;
 final  List<Playlist> _playlists;
 List<Playlist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}


/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistDeletedCopyWith<PlaylistDeleted> get copyWith => _$PlaylistDeletedCopyWithImpl<PlaylistDeleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistDeleted&&(identical(other.playlistId, playlistId) || other.playlistId == playlistId)&&const DeepCollectionEquality().equals(other._playlists, _playlists));
}


@override
int get hashCode => Object.hash(runtimeType,playlistId,const DeepCollectionEquality().hash(_playlists));

@override
String toString() {
  return 'PlaylistsState.playlistDeleted(playlistId: $playlistId, playlists: $playlists)';
}


}

/// @nodoc
abstract mixin class $PlaylistDeletedCopyWith<$Res> implements $PlaylistsStateCopyWith<$Res> {
  factory $PlaylistDeletedCopyWith(PlaylistDeleted value, $Res Function(PlaylistDeleted) _then) = _$PlaylistDeletedCopyWithImpl;
@useResult
$Res call({
 String playlistId, List<Playlist> playlists
});




}
/// @nodoc
class _$PlaylistDeletedCopyWithImpl<$Res>
    implements $PlaylistDeletedCopyWith<$Res> {
  _$PlaylistDeletedCopyWithImpl(this._self, this._then);

  final PlaylistDeleted _self;
  final $Res Function(PlaylistDeleted) _then;

/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlistId = null,Object? playlists = null,}) {
  return _then(PlaylistDeleted(
playlistId: null == playlistId ? _self.playlistId : playlistId // ignore: cast_nullable_to_non_nullable
as String,playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}


}

/// @nodoc


class ItemAdded implements PlaylistsState {
  const ItemAdded({required this.playlist, required final  List<Playlist> playlists}): _playlists = playlists;
  

 final  Playlist playlist;
 final  List<Playlist> _playlists;
 List<Playlist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}


/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemAddedCopyWith<ItemAdded> get copyWith => _$ItemAddedCopyWithImpl<ItemAdded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemAdded&&(identical(other.playlist, playlist) || other.playlist == playlist)&&const DeepCollectionEquality().equals(other._playlists, _playlists));
}


@override
int get hashCode => Object.hash(runtimeType,playlist,const DeepCollectionEquality().hash(_playlists));

@override
String toString() {
  return 'PlaylistsState.itemAdded(playlist: $playlist, playlists: $playlists)';
}


}

/// @nodoc
abstract mixin class $ItemAddedCopyWith<$Res> implements $PlaylistsStateCopyWith<$Res> {
  factory $ItemAddedCopyWith(ItemAdded value, $Res Function(ItemAdded) _then) = _$ItemAddedCopyWithImpl;
@useResult
$Res call({
 Playlist playlist, List<Playlist> playlists
});




}
/// @nodoc
class _$ItemAddedCopyWithImpl<$Res>
    implements $ItemAddedCopyWith<$Res> {
  _$ItemAddedCopyWithImpl(this._self, this._then);

  final ItemAdded _self;
  final $Res Function(ItemAdded) _then;

/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlist = null,Object? playlists = null,}) {
  return _then(ItemAdded(
playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as Playlist,playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}


}

/// @nodoc


class ItemRemoved implements PlaylistsState {
  const ItemRemoved({required this.playlist, required final  List<Playlist> playlists}): _playlists = playlists;
  

 final  Playlist playlist;
 final  List<Playlist> _playlists;
 List<Playlist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}


/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemRemovedCopyWith<ItemRemoved> get copyWith => _$ItemRemovedCopyWithImpl<ItemRemoved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemRemoved&&(identical(other.playlist, playlist) || other.playlist == playlist)&&const DeepCollectionEquality().equals(other._playlists, _playlists));
}


@override
int get hashCode => Object.hash(runtimeType,playlist,const DeepCollectionEquality().hash(_playlists));

@override
String toString() {
  return 'PlaylistsState.itemRemoved(playlist: $playlist, playlists: $playlists)';
}


}

/// @nodoc
abstract mixin class $ItemRemovedCopyWith<$Res> implements $PlaylistsStateCopyWith<$Res> {
  factory $ItemRemovedCopyWith(ItemRemoved value, $Res Function(ItemRemoved) _then) = _$ItemRemovedCopyWithImpl;
@useResult
$Res call({
 Playlist playlist, List<Playlist> playlists
});




}
/// @nodoc
class _$ItemRemovedCopyWithImpl<$Res>
    implements $ItemRemovedCopyWith<$Res> {
  _$ItemRemovedCopyWithImpl(this._self, this._then);

  final ItemRemoved _self;
  final $Res Function(ItemRemoved) _then;

/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlist = null,Object? playlists = null,}) {
  return _then(ItemRemoved(
playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as Playlist,playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}


}

/// @nodoc


class ItemsReordered implements PlaylistsState {
  const ItemsReordered({required this.playlist, required final  List<Playlist> playlists}): _playlists = playlists;
  

 final  Playlist playlist;
 final  List<Playlist> _playlists;
 List<Playlist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}


/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemsReorderedCopyWith<ItemsReordered> get copyWith => _$ItemsReorderedCopyWithImpl<ItemsReordered>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemsReordered&&(identical(other.playlist, playlist) || other.playlist == playlist)&&const DeepCollectionEquality().equals(other._playlists, _playlists));
}


@override
int get hashCode => Object.hash(runtimeType,playlist,const DeepCollectionEquality().hash(_playlists));

@override
String toString() {
  return 'PlaylistsState.itemsReordered(playlist: $playlist, playlists: $playlists)';
}


}

/// @nodoc
abstract mixin class $ItemsReorderedCopyWith<$Res> implements $PlaylistsStateCopyWith<$Res> {
  factory $ItemsReorderedCopyWith(ItemsReordered value, $Res Function(ItemsReordered) _then) = _$ItemsReorderedCopyWithImpl;
@useResult
$Res call({
 Playlist playlist, List<Playlist> playlists
});




}
/// @nodoc
class _$ItemsReorderedCopyWithImpl<$Res>
    implements $ItemsReorderedCopyWith<$Res> {
  _$ItemsReorderedCopyWithImpl(this._self, this._then);

  final ItemsReordered _self;
  final $Res Function(ItemsReordered) _then;

/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlist = null,Object? playlists = null,}) {
  return _then(ItemsReordered(
playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as Playlist,playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}


}

/// @nodoc


class PlaylistDuplicated implements PlaylistsState {
  const PlaylistDuplicated({required this.playlist, required final  List<Playlist> playlists}): _playlists = playlists;
  

 final  Playlist playlist;
 final  List<Playlist> _playlists;
 List<Playlist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}


/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistDuplicatedCopyWith<PlaylistDuplicated> get copyWith => _$PlaylistDuplicatedCopyWithImpl<PlaylistDuplicated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistDuplicated&&(identical(other.playlist, playlist) || other.playlist == playlist)&&const DeepCollectionEquality().equals(other._playlists, _playlists));
}


@override
int get hashCode => Object.hash(runtimeType,playlist,const DeepCollectionEquality().hash(_playlists));

@override
String toString() {
  return 'PlaylistsState.playlistDuplicated(playlist: $playlist, playlists: $playlists)';
}


}

/// @nodoc
abstract mixin class $PlaylistDuplicatedCopyWith<$Res> implements $PlaylistsStateCopyWith<$Res> {
  factory $PlaylistDuplicatedCopyWith(PlaylistDuplicated value, $Res Function(PlaylistDuplicated) _then) = _$PlaylistDuplicatedCopyWithImpl;
@useResult
$Res call({
 Playlist playlist, List<Playlist> playlists
});




}
/// @nodoc
class _$PlaylistDuplicatedCopyWithImpl<$Res>
    implements $PlaylistDuplicatedCopyWith<$Res> {
  _$PlaylistDuplicatedCopyWithImpl(this._self, this._then);

  final PlaylistDuplicated _self;
  final $Res Function(PlaylistDuplicated) _then;

/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlist = null,Object? playlists = null,}) {
  return _then(PlaylistDuplicated(
playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as Playlist,playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}


}

/// @nodoc


class FavoriteToggled implements PlaylistsState {
  const FavoriteToggled({required this.playlist, required final  List<Playlist> playlists}): _playlists = playlists;
  

 final  Playlist playlist;
 final  List<Playlist> _playlists;
 List<Playlist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}


/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoriteToggledCopyWith<FavoriteToggled> get copyWith => _$FavoriteToggledCopyWithImpl<FavoriteToggled>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoriteToggled&&(identical(other.playlist, playlist) || other.playlist == playlist)&&const DeepCollectionEquality().equals(other._playlists, _playlists));
}


@override
int get hashCode => Object.hash(runtimeType,playlist,const DeepCollectionEquality().hash(_playlists));

@override
String toString() {
  return 'PlaylistsState.favoriteToggled(playlist: $playlist, playlists: $playlists)';
}


}

/// @nodoc
abstract mixin class $FavoriteToggledCopyWith<$Res> implements $PlaylistsStateCopyWith<$Res> {
  factory $FavoriteToggledCopyWith(FavoriteToggled value, $Res Function(FavoriteToggled) _then) = _$FavoriteToggledCopyWithImpl;
@useResult
$Res call({
 Playlist playlist, List<Playlist> playlists
});




}
/// @nodoc
class _$FavoriteToggledCopyWithImpl<$Res>
    implements $FavoriteToggledCopyWith<$Res> {
  _$FavoriteToggledCopyWithImpl(this._self, this._then);

  final FavoriteToggled _self;
  final $Res Function(FavoriteToggled) _then;

/// Create a copy of PlaylistsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlist = null,Object? playlists = null,}) {
  return _then(FavoriteToggled(
playlist: null == playlist ? _self.playlist : playlist // ignore: cast_nullable_to_non_nullable
as Playlist,playlists: null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}


}

// dart format on
