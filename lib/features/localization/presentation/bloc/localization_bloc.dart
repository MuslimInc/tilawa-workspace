import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/core/config/language_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'localization_event.dart';
part 'localization_state.dart';

@injectable
class LocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> {
  final SharedPreferences _prefs;

  LocalizationBloc(this._prefs)
    : super(
        LocalizationState(locale: Locale(LanguageConfig.defaultLanguageCode)),
      ) {
    on<LoadLanguage>(_onLoadLanguage);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  Future<void> _onLoadLanguage(
    LoadLanguage event,
    Emitter<LocalizationState> emit,
  ) async {
    try {
      final languageCode =
          _prefs.getString(LanguageConfig.languageKey) ??
          LanguageConfig.getDefaultLanguageCode();

      final locale = Locale(languageCode);

      emit(LocalizationState(locale: locale));
    } catch (e) {
      // Fallback to default language if there's an error
      final locale = Locale(LanguageConfig.getDefaultLanguageCode());
      emit(LocalizationState(locale: locale));
    }
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<LocalizationState> emit,
  ) async {
    try {
      await _prefs.setString(
        LanguageConfig.languageKey,
        event.locale.languageCode,
      );

      emit(LocalizationState(locale: event.locale));
    } catch (e) {
      // If saving fails, still emit the new state
      emit(LocalizationState(locale: event.locale));
    }
  }
}
