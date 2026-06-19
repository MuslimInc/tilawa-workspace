import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/entities.dart';
import '../../domain/usecases/load_reader_settings_use_case.dart';
import '../../domain/usecases/save_reader_settings_use_case.dart';

/// Cubit that owns [ReaderSettingsEntity] state exclusively.
///
/// Extracted from [QuranReaderBloc] so that settings changes do not emit
/// on the same stream as page-navigation events — preventing [QuranPageView]
/// from rebuilding on every page swipe just because settings are in scope.
@lazySingleton
class QuranSettingsCubit extends Cubit<ReaderSettingsEntity> {
  QuranSettingsCubit(this._loadSettings, this._saveSettings)
    : super(const ReaderSettingsEntity());

  final LoadReaderSettingsUseCase _loadSettings;
  final SaveReaderSettingsUseCase _saveSettings;

  Future<void> load() async {
    final result = await _loadSettings();
    result.fold((_) {}, (settings) => emit(settings));
  }

  Future<void> update(ReaderSettingsEntity settings) async {
    await _saveSettings(settings: settings);
    emit(settings);
  }

  Future<void> updateFontSize(double fontSize) =>
      update(state.copyWith(fontSize: fontSize));

  Future<void> toggleTranslation() =>
      update(state.copyWith(showTranslation: !state.showTranslation));

  Future<void> setViewMode(QuranReaderViewMode viewMode) =>
      update(state.copyWith(viewMode: viewMode));
}
