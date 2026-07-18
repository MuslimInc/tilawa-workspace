import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/reel.dart';
import '../entities/reel_category.dart';
import '../entities/reel_engagement.dart';
import '../entities/reel_reaction.dart';

/// How a reel view is recorded.
enum ReelViewKind { started, completed }

/// Share payload mode for the native share sheet.
enum ReelShareMode { link, text, file }

/// Contract for Islamic Reels catalog + local engagement.
abstract interface class ReelsRepository {
  ResultFuture<List<Reel>> getReels({required String language});

  ResultFuture<List<ReelCategory>> getCategories({required String language});

  ResultFuture<List<Reel>> getSavedReels();

  ResultFuture<void> saveReel(Reel reel);

  ResultFuture<void> removeSavedReel(int reelId);

  ResultFuture<ReelReaction?> reactToReel(int reelId, ReelReaction reaction);

  ResultFuture<void> shareReel(Reel reel, {required ReelShareMode mode});

  ResultFuture<void> recordView(int reelId, ReelViewKind kind);

  ResultFuture<Map<int, ReelEngagement>> getEngagementMap();

  ResultFuture<Map<int, ReelReaction>> getReactions();
}
