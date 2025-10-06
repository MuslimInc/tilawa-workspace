import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'localization_event.dart';
part 'localization_state.dart';

class LocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> {
  static const String _languageKey = 'selected_language';

  LocalizationBloc() : super(const LocalizationState(locale: Locale('ar'))) {
    on<LoadLanguage>(_onLoadLanguage);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  Future<void> _onLoadLanguage(
    LoadLanguage event,
    Emitter<LocalizationState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode =
          prefs.getString(_languageKey) ?? 'ar'; // Default to Arabic

      final locale = Locale(languageCode);

      emit(LocalizationState(locale: locale));
    } catch (e) {
      // Fallback to Arabic if there's an error
      const locale = Locale('ar');
      emit(const LocalizationState(locale: locale));
    }
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<LocalizationState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, event.locale.languageCode);

      emit(LocalizationState(locale: event.locale));
    } catch (e) {
      // If saving fails, still emit the new state
      emit(LocalizationState(locale: event.locale));
    }
  }
}
