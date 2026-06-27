import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../theme/quran_sessions_theme.dart';

/// Compact metadata chip styled with feature tokens (specialization, tags).
enum QuranSessionsMetadataChipVariant { neutral, success, warning, info }

class QuranSessionsMetadataChip extends StatelessWidget {
  const QuranSessionsMetadataChip({
    super.key,
    required this.label,
    this.variant = QuranSessionsMetadataChipVariant.neutral,
  });

  final String label;
  final QuranSessionsMetadataChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;
    final tint = tokens.opacitySubtle;

    final (background, foreground) = switch (variant) {
      QuranSessionsMetadataChipVariant.success => (
        feature.success.withValues(alpha: tint),
        feature.success,
      ),
      QuranSessionsMetadataChipVariant.warning => (
        feature.warning.withValues(alpha: tint),
        feature.warning,
      ),
      QuranSessionsMetadataChipVariant.info => (
        feature.info.withValues(alpha: tint),
        feature.info,
      ),
      QuranSessionsMetadataChipVariant.neutral => (
        feature.accentSoftBackground,
        feature.primaryColor,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: feature.listItemGap,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(feature.chipRadius),
      ),
      child: Text(
        label,
        style: feature.chipLabelStyle.copyWith(color: foreground),
      ),
    );
  }
}
