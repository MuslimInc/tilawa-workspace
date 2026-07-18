import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../../domain/usecases/get_saved_reels_use_case.dart';
import '../../domain/usecases/save_reel_use_case.dart';
import 'saved_reels_state.dart';

@injectable
class SavedReelsCubit extends Cubit<SavedReelsState> {
  SavedReelsCubit(this._getSaved, this._removeSaved)
    : super(const SavedReelsState());

  final GetSavedReelsUseCase _getSaved;
  final RemoveSavedReelUseCase _removeSaved;

  Future<void> load() async {
    emit(state.copyWith(status: SavedReelsStatus.loading, clearError: true));
    final result = await _getSaved(const NoParams());
    result.fold(
      (f) => emit(
        state.copyWith(
          status: SavedReelsStatus.error,
          errorMessage: f.message ?? 'error',
        ),
      ),
      (reels) => emit(
        state.copyWith(
          status: reels.isEmpty
              ? SavedReelsStatus.empty
              : SavedReelsStatus.ready,
          reels: reels,
        ),
      ),
    );
  }

  Future<void> unsave(int reelId) async {
    final result = await _removeSaved(RemoveSavedReelParams(reelId));
    result.fold((_) {}, (_) {
      final next = state.reels.where((r) => r.id != reelId).toList();
      emit(
        state.copyWith(
          reels: next,
          status: next.isEmpty
              ? SavedReelsStatus.empty
              : SavedReelsStatus.ready,
        ),
      );
    });
  }
}
