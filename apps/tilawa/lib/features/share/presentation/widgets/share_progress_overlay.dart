import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// A translucent overlay shown during screenshot capture.
class ShareProgressOverlay extends StatelessWidget {
  const ShareProgressOverlay({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.scrim.withValues(alpha: 0.54),
      child: Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceExtraLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TilawaLoadingIndicator(),
                SizedBox(height: tokens.spaceLarge),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
