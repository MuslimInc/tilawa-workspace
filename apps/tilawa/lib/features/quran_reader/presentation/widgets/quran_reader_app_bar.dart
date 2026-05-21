import 'package:flutter/material.dart';
import 'package:tilawa/shared/widgets/tilawa_back_button.dart';
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

    return TilawaAppBar(
      surface: TilawaAppBarSurface.parchment,
      automaticallyImplyLeading: false,
      leading: TilawaBackButton(onPressed: onBack),
      titleWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TilawaIconActionButton(
          icon: Icons.search,
          tooltip: context.l10n.searchSurah,
          onTap: onSearch,
        ),
        TilawaIconActionButton(
          icon: Icons.settings,
          tooltip: context.l10n.settings,
          onTap: onSettings,
        ),
      ],
    );
  }
}
