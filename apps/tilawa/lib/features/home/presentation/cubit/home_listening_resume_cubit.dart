import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/repositories/history_repository.dart';

import 'home_listening_resume_state.dart';

@injectable
class HomeListeningResumeCubit extends Cubit<HomeListeningResumeState> {
  HomeListeningResumeCubit(this._historyRepository)
    : super(const HomeListeningResumeState());

  final HistoryRepository _historyRepository;

  Future<void> load() async {
    emit(state.copyWith(status: HomeListeningResumeStatus.loading));

    try {
      final List<HistoryEntity> history = await _historyRepository
          .getRecentHistory(limit: 1);
      if (history.isEmpty) {
        emit(
          const HomeListeningResumeState(
            status: HomeListeningResumeStatus.ready,
          ),
        );
        return;
      }

      final HistoryEntity latest = history.first;
      emit(
        HomeListeningResumeState(
          status: HomeListeningResumeStatus.ready,
          reciterName: latest.reciterName,
          surahName: latest.surahNameEn,
          historyId: latest.id,
          audioUrl: latest.audioUrl,
          surahId: latest.surahId,
          reciterId: latest.reciterId,
          moshafId: latest.moshafId,
          moshafName: latest.moshafName,
          lastPositionMs: latest.lastPositionMs,
          durationMs: latest.durationMs,
          artworkUrl: latest.artworkUrl,
        ),
      );
    } catch (_) {
      emit(
        const HomeListeningResumeState(
          status: HomeListeningResumeStatus.ready,
        ),
      );
    }
  }
}
