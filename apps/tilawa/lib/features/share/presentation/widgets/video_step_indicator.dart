import 'package:flutter/material.dart';
import 'package:tilawa/features/share/presentation/cubit/share_state.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class VideoStepIndicator extends StatelessWidget {
  const VideoStepIndicator({super.key, required this.status});
  final ShareStatus status;

  @override
  Widget build(BuildContext context) {
    final isBusy =
        status == ShareStatus.capturing ||
        status == ShareStatus.generating ||
        status == ShareStatus.sharing;
    if (!isBusy) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return RepaintBoundary(
      child: SizedBox(
        height: tokens.progressHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          child: LinearProgressIndicator(
            // Use a fixed value or very slow update to avoid constant raster pressure
            value: status == ShareStatus.sharing ? null : 0.7,
            backgroundColor: theme.colorScheme.surface.withValues(
              alpha: tokens.opacitySubtle,
            ),
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
