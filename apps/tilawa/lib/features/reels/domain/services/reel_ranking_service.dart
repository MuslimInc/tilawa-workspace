import '../entities/reel.dart';
import '../entities/reel_engagement.dart';

/// Local "For You" ranking — pure, no I/O.
///
/// score = views + likes*2 + saves*3 + shares*5
abstract final class ReelRankingService {
  static int score(ReelEngagement engagement) {
    final int likes = engagement.totalReactions;
    return engagement.viewsStarted +
        likes * 2 +
        engagement.saves * 3 +
        engagement.shares * 5;
  }

  /// Sort descending by score; ties keep stable order by id.
  static List<Reel> sortForYou(
    List<Reel> reels,
    Map<int, ReelEngagement> engagement,
  ) {
    final sorted = List<Reel>.of(reels);
    sorted.sort((a, b) {
      final int scoreA = score(engagement[a.id] ?? const ReelEngagement());
      final int scoreB = score(engagement[b.id] ?? const ReelEngagement());
      final int cmp = scoreB.compareTo(scoreA);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  /// Fisher–Yates shuffle with optional seed for deterministic tests.
  static List<Reel> reshuffle(List<Reel> reels, {int? seed}) {
    final list = List<Reel>.of(reels);
    var random = seed ?? DateTime.now().microsecondsSinceEpoch;
    for (var i = list.length - 1; i > 0; i--) {
      random = (random * 1103515245 + 12345) & 0x7fffffff;
      final j = random % (i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }
}
