import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/premium_bloc.dart';
import '../bloc/premium_state.dart';

class PremiumUpgradeDialog extends StatelessWidget {
  const PremiumUpgradeDialog({
    super.key,
    required this.title,
    required this.message,
    this.onUpgrade,
  });

  final String title;
  final String message;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return BlocBuilder<PremiumBloc, PremiumState>(
      builder: (context, state) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
          ),
          title: Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: colorScheme.tertiary,
                size: tokens.iconSizeLarge,
              ),
              SizedBox(width: tokens.spaceSmall),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: theme.textTheme.bodyLarge),
              SizedBox(height: tokens.spaceLarge),
              Text(
                context.l10n.premiumFeatures,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: tokens.spaceSmall),
              _PremiumFeatureItem(
                icon: Icons.download_rounded,
                text: context.l10n.unlimitedDownloads,
              ),
              _PremiumFeatureItem(
                icon: Icons.offline_bolt_rounded,
                text: context.l10n.offlineMode,
              ),
              _PremiumFeatureItem(
                icon: Icons.high_quality_rounded,
                text: context.l10n.highQualityAudio,
              ),
              _PremiumFeatureItem(
                icon: Icons.block_rounded,
                text: context.l10n.adFreeExperience,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.maybeLater),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onUpgrade?.call();
              },
              icon: const Icon(Icons.star_rounded),
              label: Text(context.l10n.upgradeNow),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(tokens.radiusMedium),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PremiumFeatureItem extends StatelessWidget {
  const _PremiumFeatureItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceExtraSmall),
      child: Row(
        children: [
          Icon(
            icon,
            size: tokens.iconSizeMedium,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: tokens.spaceSmall),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
