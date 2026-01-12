// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookmarks_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookmarksEvent {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is BookmarksEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'BookmarksEvent()';
  }
}

/// @nodoc
class $BookmarksEventCopyWith<$Res> {
  $BookmarksEventCopyWith(BookmarksEvent _, $Res Function(BookmarksEvent) __);
}

/// Adds pattern-matching-related methods to [BookmarksEvent].
extension BookmarksEventPatterns on BookmarksEvent {
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
    TResult Function(LoadBookmarksEvent value)? load,
    TResult Function(CreateBookmarkEvent value)? create,
    TResult Function(DeleteBookmarkEvent value)? delete,
    TResult Function(UpdateBookmarkLabelEvent value)? updateLabel,
    TResult Function(SearchBookmarksEvent value)? search,
    TResult Function(ClearBookmarksSearchEvent value)? clearSearch,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case LoadBookmarksEvent() when load != null:
        return load(_that);
      case CreateBookmarkEvent() when create != null:
        return create(_that);
      case DeleteBookmarkEvent() when delete != null:
        return delete(_that);
      case UpdateBookmarkLabelEvent() when updateLabel != null:
        return updateLabel(_that);
      case SearchBookmarksEvent() when search != null:
        return search(_that);
      case ClearBookmarksSearchEvent() when clearSearch != null:
        return clearSearch(_that);
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
    required TResult Function(LoadBookmarksEvent value) load,
    required TResult Function(CreateBookmarkEvent value) create,
    required TResult Function(DeleteBookmarkEvent value) delete,
    required TResult Function(UpdateBookmarkLabelEvent value) updateLabel,
    required TResult Function(SearchBookmarksEvent value) search,
    required TResult Function(ClearBookmarksSearchEvent value) clearSearch,
  }) {
    final _that = this;
    switch (_that) {
      case LoadBookmarksEvent():
        return load(_that);
      case CreateBookmarkEvent():
        return create(_that);
      case DeleteBookmarkEvent():
        return delete(_that);
      case UpdateBookmarkLabelEvent():
        return updateLabel(_that);
      case SearchBookmarksEvent():
        return search(_that);
      case ClearBookmarksSearchEvent():
        return clearSearch(_that);
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
    TResult? Function(LoadBookmarksEvent value)? load,
    TResult? Function(CreateBookmarkEvent value)? create,
    TResult? Function(DeleteBookmarkEvent value)? delete,
    TResult? Function(UpdateBookmarkLabelEvent value)? updateLabel,
    TResult? Function(SearchBookmarksEvent value)? search,
    TResult? Function(ClearBookmarksSearchEvent value)? clearSearch,
  }) {
    final _that = this;
    switch (_that) {
      case LoadBookmarksEvent() when load != null:
        return load(_that);
      case CreateBookmarkEvent() when create != null:
        return create(_that);
      case DeleteBookmarkEvent() when delete != null:
        return delete(_that);
      case UpdateBookmarkLabelEvent() when updateLabel != null:
        return updateLabel(_that);
      case SearchBookmarksEvent() when search != null:
        return search(_that);
      case ClearBookmarksSearchEvent() when clearSearch != null:
        return clearSearch(_that);
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
    TResult Function()? load,
    TResult Function(
      int surahId,
      String surahName,
      String surahNameEn,
      String reciterId,
      String reciterName,
      int moshafId,
      String moshafName,
      int positionMs,
      int durationMs,
      String audioUrl,
      String? label,
      String? artworkUrl,
    )?
    create,
    TResult Function(String id)? delete,
    TResult Function(String id, String? label)? updateLabel,
    TResult Function(String query)? search,
    TResult Function()? clearSearch,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case LoadBookmarksEvent() when load != null:
        return load();
      case CreateBookmarkEvent() when create != null:
        return create(
          _that.surahId,
          _that.surahName,
          _that.surahNameEn,
          _that.reciterId,
          _that.reciterName,
          _that.moshafId,
          _that.moshafName,
          _that.positionMs,
          _that.durationMs,
          _that.audioUrl,
          _that.label,
          _that.artworkUrl,
        );
      case DeleteBookmarkEvent() when delete != null:
        return delete(_that.id);
      case UpdateBookmarkLabelEvent() when updateLabel != null:
        return updateLabel(_that.id, _that.label);
      case SearchBookmarksEvent() when search != null:
        return search(_that.query);
      case ClearBookmarksSearchEvent() when clearSearch != null:
        return clearSearch();
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
    required TResult Function() load,
    required TResult Function(
      int surahId,
      String surahName,
      String surahNameEn,
      String reciterId,
      String reciterName,
      int moshafId,
      String moshafName,
      int positionMs,
      int durationMs,
      String audioUrl,
      String? label,
      String? artworkUrl,
    )
    create,
    required TResult Function(String id) delete,
    required TResult Function(String id, String? label) updateLabel,
    required TResult Function(String query) search,
    required TResult Function() clearSearch,
  }) {
    final _that = this;
    switch (_that) {
      case LoadBookmarksEvent():
        return load();
      case CreateBookmarkEvent():
        return create(
          _that.surahId,
          _that.surahName,
          _that.surahNameEn,
          _that.reciterId,
          _that.reciterName,
          _that.moshafId,
          _that.moshafName,
          _that.positionMs,
          _that.durationMs,
          _that.audioUrl,
          _that.label,
          _that.artworkUrl,
        );
      case DeleteBookmarkEvent():
        return delete(_that.id);
      case UpdateBookmarkLabelEvent():
        return updateLabel(_that.id, _that.label);
      case SearchBookmarksEvent():
        return search(_that.query);
      case ClearBookmarksSearchEvent():
        return clearSearch();
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
    TResult? Function()? load,
    TResult? Function(
      int surahId,
      String surahName,
      String surahNameEn,
      String reciterId,
      String reciterName,
      int moshafId,
      String moshafName,
      int positionMs,
      int durationMs,
      String audioUrl,
      String? label,
      String? artworkUrl,
    )?
    create,
    TResult? Function(String id)? delete,
    TResult? Function(String id, String? label)? updateLabel,
    TResult? Function(String query)? search,
    TResult? Function()? clearSearch,
  }) {
    final _that = this;
    switch (_that) {
      case LoadBookmarksEvent() when load != null:
        return load();
      case CreateBookmarkEvent() when create != null:
        return create(
          _that.surahId,
          _that.surahName,
          _that.surahNameEn,
          _that.reciterId,
          _that.reciterName,
          _that.moshafId,
          _that.moshafName,
          _that.positionMs,
          _that.durationMs,
          _that.audioUrl,
          _that.label,
          _that.artworkUrl,
        );
      case DeleteBookmarkEvent() when delete != null:
        return delete(_that.id);
      case UpdateBookmarkLabelEvent() when updateLabel != null:
        return updateLabel(_that.id, _that.label);
      case SearchBookmarksEvent() when search != null:
        return search(_that.query);
      case ClearBookmarksSearchEvent() when clearSearch != null:
        return clearSearch();
      case _:
        return null;
    }
  }
}

/// @nodoc

class LoadBookmarksEvent implements BookmarksEvent {
  const LoadBookmarksEvent();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is LoadBookmarksEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'BookmarksEvent.load()';
  }
}

/// @nodoc

class CreateBookmarkEvent implements BookmarksEvent {
  const CreateBookmarkEvent({
    required this.surahId,
    required this.surahName,
    required this.surahNameEn,
    required this.reciterId,
    required this.reciterName,
    required this.moshafId,
    required this.moshafName,
    required this.positionMs,
    required this.durationMs,
    required this.audioUrl,
    this.label,
    this.artworkUrl,
  });

  final int surahId;
  final String surahName;
  final String surahNameEn;
  final String reciterId;
  final String reciterName;
  final int moshafId;
  final String moshafName;
  final int positionMs;
  final int durationMs;
  final String audioUrl;
  final String? label;
  final String? artworkUrl;

  /// Create a copy of BookmarksEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CreateBookmarkEventCopyWith<CreateBookmarkEvent> get copyWith =>
      _$CreateBookmarkEventCopyWithImpl<CreateBookmarkEvent>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CreateBookmarkEvent &&
            (identical(other.surahId, surahId) || other.surahId == surahId) &&
            (identical(other.surahName, surahName) ||
                other.surahName == surahName) &&
            (identical(other.surahNameEn, surahNameEn) ||
                other.surahNameEn == surahNameEn) &&
            (identical(other.reciterId, reciterId) ||
                other.reciterId == reciterId) &&
            (identical(other.reciterName, reciterName) ||
                other.reciterName == reciterName) &&
            (identical(other.moshafId, moshafId) ||
                other.moshafId == moshafId) &&
            (identical(other.moshafName, moshafName) ||
                other.moshafName == moshafName) &&
            (identical(other.positionMs, positionMs) ||
                other.positionMs == positionMs) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.artworkUrl, artworkUrl) ||
                other.artworkUrl == artworkUrl));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    surahId,
    surahName,
    surahNameEn,
    reciterId,
    reciterName,
    moshafId,
    moshafName,
    positionMs,
    durationMs,
    audioUrl,
    label,
    artworkUrl,
  );

  @override
  String toString() {
    return 'BookmarksEvent.create(surahId: $surahId, surahName: $surahName, surahNameEn: $surahNameEn, reciterId: $reciterId, reciterName: $reciterName, moshafId: $moshafId, moshafName: $moshafName, positionMs: $positionMs, durationMs: $durationMs, audioUrl: $audioUrl, label: $label, artworkUrl: $artworkUrl)';
  }
}

/// @nodoc
abstract mixin class $CreateBookmarkEventCopyWith<$Res>
    implements $BookmarksEventCopyWith<$Res> {
  factory $CreateBookmarkEventCopyWith(
    CreateBookmarkEvent value,
    $Res Function(CreateBookmarkEvent) _then,
  ) = _$CreateBookmarkEventCopyWithImpl;
  @useResult
  $Res call({
    int surahId,
    String surahName,
    String surahNameEn,
    String reciterId,
    String reciterName,
    int moshafId,
    String moshafName,
    int positionMs,
    int durationMs,
    String audioUrl,
    String? label,
    String? artworkUrl,
  });
}

/// @nodoc
class _$CreateBookmarkEventCopyWithImpl<$Res>
    implements $CreateBookmarkEventCopyWith<$Res> {
  _$CreateBookmarkEventCopyWithImpl(this._self, this._then);

  final CreateBookmarkEvent _self;
  final $Res Function(CreateBookmarkEvent) _then;

  /// Create a copy of BookmarksEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? surahId = null,
    Object? surahName = null,
    Object? surahNameEn = null,
    Object? reciterId = null,
    Object? reciterName = null,
    Object? moshafId = null,
    Object? moshafName = null,
    Object? positionMs = null,
    Object? durationMs = null,
    Object? audioUrl = null,
    Object? label = freezed,
    Object? artworkUrl = freezed,
  }) {
    return _then(
      CreateBookmarkEvent(
        surahId: null == surahId
            ? _self.surahId
            : surahId // ignore: cast_nullable_to_non_nullable
                  as int,
        surahName: null == surahName
            ? _self.surahName
            : surahName // ignore: cast_nullable_to_non_nullable
                  as String,
        surahNameEn: null == surahNameEn
            ? _self.surahNameEn
            : surahNameEn // ignore: cast_nullable_to_non_nullable
                  as String,
        reciterId: null == reciterId
            ? _self.reciterId
            : reciterId // ignore: cast_nullable_to_non_nullable
                  as String,
        reciterName: null == reciterName
            ? _self.reciterName
            : reciterName // ignore: cast_nullable_to_non_nullable
                  as String,
        moshafId: null == moshafId
            ? _self.moshafId
            : moshafId // ignore: cast_nullable_to_non_nullable
                  as int,
        moshafName: null == moshafName
            ? _self.moshafName
            : moshafName // ignore: cast_nullable_to_non_nullable
                  as String,
        positionMs: null == positionMs
            ? _self.positionMs
            : positionMs // ignore: cast_nullable_to_non_nullable
                  as int,
        durationMs: null == durationMs
            ? _self.durationMs
            : durationMs // ignore: cast_nullable_to_non_nullable
                  as int,
        audioUrl: null == audioUrl
            ? _self.audioUrl
            : audioUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        label: freezed == label
            ? _self.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
        artworkUrl: freezed == artworkUrl
            ? _self.artworkUrl
            : artworkUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class DeleteBookmarkEvent implements BookmarksEvent {
  const DeleteBookmarkEvent({required this.id});

  final String id;

  /// Create a copy of BookmarksEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DeleteBookmarkEventCopyWith<DeleteBookmarkEvent> get copyWith =>
      _$DeleteBookmarkEventCopyWithImpl<DeleteBookmarkEvent>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DeleteBookmarkEvent &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @override
  String toString() {
    return 'BookmarksEvent.delete(id: $id)';
  }
}

/// @nodoc
abstract mixin class $DeleteBookmarkEventCopyWith<$Res>
    implements $BookmarksEventCopyWith<$Res> {
  factory $DeleteBookmarkEventCopyWith(
    DeleteBookmarkEvent value,
    $Res Function(DeleteBookmarkEvent) _then,
  ) = _$DeleteBookmarkEventCopyWithImpl;
  @useResult
  $Res call({String id});
}

/// @nodoc
class _$DeleteBookmarkEventCopyWithImpl<$Res>
    implements $DeleteBookmarkEventCopyWith<$Res> {
  _$DeleteBookmarkEventCopyWithImpl(this._self, this._then);

  final DeleteBookmarkEvent _self;
  final $Res Function(DeleteBookmarkEvent) _then;

  /// Create a copy of BookmarksEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? id = null}) {
    return _then(
      DeleteBookmarkEvent(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class UpdateBookmarkLabelEvent implements BookmarksEvent {
  const UpdateBookmarkLabelEvent({required this.id, this.label});

  final String id;
  final String? label;

  /// Create a copy of BookmarksEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UpdateBookmarkLabelEventCopyWith<UpdateBookmarkLabelEvent> get copyWith =>
      _$UpdateBookmarkLabelEventCopyWithImpl<UpdateBookmarkLabelEvent>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UpdateBookmarkLabelEvent &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, label);

  @override
  String toString() {
    return 'BookmarksEvent.updateLabel(id: $id, label: $label)';
  }
}

/// @nodoc
abstract mixin class $UpdateBookmarkLabelEventCopyWith<$Res>
    implements $BookmarksEventCopyWith<$Res> {
  factory $UpdateBookmarkLabelEventCopyWith(
    UpdateBookmarkLabelEvent value,
    $Res Function(UpdateBookmarkLabelEvent) _then,
  ) = _$UpdateBookmarkLabelEventCopyWithImpl;
  @useResult
  $Res call({String id, String? label});
}

/// @nodoc
class _$UpdateBookmarkLabelEventCopyWithImpl<$Res>
    implements $UpdateBookmarkLabelEventCopyWith<$Res> {
  _$UpdateBookmarkLabelEventCopyWithImpl(this._self, this._then);

  final UpdateBookmarkLabelEvent _self;
  final $Res Function(UpdateBookmarkLabelEvent) _then;

  /// Create a copy of BookmarksEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? id = null, Object? label = freezed}) {
    return _then(
      UpdateBookmarkLabelEvent(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        label: freezed == label
            ? _self.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class SearchBookmarksEvent implements BookmarksEvent {
  const SearchBookmarksEvent({required this.query});

  final String query;

  /// Create a copy of BookmarksEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SearchBookmarksEventCopyWith<SearchBookmarksEvent> get copyWith =>
      _$SearchBookmarksEventCopyWithImpl<SearchBookmarksEvent>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SearchBookmarksEvent &&
            (identical(other.query, query) || other.query == query));
  }

  @override
  int get hashCode => Object.hash(runtimeType, query);

  @override
  String toString() {
    return 'BookmarksEvent.search(query: $query)';
  }
}

/// @nodoc
abstract mixin class $SearchBookmarksEventCopyWith<$Res>
    implements $BookmarksEventCopyWith<$Res> {
  factory $SearchBookmarksEventCopyWith(
    SearchBookmarksEvent value,
    $Res Function(SearchBookmarksEvent) _then,
  ) = _$SearchBookmarksEventCopyWithImpl;
  @useResult
  $Res call({String query});
}

/// @nodoc
class _$SearchBookmarksEventCopyWithImpl<$Res>
    implements $SearchBookmarksEventCopyWith<$Res> {
  _$SearchBookmarksEventCopyWithImpl(this._self, this._then);

  final SearchBookmarksEvent _self;
  final $Res Function(SearchBookmarksEvent) _then;

  /// Create a copy of BookmarksEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? query = null}) {
    return _then(
      SearchBookmarksEvent(
        query: null == query
            ? _self.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class ClearBookmarksSearchEvent implements BookmarksEvent {
  const ClearBookmarksSearchEvent();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ClearBookmarksSearchEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'BookmarksEvent.clearSearch()';
  }
}

/// @nodoc
mixin _$BookmarksState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is BookmarksState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'BookmarksState()';
  }
}

/// @nodoc
class $BookmarksStateCopyWith<$Res> {
  $BookmarksStateCopyWith(BookmarksState _, $Res Function(BookmarksState) __);
}

/// Adds pattern-matching-related methods to [BookmarksState].
extension BookmarksStatePatterns on BookmarksState {
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
    TResult Function(BookmarksInitial value)? initial,
    TResult Function(BookmarksLoading value)? loading,
    TResult Function(BookmarksLoaded value)? loaded,
    TResult Function(BookmarkCreated value)? bookmarkCreated,
    TResult Function(BookmarkUpdated value)? bookmarkUpdated,
    TResult Function(BookmarkDeleted value)? bookmarkDeleted,
    TResult Function(BookmarksError value)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksInitial() when initial != null:
        return initial(_that);
      case BookmarksLoading() when loading != null:
        return loading(_that);
      case BookmarksLoaded() when loaded != null:
        return loaded(_that);
      case BookmarkCreated() when bookmarkCreated != null:
        return bookmarkCreated(_that);
      case BookmarkUpdated() when bookmarkUpdated != null:
        return bookmarkUpdated(_that);
      case BookmarkDeleted() when bookmarkDeleted != null:
        return bookmarkDeleted(_that);
      case BookmarksError() when error != null:
        return error(_that);
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
    required TResult Function(BookmarksInitial value) initial,
    required TResult Function(BookmarksLoading value) loading,
    required TResult Function(BookmarksLoaded value) loaded,
    required TResult Function(BookmarkCreated value) bookmarkCreated,
    required TResult Function(BookmarkUpdated value) bookmarkUpdated,
    required TResult Function(BookmarkDeleted value) bookmarkDeleted,
    required TResult Function(BookmarksError value) error,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksInitial():
        return initial(_that);
      case BookmarksLoading():
        return loading(_that);
      case BookmarksLoaded():
        return loaded(_that);
      case BookmarkCreated():
        return bookmarkCreated(_that);
      case BookmarkUpdated():
        return bookmarkUpdated(_that);
      case BookmarkDeleted():
        return bookmarkDeleted(_that);
      case BookmarksError():
        return error(_that);
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
    TResult? Function(BookmarksInitial value)? initial,
    TResult? Function(BookmarksLoading value)? loading,
    TResult? Function(BookmarksLoaded value)? loaded,
    TResult? Function(BookmarkCreated value)? bookmarkCreated,
    TResult? Function(BookmarkUpdated value)? bookmarkUpdated,
    TResult? Function(BookmarkDeleted value)? bookmarkDeleted,
    TResult? Function(BookmarksError value)? error,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksInitial() when initial != null:
        return initial(_that);
      case BookmarksLoading() when loading != null:
        return loading(_that);
      case BookmarksLoaded() when loaded != null:
        return loaded(_that);
      case BookmarkCreated() when bookmarkCreated != null:
        return bookmarkCreated(_that);
      case BookmarkUpdated() when bookmarkUpdated != null:
        return bookmarkUpdated(_that);
      case BookmarkDeleted() when bookmarkDeleted != null:
        return bookmarkDeleted(_that);
      case BookmarksError() when error != null:
        return error(_that);
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
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<BookmarkEntity> bookmarks,
      List<BookmarkEntity> filteredBookmarks,
      String searchQuery,
    )?
    loaded,
    TResult Function(BookmarkEntity bookmark, List<BookmarkEntity> bookmarks)?
    bookmarkCreated,
    TResult Function(BookmarkEntity bookmark, List<BookmarkEntity> bookmarks)?
    bookmarkUpdated,
    TResult Function(String deletedId, List<BookmarkEntity> bookmarks)?
    bookmarkDeleted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksInitial() when initial != null:
        return initial();
      case BookmarksLoading() when loading != null:
        return loading();
      case BookmarksLoaded() when loaded != null:
        return loaded(
          _that.bookmarks,
          _that.filteredBookmarks,
          _that.searchQuery,
        );
      case BookmarkCreated() when bookmarkCreated != null:
        return bookmarkCreated(_that.bookmark, _that.bookmarks);
      case BookmarkUpdated() when bookmarkUpdated != null:
        return bookmarkUpdated(_that.bookmark, _that.bookmarks);
      case BookmarkDeleted() when bookmarkDeleted != null:
        return bookmarkDeleted(_that.deletedId, _that.bookmarks);
      case BookmarksError() when error != null:
        return error(_that.message);
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
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<BookmarkEntity> bookmarks,
      List<BookmarkEntity> filteredBookmarks,
      String searchQuery,
    )
    loaded,
    required TResult Function(
      BookmarkEntity bookmark,
      List<BookmarkEntity> bookmarks,
    )
    bookmarkCreated,
    required TResult Function(
      BookmarkEntity bookmark,
      List<BookmarkEntity> bookmarks,
    )
    bookmarkUpdated,
    required TResult Function(String deletedId, List<BookmarkEntity> bookmarks)
    bookmarkDeleted,
    required TResult Function(String message) error,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksInitial():
        return initial();
      case BookmarksLoading():
        return loading();
      case BookmarksLoaded():
        return loaded(
          _that.bookmarks,
          _that.filteredBookmarks,
          _that.searchQuery,
        );
      case BookmarkCreated():
        return bookmarkCreated(_that.bookmark, _that.bookmarks);
      case BookmarkUpdated():
        return bookmarkUpdated(_that.bookmark, _that.bookmarks);
      case BookmarkDeleted():
        return bookmarkDeleted(_that.deletedId, _that.bookmarks);
      case BookmarksError():
        return error(_that.message);
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
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<BookmarkEntity> bookmarks,
      List<BookmarkEntity> filteredBookmarks,
      String searchQuery,
    )?
    loaded,
    TResult? Function(BookmarkEntity bookmark, List<BookmarkEntity> bookmarks)?
    bookmarkCreated,
    TResult? Function(BookmarkEntity bookmark, List<BookmarkEntity> bookmarks)?
    bookmarkUpdated,
    TResult? Function(String deletedId, List<BookmarkEntity> bookmarks)?
    bookmarkDeleted,
    TResult? Function(String message)? error,
  }) {
    final _that = this;
    switch (_that) {
      case BookmarksInitial() when initial != null:
        return initial();
      case BookmarksLoading() when loading != null:
        return loading();
      case BookmarksLoaded() when loaded != null:
        return loaded(
          _that.bookmarks,
          _that.filteredBookmarks,
          _that.searchQuery,
        );
      case BookmarkCreated() when bookmarkCreated != null:
        return bookmarkCreated(_that.bookmark, _that.bookmarks);
      case BookmarkUpdated() when bookmarkUpdated != null:
        return bookmarkUpdated(_that.bookmark, _that.bookmarks);
      case BookmarkDeleted() when bookmarkDeleted != null:
        return bookmarkDeleted(_that.deletedId, _that.bookmarks);
      case BookmarksError() when error != null:
        return error(_that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc

class BookmarksInitial implements BookmarksState {
  const BookmarksInitial();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is BookmarksInitial);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'BookmarksState.initial()';
  }
}

/// @nodoc

class BookmarksLoading implements BookmarksState {
  const BookmarksLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is BookmarksLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'BookmarksState.loading()';
  }
}

/// @nodoc

class BookmarksLoaded implements BookmarksState {
  const BookmarksLoaded({
    required final List<BookmarkEntity> bookmarks,
    required final List<BookmarkEntity> filteredBookmarks,
    this.searchQuery = '',
  }) : _bookmarks = bookmarks,
       _filteredBookmarks = filteredBookmarks;

  final List<BookmarkEntity> _bookmarks;
  List<BookmarkEntity> get bookmarks {
    if (_bookmarks is EqualUnmodifiableListView) return _bookmarks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bookmarks);
  }

  final List<BookmarkEntity> _filteredBookmarks;
  List<BookmarkEntity> get filteredBookmarks {
    if (_filteredBookmarks is EqualUnmodifiableListView)
      return _filteredBookmarks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_filteredBookmarks);
  }

  @JsonKey()
  final String searchQuery;

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookmarksLoadedCopyWith<BookmarksLoaded> get copyWith =>
      _$BookmarksLoadedCopyWithImpl<BookmarksLoaded>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookmarksLoaded &&
            const DeepCollectionEquality().equals(
              other._bookmarks,
              _bookmarks,
            ) &&
            const DeepCollectionEquality().equals(
              other._filteredBookmarks,
              _filteredBookmarks,
            ) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_bookmarks),
    const DeepCollectionEquality().hash(_filteredBookmarks),
    searchQuery,
  );

  @override
  String toString() {
    return 'BookmarksState.loaded(bookmarks: $bookmarks, filteredBookmarks: $filteredBookmarks, searchQuery: $searchQuery)';
  }
}

/// @nodoc
abstract mixin class $BookmarksLoadedCopyWith<$Res>
    implements $BookmarksStateCopyWith<$Res> {
  factory $BookmarksLoadedCopyWith(
    BookmarksLoaded value,
    $Res Function(BookmarksLoaded) _then,
  ) = _$BookmarksLoadedCopyWithImpl;
  @useResult
  $Res call({
    List<BookmarkEntity> bookmarks,
    List<BookmarkEntity> filteredBookmarks,
    String searchQuery,
  });
}

/// @nodoc
class _$BookmarksLoadedCopyWithImpl<$Res>
    implements $BookmarksLoadedCopyWith<$Res> {
  _$BookmarksLoadedCopyWithImpl(this._self, this._then);

  final BookmarksLoaded _self;
  final $Res Function(BookmarksLoaded) _then;

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? bookmarks = null,
    Object? filteredBookmarks = null,
    Object? searchQuery = null,
  }) {
    return _then(
      BookmarksLoaded(
        bookmarks: null == bookmarks
            ? _self._bookmarks
            : bookmarks // ignore: cast_nullable_to_non_nullable
                  as List<BookmarkEntity>,
        filteredBookmarks: null == filteredBookmarks
            ? _self._filteredBookmarks
            : filteredBookmarks // ignore: cast_nullable_to_non_nullable
                  as List<BookmarkEntity>,
        searchQuery: null == searchQuery
            ? _self.searchQuery
            : searchQuery // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class BookmarkCreated implements BookmarksState {
  const BookmarkCreated({
    required this.bookmark,
    required final List<BookmarkEntity> bookmarks,
  }) : _bookmarks = bookmarks;

  final BookmarkEntity bookmark;
  final List<BookmarkEntity> _bookmarks;
  List<BookmarkEntity> get bookmarks {
    if (_bookmarks is EqualUnmodifiableListView) return _bookmarks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bookmarks);
  }

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookmarkCreatedCopyWith<BookmarkCreated> get copyWith =>
      _$BookmarkCreatedCopyWithImpl<BookmarkCreated>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookmarkCreated &&
            (identical(other.bookmark, bookmark) ||
                other.bookmark == bookmark) &&
            const DeepCollectionEquality().equals(
              other._bookmarks,
              _bookmarks,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    bookmark,
    const DeepCollectionEquality().hash(_bookmarks),
  );

  @override
  String toString() {
    return 'BookmarksState.bookmarkCreated(bookmark: $bookmark, bookmarks: $bookmarks)';
  }
}

/// @nodoc
abstract mixin class $BookmarkCreatedCopyWith<$Res>
    implements $BookmarksStateCopyWith<$Res> {
  factory $BookmarkCreatedCopyWith(
    BookmarkCreated value,
    $Res Function(BookmarkCreated) _then,
  ) = _$BookmarkCreatedCopyWithImpl;
  @useResult
  $Res call({BookmarkEntity bookmark, List<BookmarkEntity> bookmarks});

  $BookmarkEntityCopyWith<$Res> get bookmark;
}

/// @nodoc
class _$BookmarkCreatedCopyWithImpl<$Res>
    implements $BookmarkCreatedCopyWith<$Res> {
  _$BookmarkCreatedCopyWithImpl(this._self, this._then);

  final BookmarkCreated _self;
  final $Res Function(BookmarkCreated) _then;

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? bookmark = null, Object? bookmarks = null}) {
    return _then(
      BookmarkCreated(
        bookmark: null == bookmark
            ? _self.bookmark
            : bookmark // ignore: cast_nullable_to_non_nullable
                  as BookmarkEntity,
        bookmarks: null == bookmarks
            ? _self._bookmarks
            : bookmarks // ignore: cast_nullable_to_non_nullable
                  as List<BookmarkEntity>,
      ),
    );
  }

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BookmarkEntityCopyWith<$Res> get bookmark {
    return $BookmarkEntityCopyWith<$Res>(_self.bookmark, (value) {
      return _then(_self.copyWith(bookmark: value));
    });
  }
}

/// @nodoc

class BookmarkUpdated implements BookmarksState {
  const BookmarkUpdated({
    required this.bookmark,
    required final List<BookmarkEntity> bookmarks,
  }) : _bookmarks = bookmarks;

  final BookmarkEntity bookmark;
  final List<BookmarkEntity> _bookmarks;
  List<BookmarkEntity> get bookmarks {
    if (_bookmarks is EqualUnmodifiableListView) return _bookmarks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bookmarks);
  }

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookmarkUpdatedCopyWith<BookmarkUpdated> get copyWith =>
      _$BookmarkUpdatedCopyWithImpl<BookmarkUpdated>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookmarkUpdated &&
            (identical(other.bookmark, bookmark) ||
                other.bookmark == bookmark) &&
            const DeepCollectionEquality().equals(
              other._bookmarks,
              _bookmarks,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    bookmark,
    const DeepCollectionEquality().hash(_bookmarks),
  );

  @override
  String toString() {
    return 'BookmarksState.bookmarkUpdated(bookmark: $bookmark, bookmarks: $bookmarks)';
  }
}

/// @nodoc
abstract mixin class $BookmarkUpdatedCopyWith<$Res>
    implements $BookmarksStateCopyWith<$Res> {
  factory $BookmarkUpdatedCopyWith(
    BookmarkUpdated value,
    $Res Function(BookmarkUpdated) _then,
  ) = _$BookmarkUpdatedCopyWithImpl;
  @useResult
  $Res call({BookmarkEntity bookmark, List<BookmarkEntity> bookmarks});

  $BookmarkEntityCopyWith<$Res> get bookmark;
}

/// @nodoc
class _$BookmarkUpdatedCopyWithImpl<$Res>
    implements $BookmarkUpdatedCopyWith<$Res> {
  _$BookmarkUpdatedCopyWithImpl(this._self, this._then);

  final BookmarkUpdated _self;
  final $Res Function(BookmarkUpdated) _then;

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? bookmark = null, Object? bookmarks = null}) {
    return _then(
      BookmarkUpdated(
        bookmark: null == bookmark
            ? _self.bookmark
            : bookmark // ignore: cast_nullable_to_non_nullable
                  as BookmarkEntity,
        bookmarks: null == bookmarks
            ? _self._bookmarks
            : bookmarks // ignore: cast_nullable_to_non_nullable
                  as List<BookmarkEntity>,
      ),
    );
  }

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BookmarkEntityCopyWith<$Res> get bookmark {
    return $BookmarkEntityCopyWith<$Res>(_self.bookmark, (value) {
      return _then(_self.copyWith(bookmark: value));
    });
  }
}

/// @nodoc

class BookmarkDeleted implements BookmarksState {
  const BookmarkDeleted({
    required this.deletedId,
    required final List<BookmarkEntity> bookmarks,
  }) : _bookmarks = bookmarks;

  final String deletedId;
  final List<BookmarkEntity> _bookmarks;
  List<BookmarkEntity> get bookmarks {
    if (_bookmarks is EqualUnmodifiableListView) return _bookmarks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bookmarks);
  }

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookmarkDeletedCopyWith<BookmarkDeleted> get copyWith =>
      _$BookmarkDeletedCopyWithImpl<BookmarkDeleted>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookmarkDeleted &&
            (identical(other.deletedId, deletedId) ||
                other.deletedId == deletedId) &&
            const DeepCollectionEquality().equals(
              other._bookmarks,
              _bookmarks,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    deletedId,
    const DeepCollectionEquality().hash(_bookmarks),
  );

  @override
  String toString() {
    return 'BookmarksState.bookmarkDeleted(deletedId: $deletedId, bookmarks: $bookmarks)';
  }
}

/// @nodoc
abstract mixin class $BookmarkDeletedCopyWith<$Res>
    implements $BookmarksStateCopyWith<$Res> {
  factory $BookmarkDeletedCopyWith(
    BookmarkDeleted value,
    $Res Function(BookmarkDeleted) _then,
  ) = _$BookmarkDeletedCopyWithImpl;
  @useResult
  $Res call({String deletedId, List<BookmarkEntity> bookmarks});
}

/// @nodoc
class _$BookmarkDeletedCopyWithImpl<$Res>
    implements $BookmarkDeletedCopyWith<$Res> {
  _$BookmarkDeletedCopyWithImpl(this._self, this._then);

  final BookmarkDeleted _self;
  final $Res Function(BookmarkDeleted) _then;

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? deletedId = null, Object? bookmarks = null}) {
    return _then(
      BookmarkDeleted(
        deletedId: null == deletedId
            ? _self.deletedId
            : deletedId // ignore: cast_nullable_to_non_nullable
                  as String,
        bookmarks: null == bookmarks
            ? _self._bookmarks
            : bookmarks // ignore: cast_nullable_to_non_nullable
                  as List<BookmarkEntity>,
      ),
    );
  }
}

/// @nodoc

class BookmarksError implements BookmarksState {
  const BookmarksError(this.message);

  final String message;

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookmarksErrorCopyWith<BookmarksError> get copyWith =>
      _$BookmarksErrorCopyWithImpl<BookmarksError>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookmarksError &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'BookmarksState.error(message: $message)';
  }
}

/// @nodoc
abstract mixin class $BookmarksErrorCopyWith<$Res>
    implements $BookmarksStateCopyWith<$Res> {
  factory $BookmarksErrorCopyWith(
    BookmarksError value,
    $Res Function(BookmarksError) _then,
  ) = _$BookmarksErrorCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$BookmarksErrorCopyWithImpl<$Res>
    implements $BookmarksErrorCopyWith<$Res> {
  _$BookmarksErrorCopyWithImpl(this._self, this._then);

  final BookmarksError _self;
  final $Res Function(BookmarksError) _then;

  /// Create a copy of BookmarksState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? message = null}) {
    return _then(
      BookmarksError(
        null == message
            ? _self.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}
