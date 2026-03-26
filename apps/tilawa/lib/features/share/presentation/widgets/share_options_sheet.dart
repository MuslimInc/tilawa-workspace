import 'package:flutter/material.dart';

import 'package:tilawa/core/extensions.dart';

/// Bottom sheet presenting two share options: Screenshot and Audio Clip.
class ShareOptionsSheet extends StatelessWidget {
  const ShareOptionsSheet({
    super.key,
    required this.onShareScreenshot,
    required this.onShareAudioClip,
  });

  final VoidCallback onShareScreenshot;
  final VoidCallback onShareAudioClip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              context.l10n.share,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Options row
            Row(
              children: [
                Expanded(
                  child: _ShareOptionCard(
                    icon: Icons.camera_alt_outlined,
                    label: context.l10n.shareScreenshot,
                    onTap: () {
                      Navigator.of(context).pop();
                      onShareScreenshot();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShareOptionCard(
                    icon: Icons.audiotrack_outlined,
                    label: context.l10n.shareAudioClip,
                    onTap: () {
                      Navigator.of(context).pop();
                      onShareAudioClip();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ShareOptionCard extends StatelessWidget {
  const _ShareOptionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
