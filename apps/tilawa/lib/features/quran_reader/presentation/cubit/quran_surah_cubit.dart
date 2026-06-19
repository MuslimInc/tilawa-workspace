import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/entities.dart';
import '../../domain/usecases/get_surah_content_use_case.dart';
import '../../domain/usecases/load_reader_settings_use_case.dart';

sealed class QuranSurahState {
  const QuranSurahState();
}

final class QuranSurahInitial extends QuranSurahState {
  const QuranSurahInitial();
}

final class QuranSurahLoading extends QuranSurahState {
  const QuranSurahLoading();
}

final class QuranSurahLoaded extends QuranSurahState {
  const QuranSurahLoaded({
    required this.surah,
    required this.settings,
  });

  final SurahContentEntity surah;
  final ReaderSettingsEntity settings;
}

final class QuranSurahError extends QuranSurahState {
  const QuranSurahError(this.message);

  final String message;
}

@injectable
class QuranSurahCubit extends Cubit<QuranSurahState> {
  QuranSurahCubit(
    this._getSurahContentUseCase,
    this._loadReaderSettingsUseCase,
  ) : super(const QuranSurahInitial());

  final GetSurahContentUseCase _getSurahContentUseCase;
  final LoadReaderSettingsUseCase _loadReaderSettingsUseCase;

  Future<void> load(int surahNumber) async {
    emit(const QuranSurahLoading());

    final settingsResult = await _loadReaderSettingsUseCase();
    final ReaderSettingsEntity settings = settingsResult.fold(
      (_) => const ReaderSettingsEntity(),
      (value) => value,
    );

    final result = await _getSurahContentUseCase(surahNumber: surahNumber);
    result.fold(
      (Failure failure) =>
          emit(QuranSurahError(failure.message ?? 'Unknown error')),
      (surah) => emit(QuranSurahLoaded(surah: surah, settings: settings)),
    );
  }
}
