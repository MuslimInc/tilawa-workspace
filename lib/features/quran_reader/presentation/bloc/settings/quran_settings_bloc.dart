import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/load_reader_settings_use_case.dart';
import '../../../domain/usecases/save_reader_settings_use_case.dart';

part 'quran_settings_bloc.freezed.dart';
part 'quran_settings_event.dart';
part 'quran_settings_state.dart';

@injectable
class QuranSettingsBloc extends Bloc<QuranSettingsEvent, QuranSettingsState> {
  QuranSettingsBloc(
    this._loadReaderSettingsUseCase,
    this._saveReaderSettingsUseCase,
  ) : super(const QuranSettingsState()) {
    on<_LoadSettings>(_onLoadSettings);
    on<_UpdateSettings>(_onUpdateSettings);
    on<_UpdateFontSize>(_onUpdateFontSize);
    on<_ToggleTranslation>(_onToggleTranslation);
  }

  final LoadReaderSettingsUseCase _loadReaderSettingsUseCase;
  final SaveReaderSettingsUseCase _saveReaderSettingsUseCase;

  Future<void> _onLoadSettings(
    _LoadSettings event,
    Emitter<QuranSettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final Either<Failure, ReaderSettingsEntity> result =
        await _loadReaderSettingsUseCase.call();

    result.fold(
      (failure) {
        emit(
          state.copyWith(isLoading: false, errorMessage: failure.toString()),
        );
      },
      (settings) {
        emit(state.copyWith(isLoading: false, settings: settings));
      },
    );
  }

  Future<void> _onUpdateSettings(
    _UpdateSettings event,
    Emitter<QuranSettingsState> emit,
  ) async {
    await _saveReaderSettingsUseCase.call(settings: event.settings);
    emit(state.copyWith(settings: event.settings));
  }

  Future<void> _onUpdateFontSize(
    _UpdateFontSize event,
    Emitter<QuranSettingsState> emit,
  ) async {
    final ReaderSettingsEntity newSettings = state.settings.copyWith(
      fontSize: event.fontSize,
    );
    await _saveReaderSettingsUseCase.call(settings: newSettings);
    emit(state.copyWith(settings: newSettings));
  }

  Future<void> _onToggleTranslation(
    _ToggleTranslation event,
    Emitter<QuranSettingsState> emit,
  ) async {
    final ReaderSettingsEntity newSettings = state.settings.copyWith(
      showTranslation: !state.settings.showTranslation,
    );
    await _saveReaderSettingsUseCase.call(settings: newSettings);
    emit(state.copyWith(settings: newSettings));
  }
}
