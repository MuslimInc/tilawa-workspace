import 'package:flutter/material.dart';

import '../../core/presentation/widgets/offline_indicator_widget.dart';

/// Deferred startup overlays in the shell bottom slot (offline banner only).
///
/// The Quran mini-player is hosted globally by [GlobalQuranPlayerHost].
class MainBottomOverlay extends StatelessWidget {
  const MainBottomOverlay({
    super.key,
    required this.isOfflineIndicatorReady,
  });

  final bool isOfflineIndicatorReady;

  @override
  Widget build(BuildContext context) {
    if (!isOfflineIndicatorReady) {
      return const SizedBox.shrink();
    }

    return const Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: OfflineIndicatorWidget(),
        ),
      ],
    );
  }
}
