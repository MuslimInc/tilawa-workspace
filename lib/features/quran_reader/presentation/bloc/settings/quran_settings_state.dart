part of 'quran_settings_bloc.dart';

@freezed
abstract class QuranSettingsState with _$QuranSettingsState {
  const factory QuranSettingsState({
    @Default(ReaderSettingsEntity()) ReaderSettingsEntity settings,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _QuranSettingsState;
}
