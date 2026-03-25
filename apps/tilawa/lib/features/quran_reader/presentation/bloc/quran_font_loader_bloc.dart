import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/check_fonts_downloaded_use_case.dart';
import '../../domain/usecases/download_quran_fonts_use_case.dart';
import '../../domain/usecases/load_quran_fonts_to_engine_use_case.dart';

part 'quran_font_loader_bloc.freezed.dart';

@freezed
class QuranFontLoaderEvent with _$QuranFontLoaderEvent {
  const factory QuranFontLoaderEvent.initialize() = _Initialize;
  const factory QuranFontLoaderEvent.updateProgress(double progress) =
      _UpdateProgress;
}

@freezed
class QuranFontLoaderState with _$QuranFontLoaderState {
  const factory QuranFontLoaderState.initial() = _Initial;
  const factory QuranFontLoaderState.checking() = _Checking;
  const factory QuranFontLoaderState.downloading(double progress) =
      _Downloading;
  const factory QuranFontLoaderState.registering() = _Registering;
  const factory QuranFontLoaderState.success() = _Success;
  const factory QuranFontLoaderState.error(String message) = _Error;
}

@injectable
class QuranFontLoaderBloc
    extends Bloc<QuranFontLoaderEvent, QuranFontLoaderState> {
  QuranFontLoaderBloc(
    this._checkFontsDownloadedUseCase,
    this._downloadQuranFontsUseCase,
    this._loadQuranFontsToEngineUseCase,
  ) : super(const QuranFontLoaderState.initial()) {
    on<_Initialize>(_onInitialize);
    on<_UpdateProgress>(_onUpdateProgress);
  }

  final CheckFontsDownloadedUseCase _checkFontsDownloadedUseCase;
  final DownloadQuranFontsUseCase _downloadQuranFontsUseCase;
  final LoadQuranFontsToEngineUseCase _loadQuranFontsToEngineUseCase;

  Future<void> _onInitialize(
    _Initialize event,
    Emitter<QuranFontLoaderState> emit,
  ) async {
    if (_loadQuranFontsToEngineUseCase.hasLoadedFontsToEngine) {
      emit(const QuranFontLoaderState.success());
      return;
    }

    emit(const QuranFontLoaderState.checking());

    try {
      final isDownloaded = await _checkFontsDownloadedUseCase();
      if (!isDownloaded) {
        emit(const QuranFontLoaderState.downloading(0));
        var lastEmittedProgress = 0.0;
        await _downloadQuranFontsUseCase(
          onProgress: (progress) {
            if (isClosed) return;
            final currentPercent = (progress * 100).floor();
            final lastPercent = (lastEmittedProgress * 100).floor();
            if (currentPercent > lastPercent || progress >= 1.0) {
              lastEmittedProgress = progress;
              emit(QuranFontLoaderState.downloading(progress));
            }
          },
        );
      }

      emit(const QuranFontLoaderState.registering());
      await _loadQuranFontsToEngineUseCase();
      emit(const QuranFontLoaderState.success());
    } catch (e) {
      emit(QuranFontLoaderState.error(e.toString()));
    }
  }

  void _onUpdateProgress(
    _UpdateProgress event,
    Emitter<QuranFontLoaderState> emit,
  ) {
    emit(QuranFontLoaderState.downloading(event.progress));
  }
}
