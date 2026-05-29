import 'dart:async';

import 'package:injectable/injectable.dart';

import 'package:tilawa/features/app_review/domain/entities/app_review_prompt_moment.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_signal.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_trigger_manager.dart';
import 'package:tilawa/features/reciters/domain/services/reciter_engagement_reporter.dart';

@LazySingleton(as: ReciterEngagementReporter)
class AppReviewReciterEngagementReporter implements ReciterEngagementReporter {
  const AppReviewReciterEngagementReporter(this._triggerManager);

  final AppReviewTriggerManager _triggerManager;

  @override
  void reportFavoriteReciterAdded() {
    unawaited(
      _triggerManager.recordSignal(AppReviewSignal.favoriteReciterAdded),
    );
    unawaited(
      _triggerManager.tryPromptIfEligible(
        AppReviewPromptMoment.favoriteReciterAdded,
      ),
    );
  }
}
