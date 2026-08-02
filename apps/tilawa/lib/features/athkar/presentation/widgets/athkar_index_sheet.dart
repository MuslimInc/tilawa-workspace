import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/athkar_item.dart';

/// Opens the Athkar session table-of-contents sheet.
///
/// Returns the selected 0-based index, or `null` if dismissed.
Future<int?> showAthkarIndexSheet({
  required BuildContext context,
  required List<AthkarItem> items,
  required int currentIndex,
  required String categoryName,
}) {
  final ColorScheme colorScheme = Theme.of(context).colorScheme;
  return showTilawaModalBottomSheet<int>(
    context: context,
    backgroundColor: colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    isScrollControlled: true,
    sheetSemanticsLabel: context.l10n.athkarIndexTitle,
    builder: (BuildContext sheetContext) {
      return AthkarIndexSheet(
        items: items,
        currentIndex: currentIndex,
        categoryName: categoryName,
      );
    },
  );
}

class AthkarIndexSheet extends StatefulWidget {
  const AthkarIndexSheet({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.categoryName,
  });

  final List<AthkarItem> items;
  final int currentIndex;
  final String categoryName;

  @override
  State<AthkarIndexSheet> createState() => _AthkarIndexSheetState();
}

class _AthkarIndexSheetState extends State<AthkarIndexSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<({int index, AthkarItem item})> get _filtered {
    final String q = _query.trim().toLowerCase();
    final List<({int index, AthkarItem item})> all = [
      for (int i = 0; i < widget.items.length; i++)
        (index: i, item: widget.items[i]),
    ];
    if (q.isEmpty) {
      return all;
    }
    return all.where((entry) {
      final AthkarItem item = entry.item;
      return item.textAr.toLowerCase().contains(q) ||
          item.textEn.toLowerCase().contains(q) ||
          item.reference.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final List<({int index, AthkarItem item})> filtered = _filtered;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: TilawaBottomSheetScaffold(
        topBar: TilawaSearchField(
          controller: _searchController,
          hintText: context.l10n.athkarSearchHint(widget.categoryName),
          margin: EdgeInsets.zero,
          onChanged: (String value) {
            setState(() {
              _query = value;
            });
          },
          onClear: () {
            _searchController.clear();
            setState(() {
              _query = '';
            });
          },
          clearButtonTooltip: context.l10n.a11yClearSearch,
        ),
        children: [
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: TilawaBottomSheetScaffold.resolvedBodyPadding(
                      context,
                    ),
                    child: Center(
                      child: Text(
                        context.l10n.noResultsFound,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: TilawaBottomSheetScaffold.resolvedBodyPadding(
                      context,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => TilawaDivider(
                      height: tokens.borderWidthThin,
                      color: colorScheme.outlineVariant,
                    ),
                    itemBuilder: (BuildContext context, int i) {
                      final ({int index, AthkarItem item}) entry = filtered[i];
                      final bool selected = entry.index == widget.currentIndex;
                      final String preview = entry.item.textAr;

                      return InkWell(
                        onTap: () => Navigator.of(context).pop(entry.index),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: tokens.spaceMedium,
                          ),
                          child: Row(
                            spacing: tokens.spaceMedium,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  preview,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.start,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: selected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    height: tokens.textHeightLoose,
                                  ),
                                ),
                              ),
                              Text(
                                '${entry.index + 1}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: selected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
