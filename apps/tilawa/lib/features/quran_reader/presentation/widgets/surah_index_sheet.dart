import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';

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
    _filteredSurahsNotifier.value = _computeFilteredSurahs();
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

  List<int> _computeFilteredSurahs() {
    return [
      for (int i = 1; i <= 114; i++)
        if (_matchesSearch(i)) i,
    ];
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

  String _normalizeSearchText(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'), '')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), '');
  }

  /// Returns true if the [surahNumber] matches the current query.
  bool _matchesSearch(int surahNumber) {
    if (_searchController.text.isEmpty) return true;

    final query = _searchController.text.toLowerCase();
    final normalizedQuery = _normalizeSearchText(_searchController.text);
    final name = getSurahName(surahNumber).toLowerCase();
    final arabicName = getSurahNameArabic(surahNumber);
    final englishName = getSurahNameEnglish(surahNumber);
    final number = surahNumber.toString();

    return name.contains(query) ||
        arabicName.contains(query) ||
        englishName.toLowerCase().contains(query) ||
        _normalizeSearchText(name).contains(normalizedQuery) ||
        _normalizeSearchText(arabicName).contains(normalizedQuery) ||
        _normalizeSearchText(englishName).contains(normalizedQuery) ||
        number == query;
  }

  @override
  Widget build(BuildContext context) {
    final readerTheme = QuranReaderTheme.of(context);
    final indexTheme = SurahIndexTheme.of(context);

    final Color bgColor = readerTheme.pageBackground;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: _sheetAnimationDuration,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: _initialSheetSize,
        minChildSize: _minSheetSize,
        maxChildSize: _maxSheetSize,
        snap: true,
        snapSizes: const [_initialSheetSize, _focusedSheetSize],
        expand: false,
        builder: (context, scrollController) {
          return SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(indexTheme.sheetRadius),
                ),
              ),
              child: Column(
                children: [
                  _buildDragHandle(context),
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
                      _filteredSurahsNotifier.value = _computeFilteredSurahs();
                    },
                    onClear: () {
                      _searchController.clear();
                      _filteredSurahsNotifier.value = _computeFilteredSurahs();
                    },
                  ),
                  _buildDivider(context),
                  _IndexList(
                    scrollController: scrollController,
                    filteredSurahsNotifier: _filteredSurahsNotifier,
                    onSurahSelected: widget.onSurahSelected,
                    onSurahTapped: widget.onSurahTapped,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    final readerTheme = QuranReaderTheme.of(context);
    final indexTheme = SurahIndexTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: indexTheme.dragHandleWidth,
      height: indexTheme.dragHandleHeight,
      decoration: BoxDecoration(
        color: readerTheme.primaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(indexTheme.dragHandleRadius),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final readerTheme = QuranReaderTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color borderColor = readerTheme.primaryColor.withValues(
      alpha: isDark ? 0.15 : 0.1,
    );
    return Divider(color: borderColor, height: 1);
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
    final l10n = context.l10n;
    final Color primaryColor = readerTheme.primaryColor;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final FocusNode? focusNode = FocusScope.of(context).focusedChild;
    final bool compactHeader = focusNode != null || keyboardInset > 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        compactHeader ? 10 : 16,
        20,
        compactHeader ? 6 : 8,
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
          const SizedBox(width: 12),
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
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final Color primaryColor = readerTheme.primaryColor;
    final Color cardColor = readerTheme.pageBackground.withValues(
      alpha: isDark ? 0.08 : 0.05,
    );
    final Color borderColor = primaryColor.withValues(
      alpha: isDark ? 0.15 : 0.1,
    );
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        scrollPadding: EdgeInsets.only(bottom: keyboardInset + 24),
        onChanged: onChanged,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: readerTheme.textColor,
        ),
        decoration: InputDecoration(
          hintText: l10n.searchSurah,
          hintStyle: TextStyle(
            color: primaryColor.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: primaryColor.withValues(alpha: 0.6),
            size: indexTheme.searchBarIconSize,
          ),
          suffixIcon: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              if (controller.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: primaryColor.withValues(alpha: 0.6),
                  size: 18,
                ),
                onPressed: onClear,
              );
            },
          ),
          filled: true,
          fillColor: cardColor,
          contentPadding: EdgeInsets.symmetric(
            vertical: indexTheme.searchBarVerticalPadding,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(indexTheme.searchBarRadius),
            borderSide: BorderSide(
              color: borderColor,
              width: indexTheme.searchBarBorderWidth,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(indexTheme.searchBarRadius),
            borderSide: BorderSide(
              color: borderColor,
              width: indexTheme.searchBarBorderWidth,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(indexTheme.searchBarRadius),
            borderSide: BorderSide(
              color: primaryColor,
              width: indexTheme.searchBarBorderWidth + 0.4,
            ),
          ),
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
    final readerTheme = QuranReaderTheme.of(context);
    final l10n = context.l10n;
    final primaryColor = readerTheme.primaryColor;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Expanded(
      child: ValueListenableBuilder<List<int>>(
        valueListenable: filteredSurahsNotifier,
        builder: (context, filteredSurahs, _) {
          if (filteredSurahs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: primaryColor.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noSurahsFound,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RepaintBoundary(
            child: ListView.separated(
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + keyboardInset),
              itemCount: filteredSurahs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final surahNumber = filteredSurahs[index];
                return _SurahTile(
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

/// A single surah tile in the index list.
class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surahNumber, required this.onTap});

  final int surahNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final readerTheme = QuranReaderTheme.of(context);
    final indexTheme = SurahIndexTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final l10n = context.l10n;
    final Color primaryColor = readerTheme.primaryColor;
    final Color cardColor = readerTheme.pageBackground.withValues(
      alpha: isDark ? 0.08 : 0.05,
    );
    final Color borderColor = primaryColor.withValues(
      alpha: isDark ? 0.15 : 0.1,
    );

    final arabicName = getSurahNameArabic(surahNumber);
    final englishName = getSurahName(surahNumber);
    final verseCount = getVerseCount(surahNumber);
    final place = getPlaceOfRevelation(surahNumber);
    final startPage = getPageNumber(surahNumber, 1);

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(indexTheme.tileRadius),
          splashColor: primaryColor.withValues(alpha: 0.08),
          highlightColor: primaryColor.withValues(alpha: 0.04),
          child: Container(
            padding: indexTheme.tilePadding,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(indexTheme.tileRadius),
              border: Border.all(
                color: borderColor,
                width: indexTheme.tileBorderWidth,
              ),
            ),
            child: Row(
              children: [
                // Surah number badge
                Container(
                  width: indexTheme.tileNumberSize,
                  height: indexTheme.tileNumberSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      indexTheme.tileNumberRadius,
                    ),
                  ),
                  child: Text(
                    '$surahNumber',
                    style: readerTheme.pillPageTextStyle.copyWith(
                      color: primaryColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // English name & meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        englishName,
                        style: readerTheme.surahTileNameTextStyle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${l10n.ayahCountWithPlace(verseCount, place)} · ${l10n.page} $startPage',
                        style: readerTheme.surahTileMetaTextStyle,
                      ),
                    ],
                  ),
                ),
                // Arabic name
                Text(
                  arabicName,
                  style: readerTheme.surahTileArabicNameTextStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
