import 'package:flutter/foundation.dart';

/// System-back handling for the shell-hosted [QuranPlayerWidget].
///
/// [RecitersRootBackScope] reads [interceptsSystemBackListenable] without
/// touching the player widget tree. The player sets the flag only while the
/// now-playing sheet is expanded; mini-player dismiss stays on swipe or the
/// overflow menu.
abstract final class QuranPlayerSystemBackCoordinator {
  static final ValueNotifier<bool> _intercepts = ValueNotifier<bool>(false);
  static void Function()? _handle;

  static bool get interceptsSystemBack => _intercepts.value;

  /// Listenable so [RecitersRootBackScope]'s [PopScope] rebuilds when the
  /// expanded-sheet intercept flag flips. Without this, [PopScope.canPop]
  /// stays stuck on the value computed when the cubit last fired.
  static ValueListenable<bool> get interceptsSystemBackListenable => _intercepts;

  static void setIntercepts(bool value) {
    _intercepts.value = value;
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
    _intercepts.value = false;
  }

  @visibleForTesting
  static void debugReset() {
    _intercepts.value = false;
    _handle = null;
  }
}
