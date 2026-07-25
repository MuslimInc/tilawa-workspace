import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Developer settings entry that wipes [SharedPreferencesAsync] so splash
/// follows the first-install path (language welcome → onboarding).
class ClearAppPreferencesDebugTile extends StatelessWidget {
  const ClearAppPreferencesDebugTile({
    super.key,
    this.isLast = false,
    this.debugMode = kDebugMode,
    this.clearPreferences,
    this.onRestartJourney,
  });

  final bool isLast;
  final bool debugMode;

  /// Override for tests; defaults to clearing the DI [SharedPreferencesAsync].
  final Future<void> Function()? clearPreferences;

  /// Override for tests; defaults to navigating to [SplashRoute].
  final VoidCallback? onRestartJourney;

  @override
  Widget build(BuildContext context) {
    if (!debugMode) {
      return const SizedBox.shrink();
    }

    return TilawaSettingsTile(
      title: 'Clear app preferences',
      subtitle: 'Reset first-install journey via splash',
      showDivider: !isLast,
      onTap: () => _onTap(context),
    );
  }

  Future<void> _onTap(BuildContext context) async {
    final bool? confirmed = await showTilawaConfirmDialog(
      context: context,
      title: 'Clear app preferences?',
      message:
          'Wipes local preferences so splash follows the first-install path '
          '(language welcome → onboarding). Auth session may still remain.',
      confirmLabel: 'Clear',
      cancelLabel: 'Cancel',
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final Future<void> Function() clear =
        clearPreferences ?? () => getIt<SharedPreferencesAsync>().clear();
    await clear();
    if (!context.mounted) {
      return;
    }

    final VoidCallback restart =
        onRestartJourney ?? () => const SplashRoute().go(context);
    restart();
  }
}
