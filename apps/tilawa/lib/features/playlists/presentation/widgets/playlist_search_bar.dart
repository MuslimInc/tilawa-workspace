import 'package:flutter/material.dart';

import 'package:tilawa/core/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';

class PlaylistSearchBar extends StatelessWidget {
  const PlaylistSearchBar({
    super.key,
    required this.onSearchChanged,
    required this.onClearSearch,
    this.hintText,
  });

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: hintText ?? l10n.searchPlaylists,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: onClearSearch,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
