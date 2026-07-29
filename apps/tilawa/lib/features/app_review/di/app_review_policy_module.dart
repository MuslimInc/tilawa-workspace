import 'package:get_it/get_it.dart';
import 'package:tilawa/core/di/get_it_idempotent.dart';

import '../domain/entities/app_review_trigger_policy.dart';

/// Registers tunable review trigger thresholds.
class AppReviewPolicyModule {
  AppReviewPolicyModule._();

  static void register(GetIt getIt) {
    getIt.registerLazySingletonIfAbsent<AppReviewTriggerPolicy>(
      () => const AppReviewTriggerPolicy(),
    );
  }
}
