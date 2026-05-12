import 'package:flutter/material.dart';

import '../../core/presentation/widgets/offline_indicator_widget.dart';
import '../../shared/widgets/quran_player_widget.dart';

/// Composes deferred startup overlays rendered in the shell bottom slot.
class MainBottomOverlay extends StatelessWidget {
  const MainBottomOverlay({
    super.key,
    required this.bottomNavBarHeight,
    required this.isKeyboardOpen,
    required this.isAudioBindingDeferred,
    required this.isOfflineIndicatorReady,
    this.compactBottomNavBarVisible,
    this.hostAbsorbsBottomSafeArea = false,
  });

  final double bottomNavBarHeight;
  final bool isKeyboardOpen;
  final bool isAudioBindingDeferred;
  final bool isOfflineIndicatorReady;

  /// Hides the main shell compact bottom bar while the Quran player is
  /// expanded past [TilawaDesignTokens.playerProgressThreshold].
  final ValueNotifier<bool>? compactBottomNavBarVisible;

  /// Passed to [QuranPlayerWidget.hostAbsorbsBottomSafeArea] (compact shell).
  final bool hostAbsorbsBottomSafeArea;

  @override
  Widget build(BuildContext context) {
    final Widget playerWidget = isAudioBindingDeferred
        ? const SizedBox.shrink()
        : QuranPlayerWidget(
            bottomNavBarHeight: bottomNavBarHeight,
            isKeyboardOpen: isKeyboardOpen,
            compactBottomNavBarVisible: compactBottomNavBarVisible,
            hostAbsorbsBottomSafeArea: hostAbsorbsBottomSafeArea,
          );

    return Stack(
      children: [
        if (isOfflineIndicatorReady)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: OfflineIndicatorWidget(),
          ),
        // Positioned.fill ensures the Align(bottomCenter) inside the player
        // has proper constraints to position correctly. The player's internal
        // Align and layout logic still manage sizing (mini vs expanded).
        Positioned.fill(child: playerWidget),
      ],
    );
  }
}
