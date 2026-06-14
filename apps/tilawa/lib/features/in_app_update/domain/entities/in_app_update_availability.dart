import 'package:flutter/foundation.dart';

/// Play Store update availability reported by the platform layer.
@immutable
class InAppUpdateAvailability {
  const InAppUpdateAvailability({
    required this.updateAvailable,
    required this.immediateUpdateAllowed,
    required this.flexibleUpdateAllowed,
    this.flexibleUpdateDownloaded = false,
  });

  const InAppUpdateAvailability.unavailable()
    : updateAvailable = false,
      immediateUpdateAllowed = false,
      flexibleUpdateAllowed = false,
      flexibleUpdateDownloaded = false;

  final bool updateAvailable;
  final bool immediateUpdateAllowed;
  final bool flexibleUpdateAllowed;

  /// Flexible update finished downloading and is ready to install.
  final bool flexibleUpdateDownloaded;
}
