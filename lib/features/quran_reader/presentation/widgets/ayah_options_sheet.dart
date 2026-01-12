import 'package:flutter/material.dart';

import '../../../../core/extensions.dart';
import '../../domain/entities/entities.dart';

class AyahOptionsSheet extends StatelessWidget {
  const AyahOptionsSheet({
    super.key,
    required this.ayah,
    required this.onCopy,
    required this.onShare,
    required this.onBookmark,
    required this.onPlay,
  });

  final AyahEntity ayah;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onBookmark;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Ayah info
          Text(
            '${context.l10n.ayah} ${ayah.numberInSurah}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Ayah text preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                ayah.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Amiri',
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Options
          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: Text(context.l10n.playAyah),
            onTap: onPlay,
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: Text(context.l10n.copyAyah),
            onTap: onCopy,
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: Text(context.l10n.shareAyah),
            onTap: onShare,
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: Text(context.l10n.addBookmark),
            onTap: onBookmark,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
