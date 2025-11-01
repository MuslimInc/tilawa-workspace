import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/core/config/language_config.dart';

part 'localization_event.dart';
part 'localization_state.dart';

@injectable
class LocalizationBloc
    extends HydratedBloc<LocalizationEvent, LocalizationState> {
  LocalizationBloc()
    : super(
        LocalizationState(locale: Locale(LanguageConfig.defaultLanguageCode)),
      ) {
    on<LoadLanguage>(_onLoadLanguage);
    on<ChangeLanguage>(_onChangeLanguage);
  }

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
    // State will be loaded from storage automatically
    // This is kept for backward compatibility if needed
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<LocalizationState> emit,
  ) async {
    emit(LocalizationState(locale: event.locale));
  }
}
