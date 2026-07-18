import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/reel.dart';
import '../../domain/entities/reel_category.dart';
import '../../domain/entities/reel_reaction.dart';
import '../../domain/repositories/reels_repository.dart';
import '../../domain/services/reel_ranking_service.dart';
import '../../domain/usecases/get_reel_categories_use_case.dart';
import '../../domain/usecases/get_reels_use_case.dart';
import '../../domain/usecases/react_to_reel_use_case.dart';
import '../../domain/usecases/record_reel_view_use_case.dart';
import '../../domain/usecases/save_reel_use_case.dart';
import '../../domain/usecases/share_reel_use_case.dart';
import 'reels_state.dart';

@injectable
class ReelsCubit extends Cubit<ReelsState> {
  ReelsCubit(
    this._getReels,
    this._getCategories,
    this._saveReel,
    this._removeSaved,
    this._reactToReel,
    this._shareReel,
    this._recordView,
  ) : super(const ReelsState());

  final GetReelsUseCase _getReels;
  final GetReelCategoriesUseCase _getCategories;
  final SaveReelUseCase _saveReel;
  final RemoveSavedReelUseCase _removeSaved;
  final ReactToReelUseCase _reactToReel;
  final ShareReelUseCase _shareReel;
  final RecordReelViewUseCase _recordView;

  List<Reel> _catalog = const [];
  final Set<int> _viewStartedIds = {};

  Future<void> load({
    required String language,
    required String allLabel,
    required Map<int, String> categoryLabels,
  }) async {
    emit(state.copyWith(status: ReelsStatus.loading, clearError: true));

    final categoriesResult = await _getCategories(
      GetReelCategoriesParams(language: language),
    );
    final List<ReelCategory> categories = categoriesResult.fold(
      (_) => [
        for (final e in categoryLabels.entries)
          ReelCategory(id: e.key, label: e.value),
      ],
      (list) => [
        for (final c in list)
          ReelCategory(
            id: c.id,
            label: categoryLabels[c.id] ?? c.label,
          ),
      ],
    );

    final result = await _getReels(
      GetReelsParams(language: language),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ReelsStatus.error,
          errorMessage: failure.message ?? 'error',
          categories: [
            ReelCategory(id: null, label: allLabel),
            ...categories,
          ],
        ),
      ),
      (data) {
        _catalog = data.reels;
        final filtered = state.selectedCategoryId == null
            ? data.reels
            : data.reels
                  .where((r) => r.categoryId == state.selectedCategoryId)
                  .toList();
        final ranked = ReelRankingService.sortForYou(
          filtered,
          data.engagement,
        );
        if (ranked.isEmpty) {
          emit(
            state.copyWith(
              status: ReelsStatus.empty,
              reels: const [],
              engagement: data.engagement,
              categories: [
                ReelCategory(id: null, label: allLabel),
                ...categories,
              ],
              currentIndex: 0,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            status: ReelsStatus.ready,
            reels: ranked,
            engagement: data.engagement,
            categories: [
              ReelCategory(id: null, label: allLabel),
              ...categories,
            ],
            currentIndex: 0,
            clearError: true,
          ),
        );
        _onPageVisible(0);
      },
    );
  }

  Future<void> selectCategory(int? categoryId) async {
    emit(
      state.copyWith(
        selectedCategoryId: categoryId,
        clearCategory: categoryId == null,
        status: ReelsStatus.loading,
      ),
    );
    // Re-filter from last language load via getReels again needs language —
    // filter locally from catalog if we have it, else caller reloads.
    if (_catalog.isEmpty) return;

    final filtered = categoryId == null
        ? List<Reel>.of(_catalog)
        : _catalog.where((r) => r.categoryId == categoryId).toList();
    final ranked = ReelRankingService.sortForYou(filtered, state.engagement);

    if (ranked.isEmpty) {
      emit(
        state.copyWith(
          status: ReelsStatus.empty,
          reels: const [],
          currentIndex: 0,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: ReelsStatus.ready,
        reels: ranked,
        currentIndex: 0,
      ),
    );
    _onPageVisible(0);
  }

  void onPageChanged(int index) {
    if (index < 0 || index >= state.reels.length) return;
    emit(state.copyWith(currentIndex: index, clearBurst: true));
    _onPageVisible(index);

    // Near end → append one reshuffled cycle (cap growth).
    if (index >= state.reels.length - 2 &&
        state.reels.length > 1 &&
        state.reels.length < _catalog.length * 3) {
      final selected = state.selectedCategoryId;
      final base = selected == null
          ? _catalog
          : _catalog.where((r) => r.categoryId == selected).toList();
      final more = ReelRankingService.reshuffle(base);
      if (more.isNotEmpty) {
        emit(state.copyWith(reels: [...state.reels, ...more]));
      }
    }
  }

  void _onPageVisible(int index) {
    if (index < 0 || index >= state.reels.length) return;
    final reel = state.reels[index];
    if (_viewStartedIds.add(reel.id)) {
      unawaited(
        _recordView(
          RecordReelViewParams(reelId: reel.id, kind: ReelViewKind.started),
        ),
      );
    }
  }

  Future<void> markCompleted(int reelId) {
    return _recordView(
      RecordReelViewParams(reelId: reelId, kind: ReelViewKind.completed),
    );
  }

  Future<void> toggleSave(Reel reel) async {
    if (reel.isSaved) {
      final result = await _removeSaved(RemoveSavedReelParams(reel.id));
      result.fold((_) {}, (_) => _patchReel(reel.id, isSaved: false));
    } else {
      final result = await _saveReel(SaveReelParams(reel));
      result.fold((_) {}, (_) => _patchReel(reel.id, isSaved: true));
    }
  }

  Future<void> react(int reelId, ReelReaction reaction) async {
    final result = await _reactToReel(
      ReactToReelParams(reelId: reelId, reaction: reaction),
    );
    result.fold((_) {}, (next) {
      _patchReel(
        reelId,
        reaction: next,
        clearReaction: next == null,
      );
      if (next != null) {
        emit(state.copyWith(burstReactionReelId: reelId));
      }
    });
  }

  Future<void> doubleTapReact(int reelId) => react(reelId, ReelReaction.loved);

  Future<void> share(Reel reel, {ReelShareMode mode = ReelShareMode.link}) {
    return _shareReel(ShareReelParams(reel: reel, mode: mode));
  }

  void clearBurst() => emit(state.copyWith(clearBurst: true));

  void _patchReel(
    int reelId, {
    bool? isSaved,
    ReelReaction? reaction,
    bool clearReaction = false,
  }) {
    final updated = state.reels
        .map(
          (r) => r.id == reelId
              ? r.copyWith(
                  isSaved: isSaved,
                  reaction: reaction,
                  clearReaction: clearReaction,
                )
              : r,
        )
        .toList();
    _catalog = _catalog
        .map(
          (r) => r.id == reelId
              ? r.copyWith(
                  isSaved: isSaved,
                  reaction: reaction,
                  clearReaction: clearReaction,
                )
              : r,
        )
        .toList();
    emit(state.copyWith(reels: updated));
  }
}
