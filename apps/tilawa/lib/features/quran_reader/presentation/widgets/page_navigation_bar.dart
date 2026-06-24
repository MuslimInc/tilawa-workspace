import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/atoms/nav_action_button.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/molecules/navigation_index_card.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/molecules/page_slider_section.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/molecules/slider_preview_pill.dart';
import 'package:tilawa/features/share/presentation/utils/share_feature_flags.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class PageNavigationBar extends StatefulWidget {
  const PageNavigationBar({
    super.key,
    required this.currentPage,
    required this.onPageChanged,
    required this.onShowIndex,
    required this.onShare,
    this.onPractice,
    this.onWarming,
    this.onPointerDown,
    this.onPointerUp,
  });

  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onShowIndex;
  final VoidCallback onShare;
  final VoidCallback? onPractice;
  final ValueChanged<int>? onWarming;
  final VoidCallback? onPointerDown;
  final VoidCallback? onPointerUp;

  @override
  State<PageNavigationBar> createState() => _PageNavigationBarState();
}

class _PageNavigationBarState extends State<PageNavigationBar> {
  static int get _totalPages => QuranConstants.totalPagesCount;

  double? _sliderValueOverride;
  int? _lastPreviewPage;
  Timer? _previewHideTimer;
  bool _showFocusedPagePreview = false;
  bool _isDraggingSlider = false;
  int? _throttledWarmingPage;
  Timer? _warmingThrottleTimer;

  // Measurement Cache
  final Map<String, double> _textWidthCache = {};
  double? _lastCachedReaderFontSize;

  bool get _showPreviewPill => _isDraggingSlider || _showFocusedPagePreview;

  bool get _isDragging => _isDraggingSlider;

  double get _sliderValue =>
      _sliderValueOverride ?? widget.currentPage.toDouble();

  int get _previewPage => _sliderValue.round().clamp(1, _totalPages);

  @override
  void didUpdateWidget(covariant PageNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isDraggingSlider &&
        _sliderValueOverride != null &&
        widget.currentPage != oldWidget.currentPage) {
      setState(() {
        _sliderValueOverride = null;
      });
    }

    if (widget.currentPage != oldWidget.currentPage && !_isDraggingSlider) {
      _showCurrentPagePreview();
    }
  }

  @override
  void dispose() {
    _previewHideTimer?.cancel();
    super.dispose();
  }

  void _showCurrentPagePreview() {
    _previewHideTimer?.cancel();

    if (!mounted) return;

    final navTheme = PageNavigationBarTheme.of(context);

    setState(() {
      _showFocusedPagePreview = true;
      _sliderValueOverride = null;
      _lastPreviewPage = widget.currentPage;
    });

    _previewHideTimer = Timer(navTheme.pagePreviewDuration, () {
      if (!mounted || _isDraggingSlider) return;

      setState(() {
        _showFocusedPagePreview = false;
        _lastPreviewPage = null;
      });
    });
  }

  void _handleSliderChangeStart(double value) {
    _previewHideTimer?.cancel();
    widget.onPointerDown?.call();

    setState(() {
      _showFocusedPagePreview = false;
      _isDraggingSlider = true;
      _sliderValueOverride = value;
      _lastPreviewPage = value.round().clamp(1, _totalPages);
    });
  }

  void _handleSliderChanged(double value) {
    final int previewPage = value.round().clamp(1, _totalPages);

    if (previewPage != _lastPreviewPage) {
      HapticFeedback.selectionClick();
    }

    setState(() {
      _sliderValueOverride = value;
      _lastPreviewPage = previewPage;
    });

    if (previewPage != widget.currentPage) {
      _throttleWarming(previewPage);
    }
  }

  void _throttleWarming(int pageNumber) {
    _throttledWarmingPage = pageNumber;
    if (_warmingThrottleTimer != null) return;

    // Use a 300ms throttle for warming while dragging.
    // This allows the slider to remain buttery smooth while still
    // letting the engine know about the intended destination.
    _warmingThrottleTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _isDraggingSlider && _throttledWarmingPage != null) {
        widget.onWarming?.call(_throttledWarmingPage!);
      }
      _warmingThrottleTimer = null;
    });
  }

  void _handleSliderChangeEnd(double value) {
    _warmingThrottleTimer?.cancel();
    _warmingThrottleTimer = null;

    final int targetPage = value.round().clamp(1, _totalPages);
    final bool shouldNavigate = targetPage != widget.currentPage;

    setState(() {
      _isDraggingSlider = false;
      _showFocusedPagePreview = false;
      _sliderValueOverride = shouldNavigate ? targetPage.toDouble() : null;
      _lastPreviewPage = null;
    });

    if (shouldNavigate) {
      widget.onPageChanged(targetPage);
    }

    // Delay the resume slightly to avoid collision with the jump build
    Timer(const Duration(milliseconds: 50), () {
      if (mounted) widget.onPointerUp?.call();
    });
  }

  double _measureTextWidth({
    required BuildContext context,
    required String text,
    required TextStyle style,
  }) {
    final double? cachedWidth = _textWidthCache[text];
    if (cachedWidth != null && _lastCachedReaderFontSize == style.fontSize) {
      return cachedWidth;
    }

    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();

    _textWidthCache[text] = painter.width;
    _lastCachedReaderFontSize = style.fontSize;
    return painter.width;
  }

  double _buildPreviewPillWidth({
    required BuildContext context,
    required String surahName,
    required int pageNumber,
    required double availableWidth,
  }) {
    final readerTheme = QuranReaderTheme.of(context);
    final navTheme = PageNavigationBarTheme.of(context);

    final String pageLabel = '${context.l10n.page} $pageNumber';
    final double surahWidth = _measureTextWidth(
      context: context,
      text: surahName,
      style: readerTheme.pillSurahTextStyle,
    );
    final double pageWidth = _measureTextWidth(
      context: context,
      text: pageLabel,
      style: readerTheme.pillPageTextStyle,
    );
    final double desiredWidth =
        (navTheme.previewPillHorizontalPadding * 2) +
        surahWidth +
        navTheme.previewPillContentGap +
        (navTheme.previewPillChipHorizontalPadding * 2) +
        pageWidth;
    final double maxWidth = availableWidth.clamp(
      navTheme.previewPillMinWidth,
      availableWidth * navTheme.previewPillMaxWidthFactor,
    );

    return desiredWidth.clamp(navTheme.previewPillMinWidth, maxWidth);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final readerTheme = QuranReaderTheme.of(context);
    final navTheme = PageNavigationBarTheme.of(context);

    final Color primaryColor = readerTheme.primaryColor;
    final Color barColor = readerTheme.pageBackground.withValues(
      alpha: isDark ? 0.78 : 0.85,
    );
    final Color borderColor = primaryColor.withValues(
      alpha: isDark ? 0.12 : 0.1,
    );
    final Color textColor = readerTheme.textColor;
    final Color mutedTextColor = readerTheme.textColor.withValues(alpha: 0.65);

    final double bottomPadding = context.floatingBottomPadding;
    final _PagePreviewInfo currentInfo = _PagePreviewInfo.fromPage(
      context,
      widget.currentPage,
    );
    final _PagePreviewInfo displayInfo = _isDragging
        ? _PagePreviewInfo.fromPage(context, _previewPage)
        : currentInfo;
    final int displayPage = _isDragging ? _previewPage : widget.currentPage;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double barTotalWidth =
            constraints.maxWidth - (navTheme.barMarginHorizontal * 2);
        final double barContentWidth =
            barTotalWidth - navTheme.barPadding.horizontal;
        final double sliderContentWidth =
            barContentWidth - navTheme.sliderSectionPadding.horizontal;
        final double sliderWidth =
            sliderContentWidth -
            (navTheme.sliderRangeLabelWidth * 2) -
            (navTheme.sliderRangeGap * 2);
        final double sliderInset =
            navTheme.barMarginHorizontal +
            navTheme.barPadding.left +
            navTheme.sliderSectionPadding.left +
            navTheme.sliderRangeLabelWidth +
            navTheme.sliderRangeGap;
        final double pillWidth = _buildPreviewPillWidth(
          context: context,
          surahName: displayInfo.surahName,
          pageNumber: _previewPage,
          availableWidth: constraints.maxWidth - 24,
        );
        final double normalizedValue = (_previewPage - 1) / (_totalPages - 1);
        final double thumbTravelWidth = sliderWidth - navTheme.sliderThumbSize;
        final double thumbCenterX =
            sliderInset +
            (navTheme.sliderThumbSize / 2) +
            ((1 - normalizedValue) * thumbTravelWidth);
        final double pillLeft = (thumbCenterX - (pillWidth / 2)).clamp(
          navTheme.barMarginHorizontal,
          constraints.maxWidth - pillWidth - navTheme.barMarginHorizontal,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: navTheme.barMarginHorizontal,
                right: navTheme.barMarginHorizontal,
                bottom: bottomPadding + navTheme.barMarginBottom,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(navTheme.barBorderRadius),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: navTheme.barPadding,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(
                        navTheme.barBorderRadius,
                      ),
                      border: Border.all(color: borderColor, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(
                            alpha: isDark ? 0.35 : 0.08,
                          ),
                          blurRadius: 24,
                          spreadRadius: -4,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        PageSliderSection(
                          totalPages: _totalPages,
                          sliderValue: _sliderValue,
                          primaryColor: primaryColor,
                          textColor: textColor,
                          borderColor: borderColor,
                          isDark: isDark,
                          onChanged: _handleSliderChanged,
                          onChangeStart: _handleSliderChangeStart,
                          onChangeEnd: _handleSliderChangeEnd,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: NavigationIndexCard(
                                  pageNumber: displayPage,
                                  surahNumber: getPageData(
                                    displayPage,
                                  ).first.surah,
                                  surahName: displayInfo.surahName,
                                  juzNumber: displayInfo.juzNumber,
                                  hizbLabel: displayInfo.hizbLabel,
                                  primaryColor: primaryColor,
                                  textColor: textColor,
                                  mutedTextColor: mutedTextColor,
                                  surfaceColor: colorScheme.surface,
                                  outlineColor: borderColor,
                                  isDark: isDark,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    widget.onShowIndex();
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              NavActionButton(
                                icon: Icons.format_list_bulleted_rounded,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  widget.onShowIndex();
                                },
                                tooltip: context.l10n.surahIndex,
                              ),
                              if (widget.onPractice != null) ...[
                                const SizedBox(width: 10),
                                NavActionButton(
                                  icon: Icons.mic_rounded,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    widget.onPractice!.call();
                                  },
                                  tooltip:
                                      context.l10n.recitationPracticeTooltip,
                                ),
                              ],
                              if (kShareScreenshotEnabled ||
                                  kShareVideoReelEnabled) ...[
                                const SizedBox(width: 10),
                                NavActionButton(
                                  icon: Icons.share_rounded,
                                  onTap: widget.onShare,
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).shareButtonLabel,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_showPreviewPill)
              Positioned(
                top: -navTheme.previewPillTopOffset,
                left: pillLeft,
                child: IgnorePointer(
                  child: SliderPreviewPill(
                    width: pillWidth,
                    surahName: displayInfo.surahName,
                    pageNumber: _previewPage,
                    primaryColor: primaryColor,
                    backgroundColor: colorScheme.surface,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                    isDark: isDark,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PagePreviewInfo {
  const _PagePreviewInfo({
    required this.surahName,
    required this.juzNumber,
    required this.hizbLabel,
  });

  final String surahName;
  final int juzNumber;
  final String hizbLabel;

  static final Map<String, _PagePreviewInfo> _cache = {};

  static _PagePreviewInfo fromPage(BuildContext context, int pageNumber) {
    final String cacheKey = '${context.l10n.localeName}|$pageNumber';
    final _PagePreviewInfo? cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final pageData = getPageData(pageNumber);
    final bool isArabic = context.l10n.localeName == 'ar';
    final Set<int> uniqueSurahNumbers = pageData
        .map((entry) => entry.surah)
        .toSet();

    final int juzNumber = getJuzNumber(
      pageData.first.surah,
      pageData.first.start,
    );

    final int? quarterNumber = pageNumber == 1 || pageNumber == 2
        ? null
        : getQuarterNumber(pageData.first.surah, pageData.first.start);

    String hizbLabelStr = '';
    if (quarterNumber != null) {
      final int hizbIndex = (quarterNumber - 1) ~/ 4 + 1;
      final int quarterInHizb = (quarterNumber - 1) % 4;

      final String prefix;
      switch (quarterInHizb) {
        case 0:
          prefix = '';
        case 1:
          prefix = '1/4 ';
        case 2:
          prefix = '1/2 ';
        case 3:
          prefix = '3/4 ';
        default:
          prefix = '';
      }
      hizbLabelStr = '$prefix${context.l10n.hizb} $hizbIndex';
    }

    final _PagePreviewInfo result = _PagePreviewInfo(
      surahName: uniqueSurahNumbers
          .map(
            (surahNumber) => isArabic
                ? getSurahNameArabic(surahNumber)
                : getSurahNameEnglish(surahNumber),
          )
          .join(' · '),
      juzNumber: juzNumber,
      hizbLabel: hizbLabelStr,
    );
    _cache[cacheKey] = result;
    return result;
  }
}
