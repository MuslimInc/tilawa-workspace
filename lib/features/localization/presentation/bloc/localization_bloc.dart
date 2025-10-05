import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/features/localization/domain/usecases/get_current_language.dart';
import 'package:muzakri/features/localization/domain/usecases/set_language.dart';
import 'package:muzakri/features/localization/presentation/bloc/localization_event.dart';
import 'package:muzakri/features/localization/presentation/bloc/localization_state.dart';

class LocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> {
  LocalizationBloc({
    required GetCurrentLanguage getCurrentLanguage,
    required SetLanguage setLanguage,
  }) : _getCurrentLanguage = getCurrentLanguage,
       _setLanguage = setLanguage,
       super(const LocalizationInitial()) {
    on<LoadLocalization>(_onLoadLocalization);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  final GetCurrentLanguage _getCurrentLanguage;
  final SetLanguage _setLanguage;

  Future<void> _onLoadLocalization(
    LoadLocalization event,
    Emitter<LocalizationState> emit,
  ) async {
    emit(const LocalizationLoading());

    final result = await _getCurrentLanguage();

    result.fold(
      (failure) =>
          emit(LocalizationError(failure.message ?? 'Failed to load language')),
      (language) => emit(
        LocalizationLoaded(
          currentLanguage: language,
          supportedLanguages: const ['en', 'ar'],
        ),
      ),
    );
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<LocalizationState> emit,
  ) async {
    final result = await _setLanguage(event.languageCode);

    result.fold(
      (failure) => emit(
        LocalizationError(failure.message ?? 'Failed to change language'),
      ),
      (_) {
        if (state is LocalizationLoaded) {
          final currentState = state as LocalizationLoaded;
          emit(currentState.copyWith(currentLanguage: event.languageCode));
        }
      },
    );
  }
}
