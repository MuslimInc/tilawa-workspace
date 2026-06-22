import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_athkar_compact_state.dart';
import 'home_listening_resume_state.dart';
import 'home_primary_action_state.dart';
import 'home_quran_resume_state.dart';

/// Chooses the featured Home primary action from resume cubit snapshots.
class HomePrimaryActionCubit extends Cubit<HomePrimaryActionState> {
  HomePrimaryActionCubit() : super(const HomePrimaryActionState());

  void recompute({
    required HomeQuranResumeState quran,
    required HomeListeningResumeState listening,
    required HomeAthkarCompactState athkar,
  }) {
    final HomeAthkarRowState? urgentAthkarRow = _urgentAthkarRow(athkar);
    emit(
      HomePrimaryActionState(
        kind: _selectKind(
          quran: quran,
          listening: listening,
          urgentAthkarRow: urgentAthkarRow,
        ),
        urgentAthkarRow: urgentAthkarRow,
      ),
    );
  }

  HomePrimaryActionKind _selectKind({
    required HomeQuranResumeState quran,
    required HomeListeningResumeState listening,
    required HomeAthkarRowState? urgentAthkarRow,
  }) {
    final bool hasReadingProgress = _hasReadingProgress(quran);
    if (listening.isVisible && !hasReadingProgress) {
      return HomePrimaryActionKind.listening;
    }
    if (urgentAthkarRow != null) {
      return HomePrimaryActionKind.athkar;
    }
    return HomePrimaryActionKind.quran;
  }

  bool _hasReadingProgress(HomeQuranResumeState quran) {
    if (quran.status != HomeQuranResumeStatus.ready ||
        !quran.hasResumePosition) {
      return false;
    }
    final int? page = quran.page;
    if (page == null || page <= 1) {
      return quran.surahNumber != null;
    }
    return true;
  }

  HomeAthkarRowState? _urgentAthkarRow(HomeAthkarCompactState athkar) {
    if (athkar.status != HomeAthkarRowStatus.ready || athkar.rows.isEmpty) {
      return null;
    }
    for (final HomeAthkarRowState row in athkar.rows) {
      if (row.completion != HomeAthkarCompletionState.done) {
        return row;
      }
    }
    return null;
  }
}
