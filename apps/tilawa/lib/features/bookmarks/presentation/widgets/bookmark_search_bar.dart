import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

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
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: context.l10n.searchBookmarks,
          prefixIcon: const Icon(FluentIcons.search_24_regular),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(FluentIcons.dismiss_24_regular),
                  onPressed: () {
                    _controller.clear();
                    widget.onClearSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        onChanged: widget.onSearchChanged,
      ),
    );
  }
}
