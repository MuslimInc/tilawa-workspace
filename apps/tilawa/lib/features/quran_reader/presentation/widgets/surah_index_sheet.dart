import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/surah_index_filter.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/surah_index_tile.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// A bottom sheet widget that displays the Quran surah index.
///
/// Lists all 114 surahs with their Arabic and English names,
/// verse count, and place of revelation. Tapping a surah invokes
/// the [onSurahSelected] callback with the surah number.
class SurahIndexSheet extends StatefulWidget {
  const SurahIndexSheet({
    super.key,
    required this.onSurahSelected,
    this.onSurahTapped,
  });

  /// Called when a surah is tapped. Returns the 1-based surah number.
  final ValueChanged<int> onSurahSelected;

  /// Optional callback for proactive warming.
  final ValueChanged<int>? onSurahTapped;

  @override
  State<SurahIndexSheet> createState() => _SurahIndexSheetState();
}

class _SurahIndexSheetState extends State<SurahIndexSheet> {
  static const double _initialSheetSize = 0.75;
  static const double _minSheetSize = 0.4;
  static const double _maxSheetSize = 0.96;
  static const double _focusedSheetSize = 0.92;
  static const Duration _sheetAnimationDuration = Duration(milliseconds: 220);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final ValueNotifier<List<int>> _filteredSurahsNotifier =
      ValueNotifier<List<int>>([]);

  @override
  void initState() {
    super.initState();
    _filteredSurahsNotifier.value = SurahIndexFilter.filteredSurahs(
      _searchController.text,
    );
    _searchFocusNode.addListener(_handleSearchFocusChange);
  }

  @override
  void dispose() {
    _filteredSurahsNotifier.dispose();
    _searchFocusNode
      ..removeListener(_handleSearchFocusChange)
      ..dispose();
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _handleSearchFocusChange() {
    if (!mounted) return;

    if (_searchFocusNode.hasFocus && _sheetController.isAttached) {
      _sheetController.animateTo(
        _focusedSheetSize,
        duration: _sheetAnimationDuration,
        curve: Curves.easeOutCubic,
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final indexTheme = SurahIndexTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _initialSheetSize,
      minChildSize: _minSheetSize,
      maxChildSize: _maxSheetSize,
      snap: true,
      snapSizes: const [_initialSheetSize, _focusedSheetSize],
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(indexTheme.sheetRadius),
            ),
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: indexTheme.tileBorderWidth,
              ),
            ),
          ),
          child: Column(
            children: [
              TilawaSheetHandle(
                width: indexTheme.dragHandleWidth,
                height: indexTheme.dragHandleHeight,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.28),
              ),
              _IndexHeader(
                filteredSurahsNotifier: _filteredSurahsNotifier,
                isSearchingListenable: ValueNotifier(
                  _searchController.text.isNotEmpty,
                ),
              ),
              _IndexSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) {
                  _filteredSurahsNotifier.value =
                      SurahIndexFilter.filteredSurahs(value);
                },
                onClear: () {
                  _searchController.clear();
                  _filteredSurahsNotifier.value =
                      SurahIndexFilter.filteredSurahs('');
                },
              ),
              TilawaDivider(
                color: colorScheme.outlineVariant.withValues(alpha: 0.42),
              ),
              _IndexList(
                scrollController: scrollController,
                filteredSurahsNotifier: _filteredSurahsNotifier,
                onSurahSelected: widget.onSurahSelected,
                onSurahTapped: widget.onSurahTapped,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IndexHeader extends StatelessWidget {
  const _IndexHeader({
    required this.filteredSurahsNotifier,
    required this.isSearchingListenable,
  });

  final ValueListenable<List<int>> filteredSurahsNotifier;
  final ValueListenable<bool> isSearchingListenable;

  @override
  Widget build(BuildContext context) {
    final readerTheme = QuranReaderTheme.of(context);
    final indexTheme = SurahIndexTheme.of(context);
    final tokens = Theme.of(context).tokens;
    final l10n = context.l10n;
    final Color primaryColor = readerTheme.primaryColor;
    final FocusNode? focusNode = FocusScope.of(context).focusedChild;
    final bool tightHeader = focusNode != null || context.isKeyboardVisible;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        tokens.spaceExtraLarge,
        tightHeader ? 10 : 16,
        tokens.spaceExtraLarge,
        tightHeader ? 6 : 8,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(indexTheme.headerIconPadding),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(indexTheme.headerIconRadius),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: primaryColor,
              size: indexTheme.headerIconSize,
            ),
          ),
          SizedBox(width: tokens.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.surahIndex, style: readerTheme.indexTitleTextStyle),
                ValueListenableBuilder<List<int>>(
                  valueListenable: filteredSurahsNotifier,
                  builder: (context, filteredSurahs, _) {
                    return Text(
                      l10n.surahCountLabel(filteredSurahs.length),
                      style: readerTheme.indexSubtitleTextStyle,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexSearchBar extends StatelessWidget {
  const _IndexSearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readerTheme = QuranReaderTheme.of(context);
    final indexTheme = SurahIndexTheme.of(context);
    final tokens = theme.tokens;
    final l10n = context.l10n;

    final double keyboardInset = context.keyboardInset;

    return TilawaSearchFieldSlot(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceSmall,
      ),
      child: TilawaSearchField(
        controller: controller,
        focusNode: focusNode,
        hintText: l10n.searchSurah,
        textInputAction: TextInputAction.search,
        clearButtonTooltip: l10n.a11yClearSearch,
        scrollPadding: EdgeInsets.only(bottom: keyboardInset + 24),
        onChanged: onChanged,
        onClear: onClear,
        showShadow: false,
        textStyle: theme.textTheme.bodyMedium?.copyWith(
          color: readerTheme.textColor,
        ),
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: readerTheme.textColor.withValues(
            alpha: tokens.opacityEmphasis,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: indexTheme.searchBarVerticalPadding,
        ),
      ),
    );
  }
}

class _IndexList extends StatelessWidget {
  const _IndexList({
    required this.scrollController,
    required this.filteredSurahsNotifier,
    required this.onSurahSelected,
    this.onSurahTapped,
  });

  final ScrollController scrollController;
  final ValueListenable<List<int>> filteredSurahsNotifier;
  final ValueChanged<int> onSurahSelected;
  final ValueChanged<int>? onSurahTapped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final tokens = theme.tokens;
    final double keyboardInset = context.keyboardInset;

    return Expanded(
      child: ValueListenableBuilder<List<int>>(
        valueListenable: filteredSurahsNotifier,
        builder: (context, filteredSurahs, _) {
          if (filteredSurahs.isEmpty) {
            return TilawaEmptyState(
              icon: Icons.search_off_rounded,
              title: l10n.noSurahsFound,
            );
          }

          return RepaintBoundary(
            child: ListView.separated(
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsetsDirectional.fromSTEB(
                tokens.spaceLarge,
                tokens.spaceMedium,
                tokens.spaceLarge,
                tokens.spaceExtraLarge + keyboardInset,
              ),
              itemCount: filteredSurahs.length,
              separatorBuilder: (_, _) =>
                  SizedBox(height: tokens.spaceExtraSmall),
              itemBuilder: (context, index) {
                final surahNumber = filteredSurahs[index];
                return SurahIndexTile(
                  surahNumber: surahNumber,
                  onTap: () {
                    onSurahTapped?.call(surahNumber);
                    onSurahSelected(surahNumber);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
