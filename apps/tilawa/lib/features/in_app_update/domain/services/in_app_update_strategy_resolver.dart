import 'package:injectable/injectable.dart';

import '../entities/in_app_update_action.dart';
import '../entities/in_app_update_availability.dart';
import '../entities/in_app_update_policy.dart';

/// Resolves the update UX from remote policy and Play availability.
@lazySingleton
class InAppUpdateStrategyResolver {
  /// Optional mode prefers flexible downloads. Forced mode uses immediate
  /// updates when Play allows them, then flexible, then Play Store listing.
  InAppUpdateAction resolve({
    required InAppUpdatePolicy policy,
    required InAppUpdateAvailability availability,
  }) {
    if (availability.flexibleUpdateDownloaded) {
      return InAppUpdateAction.promptFlexibleRestart;
    }

    if (!availability.updateAvailable) {
      return InAppUpdateAction.none;
    }

    if (policy.forceUpdate) {
      if (availability.immediateUpdateAllowed) {
        return InAppUpdateAction.performImmediate;
      }
      if (availability.flexibleUpdateAllowed) {
        return InAppUpdateAction.startFlexible;
      }
      return InAppUpdateAction.offerOptionalImmediate;
    }

    if (availability.flexibleUpdateAllowed) {
      return InAppUpdateAction.startFlexible;
    }

    if (availability.immediateUpdateAllowed) {
      return InAppUpdateAction.offerOptionalImmediate;
    }

    return InAppUpdateAction.none;
  }
}
