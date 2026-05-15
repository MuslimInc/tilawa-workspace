import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'package:tilawa/core/extensions.dart';

class HistorySearchBar extends StatelessWidget {
  const HistorySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TilawaSearchField(
      controller: controller,
      hintText: context.l10n.searchHistory,
      onChanged: onChanged,
      onClear: onClear,
      borderRadius: BorderRadius.circular(
        Theme.of(context).tokens.radiusMedium,
      ),
    );
  }
}
