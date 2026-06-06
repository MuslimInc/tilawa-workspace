import 'package:injectable/injectable.dart';

import '../entities/in_app_update_action.dart';
import '../entities/in_app_update_availability.dart';
import '../entities/in_app_update_policy.dart';

/// Resolves the update UX from remote policy and Play availability.
@lazySingleton
class InAppUpdateStrategyResolver {
  /// Optional mode prefers flexible downloads. Forced mode uses immediate
  /// updates when Play allows them.
  InAppUpdateAction resolve({
    required InAppUpdatePolicy policy,
    required InAppUpdateAvailability availability,
  }) {
    if (!availability.updateAvailable) {
      return InAppUpdateAction.none;
    }

    if (policy.forceUpdate && availability.immediateUpdateAllowed) {
      return InAppUpdateAction.performImmediate;
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
