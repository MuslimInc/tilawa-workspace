part of 'quran_settings_bloc.dart';

@freezed
class QuranSettingsEvent with _$QuranSettingsEvent {
  const factory QuranSettingsEvent.loadSettings() = _LoadSettings;
  const factory QuranSettingsEvent.updateSettings(
    ReaderSettingsEntity settings,
  ) = _UpdateSettings;
  const factory QuranSettingsEvent.updateFontSize(double fontSize) =
      _UpdateFontSize;
  const factory QuranSettingsEvent.toggleTranslation() = _ToggleTranslation;
}
