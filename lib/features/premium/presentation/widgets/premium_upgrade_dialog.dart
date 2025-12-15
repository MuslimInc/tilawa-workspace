import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions.dart';
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
    return BlocBuilder<PremiumBloc, PremiumState>(
      builder: (context, state) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Text(
                context.l10n.premiumFeatures,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _PremiumFeatureItem(
                icon: Icons.download,
                text: context.l10n.unlimitedDownloads,
              ),
              _PremiumFeatureItem(
                icon: Icons.offline_bolt,
                text: context.l10n.offlineMode,
              ),
              _PremiumFeatureItem(
                icon: Icons.high_quality,
                text: context.l10n.highQualityAudio,
              ),
              _PremiumFeatureItem(
                icon: Icons.block,
                text: context.l10n.adFreeExperience,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.maybeLater),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onUpgrade?.call();
              },
              icon: const Icon(Icons.star),
              label: Text(context.l10n.upgradeNow),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
