import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/get_last_read_position_use_case.dart';

import 'home_quran_resume_state.dart';

@injectable
class HomeQuranResumeCubit extends Cubit<HomeQuranResumeState> {
  HomeQuranResumeCubit(this._getLastReadPosition)
    : super(const HomeQuranResumeState());

  final GetLastReadPositionUseCase _getLastReadPosition;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: HomeQuranResumeStatus.loading,
        clearFailure: true,
      ),
    );

    final result = await _getLastReadPosition();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: HomeQuranResumeStatus.failure,
          failure: failure,
          clearPosition: true,
        ),
      ),
      (position) => emit(
        HomeQuranResumeState(
          status: HomeQuranResumeStatus.ready,
          surahNumber: position.surahNumber,
          ayahNumber: position.ayahNumber,
          page: position.page,
        ),
      ),
    );
  }
}
