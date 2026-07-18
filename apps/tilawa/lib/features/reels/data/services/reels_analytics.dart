import 'package:injectable/injectable.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../domain/entities/reel_reaction.dart';
import '../../domain/repositories/reels_repository.dart';

/// Thin analytics facade for reels — swappable / testable.
@lazySingleton
class ReelsAnalytics {
  ReelsAnalytics(this._analytics);

  final AnalyticsService _analytics;

  Future<void> viewStarted(int reelId) => _analytics.logEvent(
    AnalyticsEvents.reelViewStart,
    parameters: {AnalyticsParams.reelId: reelId},
  );

  Future<void> viewCompleted(int reelId) => _analytics.logEvent(
    AnalyticsEvents.reelViewComplete,
    parameters: {AnalyticsParams.reelId: reelId},
  );

  Future<void> reaction(int reelId, ReelReaction reaction) =>
      _analytics.logEvent(
        AnalyticsEvents.reelReaction,
        parameters: {
          AnalyticsParams.reelId: reelId,
          AnalyticsParams.reactionType: reaction.analyticsValue,
        },
      );

  Future<void> save(int reelId, {required bool saved}) => _analytics.logEvent(
    AnalyticsEvents.reelSave,
    parameters: {
      AnalyticsParams.reelId: reelId,
      AnalyticsParams.action: saved ? 'save' : 'unsave',
    },
  );

  Future<void> share(int reelId, ReelShareMode mode) => _analytics.logEvent(
    AnalyticsEvents.reelShare,
    parameters: {
      AnalyticsParams.reelId: reelId,
      AnalyticsParams.shareMode: mode.name,
    },
  );
}
