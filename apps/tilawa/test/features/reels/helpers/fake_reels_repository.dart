import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa/features/reels/domain/entities/reel.dart';
import 'package:tilawa/features/reels/domain/entities/reel_category.dart';
import 'package:tilawa/features/reels/domain/entities/reel_engagement.dart';
import 'package:tilawa/features/reels/domain/entities/reel_reaction.dart';
import 'package:tilawa/features/reels/domain/repositories/reels_repository.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';

class FakeReelsRepository implements ReelsRepository {
  FakeReelsRepository({
    this.reels = const [],
    this.failGet = false,
  });

  List<Reel> reels;
  bool failGet;
  final Map<int, ReelEngagement> engagement = {};
  final Map<int, ReelReaction> reactions = {};
  final List<Reel> saved = [];

  @override
  ResultFuture<List<ReelCategory>> getCategories({
    required String language,
  }) async {
    return const Right([
      ReelCategory(id: 2, label: 'Prophet'),
      ReelCategory(id: 3, label: 'Faith'),
      ReelCategory(id: 4, label: 'Ramadan'),
    ]);
  }

  @override
  ResultFuture<Map<int, ReelEngagement>> getEngagementMap() async =>
      Right(Map.of(engagement));

  @override
  ResultFuture<Map<int, ReelReaction>> getReactions() async =>
      Right(Map.of(reactions));

  @override
  ResultFuture<List<Reel>> getReels({required String language}) async {
    if (failGet) return const Left(NetworkFailure('offline'));
    return Right(List.of(reels));
  }

  @override
  ResultFuture<List<Reel>> getSavedReels() async => Right(List.of(saved));

  @override
  ResultFuture<ReelReaction?> reactToReel(
    int reelId,
    ReelReaction reaction,
  ) async {
    final current = reactions[reelId];
    if (current == reaction) {
      reactions.remove(reelId);
      return const Right(null);
    }
    reactions[reelId] = reaction;
    return Right(reaction);
  }

  @override
  ResultFuture<void> recordView(int reelId, ReelViewKind kind) async {
    final e = engagement[reelId] ?? const ReelEngagement();
    engagement[reelId] = switch (kind) {
      ReelViewKind.started => e.copyWith(viewsStarted: e.viewsStarted + 1),
      ReelViewKind.completed => e.copyWith(
        viewsCompleted: e.viewsCompleted + 1,
      ),
    };
    return const Right(null);
  }

  @override
  ResultFuture<void> removeSavedReel(int reelId) async {
    saved.removeWhere((r) => r.id == reelId);
    return const Right(null);
  }

  @override
  ResultFuture<void> saveReel(Reel reel) async {
    saved.removeWhere((r) => r.id == reel.id);
    saved.add(reel.copyWith(isSaved: true));
    return const Right(null);
  }

  @override
  ResultFuture<void> shareReel(
    Reel reel, {
    required ReelShareMode mode,
  }) async {
    return const Right(null);
  }
}
