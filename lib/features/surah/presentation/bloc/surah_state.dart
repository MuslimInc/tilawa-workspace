part of 'surah_bloc.dart';

@freezed
sealed class SurahState with _$SurahState {
  const factory SurahState.initial() = SurahInitial;

  const factory SurahState.loading() = SurahLoading;

  const factory SurahState.loaded({
    required List<SurahEntity> surahs,
    required String reciterName,
  }) = SurahLoaded;

  const factory SurahState.error(String message) = SurahError;

  const factory SurahState.surahUpdated({required SurahEntity surah}) =
      SurahUpdated;
}
