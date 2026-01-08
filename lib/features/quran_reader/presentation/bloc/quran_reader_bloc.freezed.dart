// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quran_reader_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuranReaderEvent {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is QuranReaderEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'QuranReaderEvent()';
  }
}

/// @nodoc
class $QuranReaderEventCopyWith<$Res> {
  $QuranReaderEventCopyWith(
    QuranReaderEvent _,
    $Res Function(QuranReaderEvent) __,
  );
}

/// Adds pattern-matching-related methods to [QuranReaderEvent].
extension QuranReaderEventPatterns on QuranReaderEvent {
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
    TResult Function(_LoadSurah value)? loadSurah,
    TResult Function(_LoadPage value)? loadPage,
    TResult Function(_LoadSettings value)? loadSettings,
    TResult Function(_UpdateSettings value)? updateSettings,
    TResult Function(_UpdateFontSize value)? updateFontSize,
    TResult Function(_ToggleTranslation value)? toggleTranslation,
    TResult Function(_ScrollToAyah value)? scrollToAyah,
    TResult Function(_SaveLastRead value)? saveLastRead,
    TResult Function(_SearchAyahs value)? searchAyahs,
    TResult Function(_ClearSearch value)? clearSearch,
    TResult Function(_JumpToPage value)? jumpToPage,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LoadSurah() when loadSurah != null:
        return loadSurah(_that);
      case _LoadPage() when loadPage != null:
        return loadPage(_that);
      case _LoadSettings() when loadSettings != null:
        return loadSettings(_that);
      case _UpdateSettings() when updateSettings != null:
        return updateSettings(_that);
      case _UpdateFontSize() when updateFontSize != null:
        return updateFontSize(_that);
      case _ToggleTranslation() when toggleTranslation != null:
        return toggleTranslation(_that);
      case _ScrollToAyah() when scrollToAyah != null:
        return scrollToAyah(_that);
      case _SaveLastRead() when saveLastRead != null:
        return saveLastRead(_that);
      case _SearchAyahs() when searchAyahs != null:
        return searchAyahs(_that);
      case _ClearSearch() when clearSearch != null:
        return clearSearch(_that);
      case _JumpToPage() when jumpToPage != null:
        return jumpToPage(_that);
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
    required TResult Function(_LoadSurah value) loadSurah,
    required TResult Function(_LoadPage value) loadPage,
    required TResult Function(_LoadSettings value) loadSettings,
    required TResult Function(_UpdateSettings value) updateSettings,
    required TResult Function(_UpdateFontSize value) updateFontSize,
    required TResult Function(_ToggleTranslation value) toggleTranslation,
    required TResult Function(_ScrollToAyah value) scrollToAyah,
    required TResult Function(_SaveLastRead value) saveLastRead,
    required TResult Function(_SearchAyahs value) searchAyahs,
    required TResult Function(_ClearSearch value) clearSearch,
    required TResult Function(_JumpToPage value) jumpToPage,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadSurah():
        return loadSurah(_that);
      case _LoadPage():
        return loadPage(_that);
      case _LoadSettings():
        return loadSettings(_that);
      case _UpdateSettings():
        return updateSettings(_that);
      case _UpdateFontSize():
        return updateFontSize(_that);
      case _ToggleTranslation():
        return toggleTranslation(_that);
      case _ScrollToAyah():
        return scrollToAyah(_that);
      case _SaveLastRead():
        return saveLastRead(_that);
      case _SearchAyahs():
        return searchAyahs(_that);
      case _ClearSearch():
        return clearSearch(_that);
      case _JumpToPage():
        return jumpToPage(_that);
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
    TResult? Function(_LoadSurah value)? loadSurah,
    TResult? Function(_LoadPage value)? loadPage,
    TResult? Function(_LoadSettings value)? loadSettings,
    TResult? Function(_UpdateSettings value)? updateSettings,
    TResult? Function(_UpdateFontSize value)? updateFontSize,
    TResult? Function(_ToggleTranslation value)? toggleTranslation,
    TResult? Function(_ScrollToAyah value)? scrollToAyah,
    TResult? Function(_SaveLastRead value)? saveLastRead,
    TResult? Function(_SearchAyahs value)? searchAyahs,
    TResult? Function(_ClearSearch value)? clearSearch,
    TResult? Function(_JumpToPage value)? jumpToPage,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadSurah() when loadSurah != null:
        return loadSurah(_that);
      case _LoadPage() when loadPage != null:
        return loadPage(_that);
      case _LoadSettings() when loadSettings != null:
        return loadSettings(_that);
      case _UpdateSettings() when updateSettings != null:
        return updateSettings(_that);
      case _UpdateFontSize() when updateFontSize != null:
        return updateFontSize(_that);
      case _ToggleTranslation() when toggleTranslation != null:
        return toggleTranslation(_that);
      case _ScrollToAyah() when scrollToAyah != null:
        return scrollToAyah(_that);
      case _SaveLastRead() when saveLastRead != null:
        return saveLastRead(_that);
      case _SearchAyahs() when searchAyahs != null:
        return searchAyahs(_that);
      case _ClearSearch() when clearSearch != null:
        return clearSearch(_that);
      case _JumpToPage() when jumpToPage != null:
        return jumpToPage(_that);
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
    TResult Function(int surahNumber)? loadSurah,
    TResult Function(int pageNumber)? loadPage,
    TResult Function()? loadSettings,
    TResult Function(ReaderSettingsEntity settings)? updateSettings,
    TResult Function(double fontSize)? updateFontSize,
    TResult Function()? toggleTranslation,
    TResult Function(int ayahNumber)? scrollToAyah,
    TResult Function(int surahNumber, int? ayahNumber)? saveLastRead,
    TResult Function(String query)? searchAyahs,
    TResult Function()? clearSearch,
    TResult Function(int pageNumber)? jumpToPage,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LoadSurah() when loadSurah != null:
        return loadSurah(_that.surahNumber);
      case _LoadPage() when loadPage != null:
        return loadPage(_that.pageNumber);
      case _LoadSettings() when loadSettings != null:
        return loadSettings();
      case _UpdateSettings() when updateSettings != null:
        return updateSettings(_that.settings);
      case _UpdateFontSize() when updateFontSize != null:
        return updateFontSize(_that.fontSize);
      case _ToggleTranslation() when toggleTranslation != null:
        return toggleTranslation();
      case _ScrollToAyah() when scrollToAyah != null:
        return scrollToAyah(_that.ayahNumber);
      case _SaveLastRead() when saveLastRead != null:
        return saveLastRead(_that.surahNumber, _that.ayahNumber);
      case _SearchAyahs() when searchAyahs != null:
        return searchAyahs(_that.query);
      case _ClearSearch() when clearSearch != null:
        return clearSearch();
      case _JumpToPage() when jumpToPage != null:
        return jumpToPage(_that.pageNumber);
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
    required TResult Function(int surahNumber) loadSurah,
    required TResult Function(int pageNumber) loadPage,
    required TResult Function() loadSettings,
    required TResult Function(ReaderSettingsEntity settings) updateSettings,
    required TResult Function(double fontSize) updateFontSize,
    required TResult Function() toggleTranslation,
    required TResult Function(int ayahNumber) scrollToAyah,
    required TResult Function(int surahNumber, int? ayahNumber) saveLastRead,
    required TResult Function(String query) searchAyahs,
    required TResult Function() clearSearch,
    required TResult Function(int pageNumber) jumpToPage,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadSurah():
        return loadSurah(_that.surahNumber);
      case _LoadPage():
        return loadPage(_that.pageNumber);
      case _LoadSettings():
        return loadSettings();
      case _UpdateSettings():
        return updateSettings(_that.settings);
      case _UpdateFontSize():
        return updateFontSize(_that.fontSize);
      case _ToggleTranslation():
        return toggleTranslation();
      case _ScrollToAyah():
        return scrollToAyah(_that.ayahNumber);
      case _SaveLastRead():
        return saveLastRead(_that.surahNumber, _that.ayahNumber);
      case _SearchAyahs():
        return searchAyahs(_that.query);
      case _ClearSearch():
        return clearSearch();
      case _JumpToPage():
        return jumpToPage(_that.pageNumber);
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
    TResult? Function(int surahNumber)? loadSurah,
    TResult? Function(int pageNumber)? loadPage,
    TResult? Function()? loadSettings,
    TResult? Function(ReaderSettingsEntity settings)? updateSettings,
    TResult? Function(double fontSize)? updateFontSize,
    TResult? Function()? toggleTranslation,
    TResult? Function(int ayahNumber)? scrollToAyah,
    TResult? Function(int surahNumber, int? ayahNumber)? saveLastRead,
    TResult? Function(String query)? searchAyahs,
    TResult? Function()? clearSearch,
    TResult? Function(int pageNumber)? jumpToPage,
  }) {
    final _that = this;
    switch (_that) {
      case _LoadSurah() when loadSurah != null:
        return loadSurah(_that.surahNumber);
      case _LoadPage() when loadPage != null:
        return loadPage(_that.pageNumber);
      case _LoadSettings() when loadSettings != null:
        return loadSettings();
      case _UpdateSettings() when updateSettings != null:
        return updateSettings(_that.settings);
      case _UpdateFontSize() when updateFontSize != null:
        return updateFontSize(_that.fontSize);
      case _ToggleTranslation() when toggleTranslation != null:
        return toggleTranslation();
      case _ScrollToAyah() when scrollToAyah != null:
        return scrollToAyah(_that.ayahNumber);
      case _SaveLastRead() when saveLastRead != null:
        return saveLastRead(_that.surahNumber, _that.ayahNumber);
      case _SearchAyahs() when searchAyahs != null:
        return searchAyahs(_that.query);
      case _ClearSearch() when clearSearch != null:
        return clearSearch();
      case _JumpToPage() when jumpToPage != null:
        return jumpToPage(_that.pageNumber);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _LoadSurah implements QuranReaderEvent {
  const _LoadSurah(this.surahNumber);

  final int surahNumber;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LoadSurahCopyWith<_LoadSurah> get copyWith =>
      __$LoadSurahCopyWithImpl<_LoadSurah>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LoadSurah &&
            (identical(other.surahNumber, surahNumber) ||
                other.surahNumber == surahNumber));
  }

  @override
  int get hashCode => Object.hash(runtimeType, surahNumber);

  @override
  String toString() {
    return 'QuranReaderEvent.loadSurah(surahNumber: $surahNumber)';
  }
}

/// @nodoc
abstract mixin class _$LoadSurahCopyWith<$Res>
    implements $QuranReaderEventCopyWith<$Res> {
  factory _$LoadSurahCopyWith(
    _LoadSurah value,
    $Res Function(_LoadSurah) _then,
  ) = __$LoadSurahCopyWithImpl;
  @useResult
  $Res call({int surahNumber});
}

/// @nodoc
class __$LoadSurahCopyWithImpl<$Res> implements _$LoadSurahCopyWith<$Res> {
  __$LoadSurahCopyWithImpl(this._self, this._then);

  final _LoadSurah _self;
  final $Res Function(_LoadSurah) _then;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? surahNumber = null}) {
    return _then(
      _LoadSurah(
        null == surahNumber
            ? _self.surahNumber
            : surahNumber // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _LoadPage implements QuranReaderEvent {
  const _LoadPage(this.pageNumber);

  final int pageNumber;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LoadPageCopyWith<_LoadPage> get copyWith =>
      __$LoadPageCopyWithImpl<_LoadPage>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LoadPage &&
            (identical(other.pageNumber, pageNumber) ||
                other.pageNumber == pageNumber));
  }

  @override
  int get hashCode => Object.hash(runtimeType, pageNumber);

  @override
  String toString() {
    return 'QuranReaderEvent.loadPage(pageNumber: $pageNumber)';
  }
}

/// @nodoc
abstract mixin class _$LoadPageCopyWith<$Res>
    implements $QuranReaderEventCopyWith<$Res> {
  factory _$LoadPageCopyWith(_LoadPage value, $Res Function(_LoadPage) _then) =
      __$LoadPageCopyWithImpl;
  @useResult
  $Res call({int pageNumber});
}

/// @nodoc
class __$LoadPageCopyWithImpl<$Res> implements _$LoadPageCopyWith<$Res> {
  __$LoadPageCopyWithImpl(this._self, this._then);

  final _LoadPage _self;
  final $Res Function(_LoadPage) _then;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? pageNumber = null}) {
    return _then(
      _LoadPage(
        null == pageNumber
            ? _self.pageNumber
            : pageNumber // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _LoadSettings implements QuranReaderEvent {
  const _LoadSettings();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _LoadSettings);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'QuranReaderEvent.loadSettings()';
  }
}

/// @nodoc

class _UpdateSettings implements QuranReaderEvent {
  const _UpdateSettings(this.settings);

  final ReaderSettingsEntity settings;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UpdateSettingsCopyWith<_UpdateSettings> get copyWith =>
      __$UpdateSettingsCopyWithImpl<_UpdateSettings>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UpdateSettings &&
            (identical(other.settings, settings) ||
                other.settings == settings));
  }

  @override
  int get hashCode => Object.hash(runtimeType, settings);

  @override
  String toString() {
    return 'QuranReaderEvent.updateSettings(settings: $settings)';
  }
}

/// @nodoc
abstract mixin class _$UpdateSettingsCopyWith<$Res>
    implements $QuranReaderEventCopyWith<$Res> {
  factory _$UpdateSettingsCopyWith(
    _UpdateSettings value,
    $Res Function(_UpdateSettings) _then,
  ) = __$UpdateSettingsCopyWithImpl;
  @useResult
  $Res call({ReaderSettingsEntity settings});

  $ReaderSettingsEntityCopyWith<$Res> get settings;
}

/// @nodoc
class __$UpdateSettingsCopyWithImpl<$Res>
    implements _$UpdateSettingsCopyWith<$Res> {
  __$UpdateSettingsCopyWithImpl(this._self, this._then);

  final _UpdateSettings _self;
  final $Res Function(_UpdateSettings) _then;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? settings = null}) {
    return _then(
      _UpdateSettings(
        null == settings
            ? _self.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as ReaderSettingsEntity,
      ),
    );
  }

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReaderSettingsEntityCopyWith<$Res> get settings {
    return $ReaderSettingsEntityCopyWith<$Res>(_self.settings, (value) {
      return _then(_self.copyWith(settings: value));
    });
  }
}

/// @nodoc

class _UpdateFontSize implements QuranReaderEvent {
  const _UpdateFontSize(this.fontSize);

  final double fontSize;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UpdateFontSizeCopyWith<_UpdateFontSize> get copyWith =>
      __$UpdateFontSizeCopyWithImpl<_UpdateFontSize>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UpdateFontSize &&
            (identical(other.fontSize, fontSize) ||
                other.fontSize == fontSize));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fontSize);

  @override
  String toString() {
    return 'QuranReaderEvent.updateFontSize(fontSize: $fontSize)';
  }
}

/// @nodoc
abstract mixin class _$UpdateFontSizeCopyWith<$Res>
    implements $QuranReaderEventCopyWith<$Res> {
  factory _$UpdateFontSizeCopyWith(
    _UpdateFontSize value,
    $Res Function(_UpdateFontSize) _then,
  ) = __$UpdateFontSizeCopyWithImpl;
  @useResult
  $Res call({double fontSize});
}

/// @nodoc
class __$UpdateFontSizeCopyWithImpl<$Res>
    implements _$UpdateFontSizeCopyWith<$Res> {
  __$UpdateFontSizeCopyWithImpl(this._self, this._then);

  final _UpdateFontSize _self;
  final $Res Function(_UpdateFontSize) _then;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? fontSize = null}) {
    return _then(
      _UpdateFontSize(
        null == fontSize
            ? _self.fontSize
            : fontSize // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _ToggleTranslation implements QuranReaderEvent {
  const _ToggleTranslation();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _ToggleTranslation);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'QuranReaderEvent.toggleTranslation()';
  }
}

/// @nodoc

class _ScrollToAyah implements QuranReaderEvent {
  const _ScrollToAyah(this.ayahNumber);

  final int ayahNumber;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ScrollToAyahCopyWith<_ScrollToAyah> get copyWith =>
      __$ScrollToAyahCopyWithImpl<_ScrollToAyah>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ScrollToAyah &&
            (identical(other.ayahNumber, ayahNumber) ||
                other.ayahNumber == ayahNumber));
  }

  @override
  int get hashCode => Object.hash(runtimeType, ayahNumber);

  @override
  String toString() {
    return 'QuranReaderEvent.scrollToAyah(ayahNumber: $ayahNumber)';
  }
}

/// @nodoc
abstract mixin class _$ScrollToAyahCopyWith<$Res>
    implements $QuranReaderEventCopyWith<$Res> {
  factory _$ScrollToAyahCopyWith(
    _ScrollToAyah value,
    $Res Function(_ScrollToAyah) _then,
  ) = __$ScrollToAyahCopyWithImpl;
  @useResult
  $Res call({int ayahNumber});
}

/// @nodoc
class __$ScrollToAyahCopyWithImpl<$Res>
    implements _$ScrollToAyahCopyWith<$Res> {
  __$ScrollToAyahCopyWithImpl(this._self, this._then);

  final _ScrollToAyah _self;
  final $Res Function(_ScrollToAyah) _then;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? ayahNumber = null}) {
    return _then(
      _ScrollToAyah(
        null == ayahNumber
            ? _self.ayahNumber
            : ayahNumber // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _SaveLastRead implements QuranReaderEvent {
  const _SaveLastRead({required this.surahNumber, this.ayahNumber});

  final int surahNumber;
  final int? ayahNumber;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SaveLastReadCopyWith<_SaveLastRead> get copyWith =>
      __$SaveLastReadCopyWithImpl<_SaveLastRead>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SaveLastRead &&
            (identical(other.surahNumber, surahNumber) ||
                other.surahNumber == surahNumber) &&
            (identical(other.ayahNumber, ayahNumber) ||
                other.ayahNumber == ayahNumber));
  }

  @override
  int get hashCode => Object.hash(runtimeType, surahNumber, ayahNumber);

  @override
  String toString() {
    return 'QuranReaderEvent.saveLastRead(surahNumber: $surahNumber, ayahNumber: $ayahNumber)';
  }
}

/// @nodoc
abstract mixin class _$SaveLastReadCopyWith<$Res>
    implements $QuranReaderEventCopyWith<$Res> {
  factory _$SaveLastReadCopyWith(
    _SaveLastRead value,
    $Res Function(_SaveLastRead) _then,
  ) = __$SaveLastReadCopyWithImpl;
  @useResult
  $Res call({int surahNumber, int? ayahNumber});
}

/// @nodoc
class __$SaveLastReadCopyWithImpl<$Res>
    implements _$SaveLastReadCopyWith<$Res> {
  __$SaveLastReadCopyWithImpl(this._self, this._then);

  final _SaveLastRead _self;
  final $Res Function(_SaveLastRead) _then;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? surahNumber = null, Object? ayahNumber = freezed}) {
    return _then(
      _SaveLastRead(
        surahNumber: null == surahNumber
            ? _self.surahNumber
            : surahNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        ayahNumber: freezed == ayahNumber
            ? _self.ayahNumber
            : ayahNumber // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _SearchAyahs implements QuranReaderEvent {
  const _SearchAyahs(this.query);

  final String query;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SearchAyahsCopyWith<_SearchAyahs> get copyWith =>
      __$SearchAyahsCopyWithImpl<_SearchAyahs>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SearchAyahs &&
            (identical(other.query, query) || other.query == query));
  }

  @override
  int get hashCode => Object.hash(runtimeType, query);

  @override
  String toString() {
    return 'QuranReaderEvent.searchAyahs(query: $query)';
  }
}

/// @nodoc
abstract mixin class _$SearchAyahsCopyWith<$Res>
    implements $QuranReaderEventCopyWith<$Res> {
  factory _$SearchAyahsCopyWith(
    _SearchAyahs value,
    $Res Function(_SearchAyahs) _then,
  ) = __$SearchAyahsCopyWithImpl;
  @useResult
  $Res call({String query});
}

/// @nodoc
class __$SearchAyahsCopyWithImpl<$Res> implements _$SearchAyahsCopyWith<$Res> {
  __$SearchAyahsCopyWithImpl(this._self, this._then);

  final _SearchAyahs _self;
  final $Res Function(_SearchAyahs) _then;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? query = null}) {
    return _then(
      _SearchAyahs(
        null == query
            ? _self.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _ClearSearch implements QuranReaderEvent {
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
    return 'QuranReaderEvent.clearSearch()';
  }
}

/// @nodoc

class _JumpToPage implements QuranReaderEvent {
  const _JumpToPage(this.pageNumber);

  final int pageNumber;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$JumpToPageCopyWith<_JumpToPage> get copyWith =>
      __$JumpToPageCopyWithImpl<_JumpToPage>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _JumpToPage &&
            (identical(other.pageNumber, pageNumber) ||
                other.pageNumber == pageNumber));
  }

  @override
  int get hashCode => Object.hash(runtimeType, pageNumber);

  @override
  String toString() {
    return 'QuranReaderEvent.jumpToPage(pageNumber: $pageNumber)';
  }
}

/// @nodoc
abstract mixin class _$JumpToPageCopyWith<$Res>
    implements $QuranReaderEventCopyWith<$Res> {
  factory _$JumpToPageCopyWith(
    _JumpToPage value,
    $Res Function(_JumpToPage) _then,
  ) = __$JumpToPageCopyWithImpl;
  @useResult
  $Res call({int pageNumber});
}

/// @nodoc
class __$JumpToPageCopyWithImpl<$Res> implements _$JumpToPageCopyWith<$Res> {
  __$JumpToPageCopyWithImpl(this._self, this._then);

  final _JumpToPage _self;
  final $Res Function(_JumpToPage) _then;

  /// Create a copy of QuranReaderEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? pageNumber = null}) {
    return _then(
      _JumpToPage(
        null == pageNumber
            ? _self.pageNumber
            : pageNumber // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
mixin _$QuranReaderState {
  QuranReaderStatus get status;
  SurahContentEntity? get currentSurah;
  QuranPageEntity? get currentPage;
  Map<int, QuranPageEntity> get pages;
  ReaderSettingsEntity get settings;
  List<AyahEntity> get searchResults;
  List<SurahContentEntity> get surahSearchResults;
  String get searchQuery;
  bool get isSearching;
  int? get scrollToAyah;
  int? get jumpToPage;
  String get errorMessage;

  /// Create a copy of QuranReaderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $QuranReaderStateCopyWith<QuranReaderState> get copyWith =>
      _$QuranReaderStateCopyWithImpl<QuranReaderState>(
        this as QuranReaderState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is QuranReaderState &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.currentSurah, currentSurah) ||
                other.currentSurah == currentSurah) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            const DeepCollectionEquality().equals(other.pages, pages) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            const DeepCollectionEquality().equals(
              other.searchResults,
              searchResults,
            ) &&
            const DeepCollectionEquality().equals(
              other.surahSearchResults,
              surahSearchResults,
            ) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.isSearching, isSearching) ||
                other.isSearching == isSearching) &&
            (identical(other.scrollToAyah, scrollToAyah) ||
                other.scrollToAyah == scrollToAyah) &&
            (identical(other.jumpToPage, jumpToPage) ||
                other.jumpToPage == jumpToPage) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    currentSurah,
    currentPage,
    const DeepCollectionEquality().hash(pages),
    settings,
    const DeepCollectionEquality().hash(searchResults),
    const DeepCollectionEquality().hash(surahSearchResults),
    searchQuery,
    isSearching,
    scrollToAyah,
    jumpToPage,
    errorMessage,
  );

  @override
  String toString() {
    return 'QuranReaderState(status: $status, currentSurah: $currentSurah, currentPage: $currentPage, pages: $pages, settings: $settings, searchResults: $searchResults, surahSearchResults: $surahSearchResults, searchQuery: $searchQuery, isSearching: $isSearching, scrollToAyah: $scrollToAyah, jumpToPage: $jumpToPage, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class $QuranReaderStateCopyWith<$Res> {
  factory $QuranReaderStateCopyWith(
    QuranReaderState value,
    $Res Function(QuranReaderState) _then,
  ) = _$QuranReaderStateCopyWithImpl;
  @useResult
  $Res call({
    QuranReaderStatus status,
    SurahContentEntity? currentSurah,
    QuranPageEntity? currentPage,
    Map<int, QuranPageEntity> pages,
    ReaderSettingsEntity settings,
    List<AyahEntity> searchResults,
    List<SurahContentEntity> surahSearchResults,
    String searchQuery,
    bool isSearching,
    int? scrollToAyah,
    int? jumpToPage,
    String errorMessage,
  });

  $SurahContentEntityCopyWith<$Res>? get currentSurah;
  $QuranPageEntityCopyWith<$Res>? get currentPage;
  $ReaderSettingsEntityCopyWith<$Res> get settings;
}

/// @nodoc
class _$QuranReaderStateCopyWithImpl<$Res>
    implements $QuranReaderStateCopyWith<$Res> {
  _$QuranReaderStateCopyWithImpl(this._self, this._then);

  final QuranReaderState _self;
  final $Res Function(QuranReaderState) _then;

  /// Create a copy of QuranReaderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? currentSurah = freezed,
    Object? currentPage = freezed,
    Object? pages = null,
    Object? settings = null,
    Object? searchResults = null,
    Object? surahSearchResults = null,
    Object? searchQuery = null,
    Object? isSearching = null,
    Object? scrollToAyah = freezed,
    Object? jumpToPage = freezed,
    Object? errorMessage = null,
  }) {
    return _then(
      _self.copyWith(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as QuranReaderStatus,
        currentSurah: freezed == currentSurah
            ? _self.currentSurah
            : currentSurah // ignore: cast_nullable_to_non_nullable
                  as SurahContentEntity?,
        currentPage: freezed == currentPage
            ? _self.currentPage
            : currentPage // ignore: cast_nullable_to_non_nullable
                  as QuranPageEntity?,
        pages: null == pages
            ? _self.pages
            : pages // ignore: cast_nullable_to_non_nullable
                  as Map<int, QuranPageEntity>,
        settings: null == settings
            ? _self.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as ReaderSettingsEntity,
        searchResults: null == searchResults
            ? _self.searchResults
            : searchResults // ignore: cast_nullable_to_non_nullable
                  as List<AyahEntity>,
        surahSearchResults: null == surahSearchResults
            ? _self.surahSearchResults
            : surahSearchResults // ignore: cast_nullable_to_non_nullable
                  as List<SurahContentEntity>,
        searchQuery: null == searchQuery
            ? _self.searchQuery
            : searchQuery // ignore: cast_nullable_to_non_nullable
                  as String,
        isSearching: null == isSearching
            ? _self.isSearching
            : isSearching // ignore: cast_nullable_to_non_nullable
                  as bool,
        scrollToAyah: freezed == scrollToAyah
            ? _self.scrollToAyah
            : scrollToAyah // ignore: cast_nullable_to_non_nullable
                  as int?,
        jumpToPage: freezed == jumpToPage
            ? _self.jumpToPage
            : jumpToPage // ignore: cast_nullable_to_non_nullable
                  as int?,
        errorMessage: null == errorMessage
            ? _self.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }

  /// Create a copy of QuranReaderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SurahContentEntityCopyWith<$Res>? get currentSurah {
    if (_self.currentSurah == null) {
      return null;
    }

    return $SurahContentEntityCopyWith<$Res>(_self.currentSurah!, (value) {
      return _then(_self.copyWith(currentSurah: value));
    });
  }

  /// Create a copy of QuranReaderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $QuranPageEntityCopyWith<$Res>? get currentPage {
    if (_self.currentPage == null) {
      return null;
    }

    return $QuranPageEntityCopyWith<$Res>(_self.currentPage!, (value) {
      return _then(_self.copyWith(currentPage: value));
    });
  }

  /// Create a copy of QuranReaderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReaderSettingsEntityCopyWith<$Res> get settings {
    return $ReaderSettingsEntityCopyWith<$Res>(_self.settings, (value) {
      return _then(_self.copyWith(settings: value));
    });
  }
}

/// Adds pattern-matching-related methods to [QuranReaderState].
extension QuranReaderStatePatterns on QuranReaderState {
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
    TResult Function(_QuranReaderState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _QuranReaderState() when $default != null:
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
    TResult Function(_QuranReaderState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranReaderState():
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
    TResult? Function(_QuranReaderState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranReaderState() when $default != null:
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
      QuranReaderStatus status,
      SurahContentEntity? currentSurah,
      QuranPageEntity? currentPage,
      Map<int, QuranPageEntity> pages,
      ReaderSettingsEntity settings,
      List<AyahEntity> searchResults,
      List<SurahContentEntity> surahSearchResults,
      String searchQuery,
      bool isSearching,
      int? scrollToAyah,
      int? jumpToPage,
      String errorMessage,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _QuranReaderState() when $default != null:
        return $default(
          _that.status,
          _that.currentSurah,
          _that.currentPage,
          _that.pages,
          _that.settings,
          _that.searchResults,
          _that.surahSearchResults,
          _that.searchQuery,
          _that.isSearching,
          _that.scrollToAyah,
          _that.jumpToPage,
          _that.errorMessage,
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
      QuranReaderStatus status,
      SurahContentEntity? currentSurah,
      QuranPageEntity? currentPage,
      Map<int, QuranPageEntity> pages,
      ReaderSettingsEntity settings,
      List<AyahEntity> searchResults,
      List<SurahContentEntity> surahSearchResults,
      String searchQuery,
      bool isSearching,
      int? scrollToAyah,
      int? jumpToPage,
      String errorMessage,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranReaderState():
        return $default(
          _that.status,
          _that.currentSurah,
          _that.currentPage,
          _that.pages,
          _that.settings,
          _that.searchResults,
          _that.surahSearchResults,
          _that.searchQuery,
          _that.isSearching,
          _that.scrollToAyah,
          _that.jumpToPage,
          _that.errorMessage,
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
      QuranReaderStatus status,
      SurahContentEntity? currentSurah,
      QuranPageEntity? currentPage,
      Map<int, QuranPageEntity> pages,
      ReaderSettingsEntity settings,
      List<AyahEntity> searchResults,
      List<SurahContentEntity> surahSearchResults,
      String searchQuery,
      bool isSearching,
      int? scrollToAyah,
      int? jumpToPage,
      String errorMessage,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _QuranReaderState() when $default != null:
        return $default(
          _that.status,
          _that.currentSurah,
          _that.currentPage,
          _that.pages,
          _that.settings,
          _that.searchResults,
          _that.surahSearchResults,
          _that.searchQuery,
          _that.isSearching,
          _that.scrollToAyah,
          _that.jumpToPage,
          _that.errorMessage,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _QuranReaderState implements QuranReaderState {
  const _QuranReaderState({
    this.status = QuranReaderStatus.initial,
    this.currentSurah,
    this.currentPage,
    final Map<int, QuranPageEntity> pages = const {},
    this.settings = const ReaderSettingsEntity(),
    final List<AyahEntity> searchResults = const [],
    final List<SurahContentEntity> surahSearchResults = const [],
    this.searchQuery = '',
    this.isSearching = false,
    this.scrollToAyah,
    this.jumpToPage,
    this.errorMessage = '',
  }) : _pages = pages,
       _searchResults = searchResults,
       _surahSearchResults = surahSearchResults;

  @override
  @JsonKey()
  final QuranReaderStatus status;
  @override
  final SurahContentEntity? currentSurah;
  @override
  final QuranPageEntity? currentPage;
  final Map<int, QuranPageEntity> _pages;
  @override
  @JsonKey()
  Map<int, QuranPageEntity> get pages {
    if (_pages is EqualUnmodifiableMapView) return _pages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_pages);
  }

  @override
  @JsonKey()
  final ReaderSettingsEntity settings;
  final List<AyahEntity> _searchResults;
  @override
  @JsonKey()
  List<AyahEntity> get searchResults {
    if (_searchResults is EqualUnmodifiableListView) return _searchResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_searchResults);
  }

  final List<SurahContentEntity> _surahSearchResults;
  @override
  @JsonKey()
  List<SurahContentEntity> get surahSearchResults {
    if (_surahSearchResults is EqualUnmodifiableListView)
      return _surahSearchResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_surahSearchResults);
  }

  @override
  @JsonKey()
  final String searchQuery;
  @override
  @JsonKey()
  final bool isSearching;
  @override
  final int? scrollToAyah;
  @override
  final int? jumpToPage;
  @override
  @JsonKey()
  final String errorMessage;

  /// Create a copy of QuranReaderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$QuranReaderStateCopyWith<_QuranReaderState> get copyWith =>
      __$QuranReaderStateCopyWithImpl<_QuranReaderState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _QuranReaderState &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.currentSurah, currentSurah) ||
                other.currentSurah == currentSurah) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            const DeepCollectionEquality().equals(other._pages, _pages) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            const DeepCollectionEquality().equals(
              other._searchResults,
              _searchResults,
            ) &&
            const DeepCollectionEquality().equals(
              other._surahSearchResults,
              _surahSearchResults,
            ) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.isSearching, isSearching) ||
                other.isSearching == isSearching) &&
            (identical(other.scrollToAyah, scrollToAyah) ||
                other.scrollToAyah == scrollToAyah) &&
            (identical(other.jumpToPage, jumpToPage) ||
                other.jumpToPage == jumpToPage) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    currentSurah,
    currentPage,
    const DeepCollectionEquality().hash(_pages),
    settings,
    const DeepCollectionEquality().hash(_searchResults),
    const DeepCollectionEquality().hash(_surahSearchResults),
    searchQuery,
    isSearching,
    scrollToAyah,
    jumpToPage,
    errorMessage,
  );

  @override
  String toString() {
    return 'QuranReaderState(status: $status, currentSurah: $currentSurah, currentPage: $currentPage, pages: $pages, settings: $settings, searchResults: $searchResults, surahSearchResults: $surahSearchResults, searchQuery: $searchQuery, isSearching: $isSearching, scrollToAyah: $scrollToAyah, jumpToPage: $jumpToPage, errorMessage: $errorMessage)';
  }
}

/// @nodoc
abstract mixin class _$QuranReaderStateCopyWith<$Res>
    implements $QuranReaderStateCopyWith<$Res> {
  factory _$QuranReaderStateCopyWith(
    _QuranReaderState value,
    $Res Function(_QuranReaderState) _then,
  ) = __$QuranReaderStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    QuranReaderStatus status,
    SurahContentEntity? currentSurah,
    QuranPageEntity? currentPage,
    Map<int, QuranPageEntity> pages,
    ReaderSettingsEntity settings,
    List<AyahEntity> searchResults,
    List<SurahContentEntity> surahSearchResults,
    String searchQuery,
    bool isSearching,
    int? scrollToAyah,
    int? jumpToPage,
    String errorMessage,
  });

  @override
  $SurahContentEntityCopyWith<$Res>? get currentSurah;
  @override
  $QuranPageEntityCopyWith<$Res>? get currentPage;
  @override
  $ReaderSettingsEntityCopyWith<$Res> get settings;
}

/// @nodoc
class __$QuranReaderStateCopyWithImpl<$Res>
    implements _$QuranReaderStateCopyWith<$Res> {
  __$QuranReaderStateCopyWithImpl(this._self, this._then);

  final _QuranReaderState _self;
  final $Res Function(_QuranReaderState) _then;

  /// Create a copy of QuranReaderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? status = null,
    Object? currentSurah = freezed,
    Object? currentPage = freezed,
    Object? pages = null,
    Object? settings = null,
    Object? searchResults = null,
    Object? surahSearchResults = null,
    Object? searchQuery = null,
    Object? isSearching = null,
    Object? scrollToAyah = freezed,
    Object? jumpToPage = freezed,
    Object? errorMessage = null,
  }) {
    return _then(
      _QuranReaderState(
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as QuranReaderStatus,
        currentSurah: freezed == currentSurah
            ? _self.currentSurah
            : currentSurah // ignore: cast_nullable_to_non_nullable
                  as SurahContentEntity?,
        currentPage: freezed == currentPage
            ? _self.currentPage
            : currentPage // ignore: cast_nullable_to_non_nullable
                  as QuranPageEntity?,
        pages: null == pages
            ? _self._pages
            : pages // ignore: cast_nullable_to_non_nullable
                  as Map<int, QuranPageEntity>,
        settings: null == settings
            ? _self.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as ReaderSettingsEntity,
        searchResults: null == searchResults
            ? _self._searchResults
            : searchResults // ignore: cast_nullable_to_non_nullable
                  as List<AyahEntity>,
        surahSearchResults: null == surahSearchResults
            ? _self._surahSearchResults
            : surahSearchResults // ignore: cast_nullable_to_non_nullable
                  as List<SurahContentEntity>,
        searchQuery: null == searchQuery
            ? _self.searchQuery
            : searchQuery // ignore: cast_nullable_to_non_nullable
                  as String,
        isSearching: null == isSearching
            ? _self.isSearching
            : isSearching // ignore: cast_nullable_to_non_nullable
                  as bool,
        scrollToAyah: freezed == scrollToAyah
            ? _self.scrollToAyah
            : scrollToAyah // ignore: cast_nullable_to_non_nullable
                  as int?,
        jumpToPage: freezed == jumpToPage
            ? _self.jumpToPage
            : jumpToPage // ignore: cast_nullable_to_non_nullable
                  as int?,
        errorMessage: null == errorMessage
            ? _self.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }

  /// Create a copy of QuranReaderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SurahContentEntityCopyWith<$Res>? get currentSurah {
    if (_self.currentSurah == null) {
      return null;
    }

    return $SurahContentEntityCopyWith<$Res>(_self.currentSurah!, (value) {
      return _then(_self.copyWith(currentSurah: value));
    });
  }

  /// Create a copy of QuranReaderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $QuranPageEntityCopyWith<$Res>? get currentPage {
    if (_self.currentPage == null) {
      return null;
    }

    return $QuranPageEntityCopyWith<$Res>(_self.currentPage!, (value) {
      return _then(_self.copyWith(currentPage: value));
    });
  }

  /// Create a copy of QuranReaderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReaderSettingsEntityCopyWith<$Res> get settings {
    return $ReaderSettingsEntityCopyWith<$Res>(_self.settings, (value) {
      return _then(_self.copyWith(settings: value));
    });
  }
}
