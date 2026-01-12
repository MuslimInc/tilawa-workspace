// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HistoryEvent {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is HistoryEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'HistoryEvent()';
  }
}

/// @nodoc
class $HistoryEventCopyWith<$Res> {
  $HistoryEventCopyWith(HistoryEvent _, $Res Function(HistoryEvent) __);
}

/// Adds pattern-matching-related methods to [HistoryEvent].
extension HistoryEventPatterns on HistoryEvent {
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
    TResult Function(_LoadAllHistory value)? loadAllHistory,
    TResult Function(_LoadRecentHistory value)? loadRecentHistory,
    TResult Function(_SearchHistory value)? searchHistory,
    TResult Function(_ClearSearch value)? clearSearch,
    TResult Function(_DeleteHistory value)? deleteHistory,
    TResult Function(_ClearAllHistory value)? clearAllHistory,
    TResult Function(_RefreshHistory value)? refreshHistory,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LoadAllHistory() when loadAllHistory != null:
        return loadAllHistory(_that);
      case _LoadRecentHistory() when loadRecentHistory != null:
        return loadRecentHistory(_that);
      case _SearchHistory() when searchHistory != null:
        return searchHistory(_that);
      case _ClearSearch() when clearSearch != null:
        return clearSearch(_that);
      case _DeleteHistory() when deleteHistory != null:
        return deleteHistory(_that);
      case _ClearAllHistory() when clearAllHistory != null:
        return clearAllHistory(_that);
      case _RefreshHistory() when refreshHistory != null:
        return refreshHistory(_that);
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
    required TResult Function(_LoadAllHistory value) loadAllHistory,
    required TResult Function(_LoadRecentHistory value) loadRecentHistory,
    required TResult Function(_SearchHistory value) searchHistory,
    required TResult Function(_ClearSearch value) clearSearch,
    required TResult Function(_DeleteHistory value) deleteHistory,
    required TResult Function(_ClearAllHistory value) clearAllHistory,
    required TResult Function(_RefreshHistory value) refreshHistory,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadAllHistory():
        return loadAllHistory(_that);
      case _LoadRecentHistory():
        return loadRecentHistory(_that);
      case _SearchHistory():
        return searchHistory(_that);
      case _ClearSearch():
        return clearSearch(_that);
      case _DeleteHistory():
        return deleteHistory(_that);
      case _ClearAllHistory():
        return clearAllHistory(_that);
      case _RefreshHistory():
        return refreshHistory(_that);
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
    TResult? Function(_LoadAllHistory value)? loadAllHistory,
    TResult? Function(_LoadRecentHistory value)? loadRecentHistory,
    TResult? Function(_SearchHistory value)? searchHistory,
    TResult? Function(_ClearSearch value)? clearSearch,
    TResult? Function(_DeleteHistory value)? deleteHistory,
    TResult? Function(_ClearAllHistory value)? clearAllHistory,
    TResult? Function(_RefreshHistory value)? refreshHistory,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadAllHistory() when loadAllHistory != null:
        return loadAllHistory(_that);
      case _LoadRecentHistory() when loadRecentHistory != null:
        return loadRecentHistory(_that);
      case _SearchHistory() when searchHistory != null:
        return searchHistory(_that);
      case _ClearSearch() when clearSearch != null:
        return clearSearch(_that);
      case _DeleteHistory() when deleteHistory != null:
        return deleteHistory(_that);
      case _ClearAllHistory() when clearAllHistory != null:
        return clearAllHistory(_that);
      case _RefreshHistory() when refreshHistory != null:
        return refreshHistory(_that);
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
    TResult Function()? loadAllHistory,
    TResult Function(int limit)? loadRecentHistory,
    TResult Function(String query)? searchHistory,
    TResult Function()? clearSearch,
    TResult Function(String id)? deleteHistory,
    TResult Function()? clearAllHistory,
    TResult Function()? refreshHistory,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LoadAllHistory() when loadAllHistory != null:
        return loadAllHistory();
      case _LoadRecentHistory() when loadRecentHistory != null:
        return loadRecentHistory(_that.limit);
      case _SearchHistory() when searchHistory != null:
        return searchHistory(_that.query);
      case _ClearSearch() when clearSearch != null:
        return clearSearch();
      case _DeleteHistory() when deleteHistory != null:
        return deleteHistory(_that.id);
      case _ClearAllHistory() when clearAllHistory != null:
        return clearAllHistory();
      case _RefreshHistory() when refreshHistory != null:
        return refreshHistory();
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
    required TResult Function() loadAllHistory,
    required TResult Function(int limit) loadRecentHistory,
    required TResult Function(String query) searchHistory,
    required TResult Function() clearSearch,
    required TResult Function(String id) deleteHistory,
    required TResult Function() clearAllHistory,
    required TResult Function() refreshHistory,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadAllHistory():
        return loadAllHistory();
      case _LoadRecentHistory():
        return loadRecentHistory(_that.limit);
      case _SearchHistory():
        return searchHistory(_that.query);
      case _ClearSearch():
        return clearSearch();
      case _DeleteHistory():
        return deleteHistory(_that.id);
      case _ClearAllHistory():
        return clearAllHistory();
      case _RefreshHistory():
        return refreshHistory();
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
    TResult? Function()? loadAllHistory,
    TResult? Function(int limit)? loadRecentHistory,
    TResult? Function(String query)? searchHistory,
    TResult? Function()? clearSearch,
    TResult? Function(String id)? deleteHistory,
    TResult? Function()? clearAllHistory,
    TResult? Function()? refreshHistory,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadAllHistory() when loadAllHistory != null:
        return loadAllHistory();
      case _LoadRecentHistory() when loadRecentHistory != null:
        return loadRecentHistory(_that.limit);
      case _SearchHistory() when searchHistory != null:
        return searchHistory(_that.query);
      case _ClearSearch() when clearSearch != null:
        return clearSearch();
      case _DeleteHistory() when deleteHistory != null:
        return deleteHistory(_that.id);
      case _ClearAllHistory() when clearAllHistory != null:
        return clearAllHistory();
      case _RefreshHistory() when refreshHistory != null:
        return refreshHistory();
      case _:
        return null;
    }
  }
}

/// @nodoc

class _LoadAllHistory implements HistoryEvent {
  const _LoadAllHistory();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _LoadAllHistory);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'HistoryEvent.loadAllHistory()';
  }
}

/// @nodoc

class _LoadRecentHistory implements HistoryEvent {
  const _LoadRecentHistory({this.limit = 20});

  @JsonKey()
  final int limit;

  /// Create a copy of HistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LoadRecentHistoryCopyWith<_LoadRecentHistory> get copyWith =>
      __$LoadRecentHistoryCopyWithImpl<_LoadRecentHistory>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LoadRecentHistory &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @override
  int get hashCode => Object.hash(runtimeType, limit);

  @override
  String toString() {
    return 'HistoryEvent.loadRecentHistory(limit: $limit)';
  }
}

/// @nodoc
abstract mixin class _$LoadRecentHistoryCopyWith<$Res>
    implements $HistoryEventCopyWith<$Res> {
  factory _$LoadRecentHistoryCopyWith(
    _LoadRecentHistory value,
    $Res Function(_LoadRecentHistory) _then,
  ) = __$LoadRecentHistoryCopyWithImpl;
  @useResult
  $Res call({int limit});
}

/// @nodoc
class __$LoadRecentHistoryCopyWithImpl<$Res>
    implements _$LoadRecentHistoryCopyWith<$Res> {
  __$LoadRecentHistoryCopyWithImpl(this._self, this._then);

  final _LoadRecentHistory _self;
  final $Res Function(_LoadRecentHistory) _then;

  /// Create a copy of HistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? limit = null}) {
    return _then(
      _LoadRecentHistory(
        limit: null == limit
            ? _self.limit
            : limit // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _SearchHistory implements HistoryEvent {
  const _SearchHistory(this.query);

  final String query;

  /// Create a copy of HistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SearchHistoryCopyWith<_SearchHistory> get copyWith =>
      __$SearchHistoryCopyWithImpl<_SearchHistory>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SearchHistory &&
            (identical(other.query, query) || other.query == query));
  }

  @override
  int get hashCode => Object.hash(runtimeType, query);

  @override
  String toString() {
    return 'HistoryEvent.searchHistory(query: $query)';
  }
}

/// @nodoc
abstract mixin class _$SearchHistoryCopyWith<$Res>
    implements $HistoryEventCopyWith<$Res> {
  factory _$SearchHistoryCopyWith(
    _SearchHistory value,
    $Res Function(_SearchHistory) _then,
  ) = __$SearchHistoryCopyWithImpl;
  @useResult
  $Res call({String query});
}

/// @nodoc
class __$SearchHistoryCopyWithImpl<$Res>
    implements _$SearchHistoryCopyWith<$Res> {
  __$SearchHistoryCopyWithImpl(this._self, this._then);

  final _SearchHistory _self;
  final $Res Function(_SearchHistory) _then;

  /// Create a copy of HistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? query = null}) {
    return _then(
      _SearchHistory(
        null == query
            ? _self.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _ClearSearch implements HistoryEvent {
  const _ClearSearch();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _ClearSearch);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'HistoryEvent.clearSearch()';
  }
}

/// @nodoc

class _DeleteHistory implements HistoryEvent {
  const _DeleteHistory(this.id);

  final String id;

  /// Create a copy of HistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DeleteHistoryCopyWith<_DeleteHistory> get copyWith =>
      __$DeleteHistoryCopyWithImpl<_DeleteHistory>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DeleteHistory &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id);

  @override
  String toString() {
    return 'HistoryEvent.deleteHistory(id: $id)';
  }
}

/// @nodoc
abstract mixin class _$DeleteHistoryCopyWith<$Res>
    implements $HistoryEventCopyWith<$Res> {
  factory _$DeleteHistoryCopyWith(
    _DeleteHistory value,
    $Res Function(_DeleteHistory) _then,
  ) = __$DeleteHistoryCopyWithImpl;
  @useResult
  $Res call({String id});
}

/// @nodoc
class __$DeleteHistoryCopyWithImpl<$Res>
    implements _$DeleteHistoryCopyWith<$Res> {
  __$DeleteHistoryCopyWithImpl(this._self, this._then);

  final _DeleteHistory _self;
  final $Res Function(_DeleteHistory) _then;

  /// Create a copy of HistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? id = null}) {
    return _then(
      _DeleteHistory(
        null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _ClearAllHistory implements HistoryEvent {
  const _ClearAllHistory();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _ClearAllHistory);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'HistoryEvent.clearAllHistory()';
  }
}

/// @nodoc

class _RefreshHistory implements HistoryEvent {
  const _RefreshHistory();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _RefreshHistory);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'HistoryEvent.refreshHistory()';
  }
}

/// @nodoc
mixin _$HistoryState {
  List<HistoryEntity> get historyList;
  List<HistoryEntity> get filteredList;
  HistoryStatus get status;
  String get searchQuery;
  String get errorMessage;
  int get totalListeningTimeMs;

  /// Create a copy of HistoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HistoryStateCopyWith<HistoryState> get copyWith =>
      _$HistoryStateCopyWithImpl<HistoryState>(
        this as HistoryState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HistoryState &&
            const DeepCollectionEquality().equals(
              other.historyList,
              historyList,
            ) &&
            const DeepCollectionEquality().equals(
              other.filteredList,
              filteredList,
            ) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.totalListeningTimeMs, totalListeningTimeMs) ||
                other.totalListeningTimeMs == totalListeningTimeMs));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(historyList),
    const DeepCollectionEquality().hash(filteredList),
    status,
    searchQuery,
    errorMessage,
    totalListeningTimeMs,
  );

  @override
  String toString() {
    return 'HistoryState(historyList: $historyList, filteredList: $filteredList, status: $status, searchQuery: $searchQuery, errorMessage: $errorMessage, totalListeningTimeMs: $totalListeningTimeMs)';
  }
}

/// @nodoc
abstract mixin class $HistoryStateCopyWith<$Res> {
  factory $HistoryStateCopyWith(
    HistoryState value,
    $Res Function(HistoryState) _then,
  ) = _$HistoryStateCopyWithImpl;
  @useResult
  $Res call({
    List<HistoryEntity> historyList,
    List<HistoryEntity> filteredList,
    HistoryStatus status,
    String searchQuery,
    String errorMessage,
    int totalListeningTimeMs,
  });
}

/// @nodoc
class _$HistoryStateCopyWithImpl<$Res> implements $HistoryStateCopyWith<$Res> {
  _$HistoryStateCopyWithImpl(this._self, this._then);

  final HistoryState _self;
  final $Res Function(HistoryState) _then;

  /// Create a copy of HistoryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? historyList = null,
    Object? filteredList = null,
    Object? status = null,
    Object? searchQuery = null,
    Object? errorMessage = null,
    Object? totalListeningTimeMs = null,
  }) {
    return _then(
      _self.copyWith(
        historyList: null == historyList
            ? _self.historyList
            : historyList // ignore: cast_nullable_to_non_nullable
                  as List<HistoryEntity>,
        filteredList: null == filteredList
            ? _self.filteredList
            : filteredList // ignore: cast_nullable_to_non_nullable
                  as List<HistoryEntity>,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as HistoryStatus,
        searchQuery: null == searchQuery
            ? _self.searchQuery
            : searchQuery // ignore: cast_nullable_to_non_nullable
                  as String,
        errorMessage: null == errorMessage
            ? _self.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String,
        totalListeningTimeMs: null == totalListeningTimeMs
            ? _self.totalListeningTimeMs
            : totalListeningTimeMs // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [HistoryState].
extension HistoryStatePatterns on HistoryState {
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
    TResult Function(_HistoryState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HistoryState() when $default != null:
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
    TResult Function(_HistoryState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HistoryState():
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
    TResult? Function(_HistoryState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HistoryState() when $default != null:
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
      List<HistoryEntity> historyList,
      List<HistoryEntity> filteredList,
      HistoryStatus status,
      String searchQuery,
      String errorMessage,
      int totalListeningTimeMs,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HistoryState() when $default != null:
        return $default(
          _that.historyList,
          _that.filteredList,
          _that.status,
          _that.searchQuery,
          _that.errorMessage,
          _that.totalListeningTimeMs,
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
      List<HistoryEntity> historyList,
      List<HistoryEntity> filteredList,
      HistoryStatus status,
      String searchQuery,
      String errorMessage,
      int totalListeningTimeMs,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HistoryState():
        return $default(
          _that.historyList,
          _that.filteredList,
          _that.status,
          _that.searchQuery,
          _that.errorMessage,
          _that.totalListeningTimeMs,
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
      List<HistoryEntity> historyList,
      List<HistoryEntity> filteredList,
      HistoryStatus status,
      String searchQuery,
      String errorMessage,
      int totalListeningTimeMs,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HistoryState() when $default != null:
        return $default(
          _that.historyList,
          _that.filteredList,
          _that.status,
          _that.searchQuery,
          _that.errorMessage,
          _that.totalListeningTimeMs,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _HistoryState implements HistoryState {
  const _HistoryState({
    final List<HistoryEntity> historyList = const [],
    final List<HistoryEntity> filteredList = const [],
    this.status = HistoryStatus.initial,
    this.searchQuery = '',
    this.errorMessage = '',
    this.totalListeningTimeMs = 0,
  }) : _historyList = historyList,
       _filteredList = filteredList;

  final List<HistoryEntity> _historyList;
  @override
  @JsonKey()
  List<HistoryEntity> get historyList {
    if (_historyList is EqualUnmodifiableListView) return _historyList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_historyList);
  }

  final List<HistoryEntity> _filteredList;
  @override
  @JsonKey()
  List<HistoryEntity> get filteredList {
    if (_filteredList is EqualUnmodifiableListView) return _filteredList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_filteredList);
  }

  @override
  @JsonKey()
  final HistoryStatus status;
  @override
  @JsonKey()
  final String searchQuery;
  @override
  @JsonKey()
  final String errorMessage;
  @override
  @JsonKey()
  final int totalListeningTimeMs;

  /// Create a copy of HistoryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HistoryStateCopyWith<_HistoryState> get copyWith =>
      __$HistoryStateCopyWithImpl<_HistoryState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HistoryState &&
            const DeepCollectionEquality().equals(
              other._historyList,
              _historyList,
            ) &&
            const DeepCollectionEquality().equals(
              other._filteredList,
              _filteredList,
            ) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.totalListeningTimeMs, totalListeningTimeMs) ||
                other.totalListeningTimeMs == totalListeningTimeMs));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_historyList),
    const DeepCollectionEquality().hash(_filteredList),
    status,
    searchQuery,
    errorMessage,
    totalListeningTimeMs,
  );

  @override
  String toString() {
    return 'HistoryState(historyList: $historyList, filteredList: $filteredList, status: $status, searchQuery: $searchQuery, errorMessage: $errorMessage, totalListeningTimeMs: $totalListeningTimeMs)';
  }
}

/// @nodoc
abstract mixin class _$HistoryStateCopyWith<$Res>
    implements $HistoryStateCopyWith<$Res> {
  factory _$HistoryStateCopyWith(
    _HistoryState value,
    $Res Function(_HistoryState) _then,
  ) = __$HistoryStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    List<HistoryEntity> historyList,
    List<HistoryEntity> filteredList,
    HistoryStatus status,
    String searchQuery,
    String errorMessage,
    int totalListeningTimeMs,
  });
}

/// @nodoc
class __$HistoryStateCopyWithImpl<$Res>
    implements _$HistoryStateCopyWith<$Res> {
  __$HistoryStateCopyWithImpl(this._self, this._then);

  final _HistoryState _self;
  final $Res Function(_HistoryState) _then;

  /// Create a copy of HistoryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? historyList = null,
    Object? filteredList = null,
    Object? status = null,
    Object? searchQuery = null,
    Object? errorMessage = null,
    Object? totalListeningTimeMs = null,
  }) {
    return _then(
      _HistoryState(
        historyList: null == historyList
            ? _self._historyList
            : historyList // ignore: cast_nullable_to_non_nullable
                  as List<HistoryEntity>,
        filteredList: null == filteredList
            ? _self._filteredList
            : filteredList // ignore: cast_nullable_to_non_nullable
                  as List<HistoryEntity>,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as HistoryStatus,
        searchQuery: null == searchQuery
            ? _self.searchQuery
            : searchQuery // ignore: cast_nullable_to_non_nullable
                  as String,
        errorMessage: null == errorMessage
            ? _self.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String,
        totalListeningTimeMs: null == totalListeningTimeMs
            ? _self.totalListeningTimeMs
            : totalListeningTimeMs // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}
