import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'package:tilawa/core/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';

class PlaylistSearchBar extends StatefulWidget {
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
  State<PlaylistSearchBar> createState() => _PlaylistSearchBarState();
}

class _PlaylistSearchBarState extends State<PlaylistSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return TilawaSearchField(
      controller: _controller,
      hintText: widget.hintText ?? l10n.searchPlaylists,
      onChanged: widget.onSearchChanged,
      onClear: () {
        _controller.clear();
        widget.onClearSearch();
      },
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(
        Theme.of(context).tokens.radiusMedium,
      ),
    );
  }
}
