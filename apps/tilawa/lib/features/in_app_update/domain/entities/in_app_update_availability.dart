import 'package:flutter/foundation.dart';

/// Play Store update availability reported by the platform layer.
@immutable
class InAppUpdateAvailability {
  const InAppUpdateAvailability({
    required this.updateAvailable,
    required this.immediateUpdateAllowed,
    required this.flexibleUpdateAllowed,
  });

  const InAppUpdateAvailability.unavailable()
    : updateAvailable = false,
      immediateUpdateAllowed = false,
      flexibleUpdateAllowed = false;

  final bool updateAvailable;
  final bool immediateUpdateAllowed;
  final bool flexibleUpdateAllowed;
}
