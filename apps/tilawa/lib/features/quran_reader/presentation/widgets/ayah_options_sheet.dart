import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';

class AyahOptionsSheet extends StatelessWidget {
  const AyahOptionsSheet({
    super.key,
    required this.ayah,
    required this.onCopy,
    required this.onShare,
    required this.onBookmark,
    required this.onPlay,
    this.onShareScreenshot,
    this.onShareAudioClip,
  });

  final AyahEntity ayah;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onBookmark;
  final VoidCallback onPlay;
  final VoidCallback? onShareScreenshot;
  final VoidCallback? onShareAudioClip;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TilawaSheetHandle(),

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
                style: theme.textTheme.bodyMedium?.copyWith(),
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
          ExpansionTile(
            leading: const Icon(Icons.share),
            title: Text(context.l10n.shareAyah),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.only(left: 24),
            children: [
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: Text(context.l10n.shareAsText),
                onTap: onShare,
              ),
              if (onShareScreenshot != null)
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: Text(context.l10n.shareScreenshot),
                  onTap: onShareScreenshot,
                ),
              if (onShareAudioClip != null)
                ListTile(
                  leading: const Icon(Icons.audiotrack_outlined),
                  title: Text(context.l10n.shareVerseAudioClip),
                  onTap: onShareAudioClip,
                ),
            ],
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
