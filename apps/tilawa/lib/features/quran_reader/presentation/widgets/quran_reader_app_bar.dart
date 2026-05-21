import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Reader chrome: parchment surface + hairline, built on [TilawaAppBar].
class QuranReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const QuranReaderAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onSearch,
    required this.onSettings,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onSettings;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color iconColor = colorScheme.onSurfaceVariant;

    return TilawaAppBar(
      surface: TilawaAppBarSurface.parchment,
      automaticallyImplyLeading: false,
      leading: IconButton(
        onPressed: onBack,
        color: iconColor,
        icon: const Icon(Icons.arrow_back),
        tooltip: context.l10n.back,
      ),
      titleWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          onPressed: onSearch,
          color: iconColor,
          icon: const Icon(Icons.search),
          tooltip: context.l10n.searchSurah,
        ),
        IconButton(
          onPressed: onSettings,
          color: iconColor,
          icon: const Icon(Icons.settings),
          tooltip: context.l10n.settings,
        ),
      ],
    );
  }
}
