import 'package:injectable/injectable.dart';

import '../entities/forced_update_decision.dart';
import '../entities/forced_update_host_platform.dart';
import '../entities/forced_update_policy.dart';

/// Pure comparison of installed build number vs remote platform minimum.
@lazySingleton
class ForcedUpdateEvaluator {
  const ForcedUpdateEvaluator();

  ForcedUpdateDecision evaluate({
    required ForcedUpdatePolicy policy,
    required String installedBuildNumber,
    required ForcedUpdateHostPlatform platform,
  }) {
    final int? minBuild = switch (platform) {
      ForcedUpdateHostPlatform.android => policy.androidMinBuildNumber,
      ForcedUpdateHostPlatform.ios => policy.iosMinBuildNumber,
      ForcedUpdateHostPlatform.other => null,
    };

    if (minBuild == null) {
      return ForcedUpdateDecision.none;
    }

    final int? installed = int.tryParse(installedBuildNumber.trim());
    if (installed == null) {
      return ForcedUpdateDecision.none;
    }

    if (installed < minBuild) {
      return ForcedUpdateDecision.required;
    }

    return ForcedUpdateDecision.none;
  }
}
