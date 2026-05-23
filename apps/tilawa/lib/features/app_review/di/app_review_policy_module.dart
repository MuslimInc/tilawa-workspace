import 'package:injectable/injectable.dart';

import '../domain/entities/app_review_trigger_policy.dart';

/// Registers tunable review trigger thresholds.
@module
abstract class AppReviewPolicyModule {
  @lazySingleton
  AppReviewTriggerPolicy appReviewTriggerPolicy() =>
      const AppReviewTriggerPolicy();
}
