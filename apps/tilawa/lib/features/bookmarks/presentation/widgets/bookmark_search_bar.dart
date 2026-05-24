import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'package:tilawa/core/extensions.dart';

class BookmarkSearchBar extends StatefulWidget {
  const BookmarkSearchBar({
    super.key,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  @override
  State<BookmarkSearchBar> createState() => _BookmarkSearchBarState();
}

class _BookmarkSearchBarState extends State<BookmarkSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return TilawaSearchFieldSlot(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceMedium,
      ),
      child: TilawaSearchField(
        controller: _controller,
        focusNode: _focusNode,
        hintText: context.l10n.searchBookmarks,
        prefixIcon: FluentIcons.search_24_regular,
        clearIcon: FluentIcons.dismiss_24_regular,
        onChanged: widget.onSearchChanged,
        onClear: () {
          _controller.clear();
          widget.onClearSearch();
        },
        showShadow: false,
      ),
    );
  }
}
