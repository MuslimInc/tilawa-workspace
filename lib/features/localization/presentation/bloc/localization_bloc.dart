import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/core/config/language_config.dart';
import 'package:muzakri/features/localization/domain/usecases/get_current_language_use_case.dart';
import 'package:muzakri/features/localization/domain/usecases/set_language_use_case.dart';

part 'localization_event.dart';
part 'localization_state.dart';

@injectable
class LocalizationBloc
    extends HydratedBloc<LocalizationEvent, LocalizationState> {
  LocalizationBloc(this._getCurrentLanguageUseCase, this._setLanguageUseCase)
    : super(
        LocalizationState(locale: Locale(LanguageConfig.defaultLanguageCode)),
      ) {
    on<LoadLanguage>(_onLoadLanguage);
    on<ChangeLanguage>(_onChangeLanguage);
    // Load language from SharedPreferences on initialization
    add(const LoadLanguage());
  }

  final GetCurrentLanguageUseCase _getCurrentLanguageUseCase;
  final SetLanguageUseCase _setLanguageUseCase;

  @override
  LocalizationState? fromJson(Map<String, dynamic> json) {
    try {
      final languageCode = json['languageCode'] as String?;
      if (languageCode != null) {
        return LocalizationState(locale: Locale(languageCode));
      }
      return LocalizationState(
        locale: Locale(LanguageConfig.getDefaultLanguageCode()),
      );
    } catch (e) {
      return LocalizationState(
        locale: Locale(LanguageConfig.getDefaultLanguageCode()),
      );
    }
  }

  @override
  Map<String, dynamic>? toJson(LocalizationState state) {
    return {'languageCode': state.locale.languageCode};
  }

  Future<void> _onLoadLanguage(
    LoadLanguage event,
    Emitter<LocalizationState> emit,
  ) async {
    // Try to load language from SharedPreferences to sync with other parts of the app
    final result = await _getCurrentLanguageUseCase();
    await result.fold(
      (failure) async {
        // If loading fails, ensure SharedPreferences has the current state value
        await _setLanguageUseCase(state.locale.languageCode);
      },
      (languageCode) async {
        // Ensure SharedPreferences always has a value
        // This is critical so that other parts of the app (like RecitersRepository)
        // can read the language preference from SharedPreferences
        await _setLanguageUseCase(languageCode);

        // If the loaded language differs from current state, update it
        // This syncs SharedPreferences with HydratedStorage
        if (languageCode != state.locale.languageCode) {
          emit(LocalizationState(locale: Locale(languageCode)));
        }
      },
    );
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<LocalizationState> emit,
  ) async {
    // Save to SharedPreferences so other parts of the app can read it
    await _setLanguageUseCase(event.locale.languageCode);
    // Update the bloc state (which will also be persisted to HydratedStorage)
    emit(LocalizationState(locale: event.locale));
  }
}
