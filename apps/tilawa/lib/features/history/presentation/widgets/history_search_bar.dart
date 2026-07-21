import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'package:tilawa/core/extensions.dart';

class HistorySearchBar extends StatelessWidget {
  const HistorySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.scrollPadding,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final EdgeInsets? scrollPadding;

  @override
  Widget build(BuildContext context) {
    return TilawaSearchField(
      controller: controller,
      hintText: context.l10n.searchHistory,
      onChanged: onChanged,
      onClear: onClear,
      clearButtonTooltip: context.l10n.a11yClearSearch,
      showShadow: false,
      scrollPadding: scrollPadding,
    );
  }
}
