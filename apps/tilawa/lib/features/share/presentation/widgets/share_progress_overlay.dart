import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// A translucent overlay shown during screenshot capture.
class ShareProgressOverlay extends StatelessWidget {
  const ShareProgressOverlay({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return ColoredBox(
      color: Colors.black54,
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
