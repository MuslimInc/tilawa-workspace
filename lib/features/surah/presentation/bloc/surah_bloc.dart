import 'dart:async';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/features/surah/domain/entities/surah_entity.dart';
import 'package:muzakri/features/surah/domain/usecases/check_surah_download_status_use_case.dart';
import 'package:muzakri/features/surah/domain/usecases/get_surahs_for_reciter_use_case.dart';
import 'package:muzakri/features/surah/domain/usecases/refresh_surah_status_use_case.dart';
import 'package:muzakri/features/surah/domain/usecases/update_surah_download_progress_use_case.dart';
import 'package:muzakri/features/surah/domain/usecases/update_surah_download_status_use_case.dart';

part 'surah_bloc.freezed.dart';
part 'surah_event.dart';
part 'surah_state.dart';

@injectable
class SurahBloc extends HydratedBloc<SurahEvent, SurahState> {
  SurahBloc(
    this._getSurahsForReciter,
    this._updateSurahDownloadStatus,
    this._updateSurahDownloadProgress,
    this._checkSurahDownloadStatus,
    this._refreshSurahStatus,
  ) : super(const SurahState.initial()) {
    on<LoadSurahsForReciter>(_onLoadSurahsForReciter);
    on<UpdateSurahDownloadStatus>(_onUpdateSurahDownloadStatus);
    on<UpdateSurahDownloadProgress>(_onUpdateSurahDownloadProgress);
    on<CheckSurahDownloadStatus>(_onCheckSurahDownloadStatus);
    on<RefreshSurahStatus>(_onRefreshSurahStatus);
  }

  final GetSurahsForReciterUseCase _getSurahsForReciter;
  final UpdateSurahDownloadStatusUseCase _updateSurahDownloadStatus;
  final UpdateSurahDownloadProgressUseCase _updateSurahDownloadProgress;
  final CheckSurahDownloadStatusUseCase _checkSurahDownloadStatus;
  final RefreshSurahStatusUseCase _refreshSurahStatus;

  Future<void> _onLoadSurahsForReciter(
    LoadSurahsForReciter event,
    Emitter<SurahState> emit,
  ) async {
    emit(const SurahState.loading());

    try {
      final surahs = await _getSurahsForReciter(event.reciterName);
      emit(SurahState.loaded(surahs: surahs, reciterName: event.reciterName));
    } catch (e) {
      emit(SurahState.error('Failed to load surahs: $e'));
    }
  }

  Future<void> _onUpdateSurahDownloadStatus(
    UpdateSurahDownloadStatus event,
    Emitter<SurahState> emit,
  ) async {
    try {
      await _updateSurahDownloadStatus(
        surahId: event.surahId,
        reciterName: event.reciterName,
        isDownloaded: event.isDownloaded,
      );

      // Get updated surah
      final surah = await _checkSurahDownloadStatus(
        surahId: event.surahId,
        reciterName: event.reciterName,
      );
      if (surah != null) {
        emit(SurahState.surahUpdated(surah: surah));
      }
    } catch (e) {
      emit(SurahState.error('Failed to update download status: $e'));
    }
  }

  Future<void> _onUpdateSurahDownloadProgress(
    UpdateSurahDownloadProgress event,
    Emitter<SurahState> emit,
  ) async {
    try {
      await _updateSurahDownloadProgress(
        surahId: event.surahId,
        reciterName: event.reciterName,
        isDownloading: event.isDownloading,
        progress: event.progress,
        downloadId: event.downloadId,
      );

      // Get updated surah
      final surah = await _checkSurahDownloadStatus(
        surahId: event.surahId,
        reciterName: event.reciterName,
      );
      if (surah != null) {
        emit(SurahState.surahUpdated(surah: surah));
      }
    } catch (e) {
      emit(SurahState.error('Failed to update download progress: $e'));
    }
  }

  Future<void> _onCheckSurahDownloadStatus(
    CheckSurahDownloadStatus event,
    Emitter<SurahState> emit,
  ) async {
    try {
      final surah = await _checkSurahDownloadStatus(
        surahId: event.surahId,
        reciterName: event.reciterName,
      );
      if (surah != null) {
        emit(SurahState.surahUpdated(surah: surah));
      }
    } catch (e) {
      emit(SurahState.error('Failed to check download status: $e'));
    }
  }

  Future<void> _onRefreshSurahStatus(
    RefreshSurahStatus event,
    Emitter<SurahState> emit,
  ) async {
    try {
      final surah = await _refreshSurahStatus(
        surahId: event.surahId,
        reciterName: event.reciterName,
      );
      if (surah != null) {
        emit(SurahState.surahUpdated(surah: surah));
      }
    } catch (e) {
      emit(SurahState.error('Failed to refresh surah status: $e'));
    }
  }

  @override
  SurahState? fromJson(Map<String, dynamic> json) {
    // Surah state should be loaded from repository, so we always start with initial state
    return const SurahState.initial();
  }

  @override
  Map<String, dynamic>? toJson(SurahState state) {
    // Don't persist complex surah data - will reload from repository
    return null;
  }
}
