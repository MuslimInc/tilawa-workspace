import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/reels/domain/entities/reel.dart';
import 'package:tilawa/features/reels/domain/entities/reel_engagement.dart';
import 'package:tilawa/features/reels/domain/entities/reel_reaction.dart';
import 'package:tilawa/features/reels/domain/services/reel_ranking_service.dart';

void main() {
  group('ReelRankingService', () {
    test('score weights views, likes, saves, shares', () {
      const engagement = ReelEngagement(
        viewsStarted: 10,
        reactionCounts: {ReelReaction.loved: 3},
        saves: 2,
        shares: 1,
      );
      // 10 + 3*2 + 2*3 + 1*5 = 10+6+6+5 = 27
      check(ReelRankingService.score(engagement)).equals(27);
    });

    test('sortForYou orders by descending score', () {
      final reels = [
        const Reel(
          id: 1,
          sheikhId: 1,
          sheikhName: 'A',
          videoUrl: 'u',
          thumbUrl: 't',
          categoryId: 2,
        ),
        const Reel(
          id: 2,
          sheikhId: 1,
          sheikhName: 'B',
          videoUrl: 'u',
          thumbUrl: 't',
          categoryId: 2,
        ),
      ];
      final engagement = {
        1: const ReelEngagement(viewsStarted: 1),
        2: const ReelEngagement(shares: 2), // score 10
      };
      final sorted = ReelRankingService.sortForYou(reels, engagement);
      check(sorted.first.id).equals(2);
      check(sorted.last.id).equals(1);
    });

    test('reshuffle is deterministic with seed', () {
      final reels = [
        for (var i = 0; i < 5; i++)
          Reel(
            id: i,
            sheikhId: 1,
            sheikhName: 'S',
            videoUrl: 'u',
            thumbUrl: 't',
            categoryId: 2,
          ),
      ];
      final a = ReelRankingService.reshuffle(reels, seed: 42);
      final b = ReelRankingService.reshuffle(reels, seed: 42);
      check(
        a.map((r) => r.id).toList(),
      ).deepEquals(b.map((r) => r.id).toList());
    });
  });
}
