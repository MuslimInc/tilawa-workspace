import 'package:flutter/foundation.dart';

/// System-back handling for the shell-hosted [QuranPlayerWidget].
///
/// [RecitersRootBackScope] reads [interceptsSystemBack] without touching the
/// player widget tree. The player sets the flag only while the now-playing
/// sheet is expanded; mini-player dismiss stays on swipe or the overflow menu.
abstract final class QuranPlayerSystemBackCoordinator {
  static bool _intercepts = false;
  static void Function()? _handle;

  static bool get interceptsSystemBack => _intercepts;

  static void setIntercepts(bool value) {
    _intercepts = value;
  }

  static void handleSystemBack() => _handle?.call();

  static void bind({required void Function() handle}) {
    _handle = handle;
  }

  static void unbind({required void Function() handle}) {
    if (!identical(_handle, handle)) {
      return;
    }
    _handle = null;
    _intercepts = false;
  }

  @visibleForTesting
  static void debugReset() {
    _intercepts = false;
    _handle = null;
  }
}
