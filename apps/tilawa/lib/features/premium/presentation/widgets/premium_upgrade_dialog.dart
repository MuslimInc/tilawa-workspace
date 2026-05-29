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
            spacing: tokens.spaceSmall,
            children: [
              Icon(
                Icons.star_rounded,
                color: colorScheme.tertiary,
                size: tokens.iconSizeLarge,
              ),
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
            TilawaButton(
              text: context.l10n.maybeLater,
              variant: TilawaButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(),
            ),
            TilawaButton(
              text: context.l10n.upgradeNow,
              variant: TilawaButtonVariant.primary,
              leadingIcon: const Icon(Icons.star_rounded),
              onPressed: () {
                Navigator.of(context).pop();
                onUpgrade?.call();
              },
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
        spacing: tokens.spaceSmall,
        children: [
          Icon(
            icon,
            size: tokens.iconSizeMedium,
            color: theme.colorScheme.primary,
          ),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
