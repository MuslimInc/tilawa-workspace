import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';

/// A bottom bar with a slider for quick page navigation and a surah index button.
class PageNavigationBar extends StatefulWidget {
  const PageNavigationBar({
    super.key,
    required this.currentPage,
    required this.onPageChanged,
    required this.onShowIndex,
    required this.onShare,
  });

  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onShowIndex;
  final VoidCallback onShare;

  @override
  State<PageNavigationBar> createState() => _PageNavigationBarState();
}

class _PageNavigationBarState extends State<PageNavigationBar> {
  static const int _totalPages = 604;
  static const _barMarginHorizontal = 20.0;
  static const _barMarginBottom = 16.0;
  static const _barBorderRadius = 36.0;
  static const _barPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const _sliderSectionPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  );
  static const _sliderThumbSize = 20.0;
  static const _sliderRangeLabelWidth = 28.0;
  static const _sliderRangeGap = 8.0;
  static const _previewPillMinWidth = 120.0;
  static const _previewPillMaxWidthFactor = 0.85;
  static const _previewPillTopOffset = 42.0;
  static const _previewPillHorizontalPadding = 16.0;
  static const _previewPillContentGap = 12.0;
  static const _previewPillChipHorizontalPadding = 10.0;
  static const _headerActionSize = 44.0;
  static const Duration _pagePreviewDuration = Duration(milliseconds: 1100);

  double? _sliderValueOverride;
  int? _lastPreviewPage;
  Timer? _previewHideTimer;
  bool _showFocusedPagePreview = false;
  bool _isDraggingSlider = false;

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

    setState(() {
      _showFocusedPagePreview = true;
      _sliderValueOverride = null;
      _lastPreviewPage = widget.currentPage;
    });

    _previewHideTimer = Timer(_pagePreviewDuration, () {
      if (!mounted || _isDraggingSlider) return;

      setState(() {
        _showFocusedPagePreview = false;
        _lastPreviewPage = null;
      });
    });
  }

  void _handleSliderChangeStart(double value) {
    _previewHideTimer?.cancel();

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
  }

  void _handleSliderChangeEnd(double value) {
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
  }

  double _measureTextWidth({
    required BuildContext context,
    required String text,
    required TextStyle style,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();

    return painter.width;
  }

  double _buildPreviewPillWidth({
    required BuildContext context,
    required String surahName,
    required int pageNumber,
    required double availableWidth,
  }) {
    final ThemeData theme = Theme.of(context);
    final TextStyle surahStyle = theme.textTheme.labelLarge!.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    );
    final TextStyle pageStyle = theme.textTheme.bodySmall!.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    final String pageLabel = '${context.l10n.page} $pageNumber';
    final double surahWidth = _measureTextWidth(
      context: context,
      text: surahName,
      style: surahStyle,
    );
    final double pageWidth = _measureTextWidth(
      context: context,
      text: pageLabel,
      style: pageStyle,
    );
    final double desiredWidth =
        (_previewPillHorizontalPadding * 2) +
        surahWidth +
        _previewPillContentGap +
        (_previewPillChipHorizontalPadding * 2) +
        pageWidth;
    final double maxWidth = availableWidth.clamp(
      _previewPillMinWidth,
      MediaQuery.sizeOf(context).width * _previewPillMaxWidthFactor,
    );

    return desiredWidth.clamp(_previewPillMinWidth, maxWidth);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = colorScheme.primary;
    final QuranReaderTheme readerTheme = QuranReaderTheme.of(context);
    final Color barColor = readerTheme.pageBackground.withValues(
      alpha: isDark ? 0.78 : 0.85,
    );
    final Color borderColor = primaryColor.withValues(
      alpha: isDark ? 0.12 : 0.1,
    );
    final Color textColor = readerTheme.textColor;
    final Color mutedTextColor = readerTheme.textColor.withValues(alpha: 0.65);
    final TextStyle sliderRangeStyle = theme.textTheme.labelSmall!.copyWith(
      color: mutedTextColor,
      fontSize: 10,
      fontWeight: FontWeight.w800,
    );
    final double bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
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
            constraints.maxWidth - (_barMarginHorizontal * 2);
        final double barContentWidth = barTotalWidth - _barPadding.horizontal;
        final double sliderContentWidth =
            barContentWidth - _sliderSectionPadding.horizontal;
        final double sliderWidth =
            sliderContentWidth -
            (_sliderRangeLabelWidth * 2) -
            (_sliderRangeGap * 2);
        final double sliderInset =
            _barMarginHorizontal +
            _barPadding.left +
            _sliderSectionPadding.left +
            _sliderRangeLabelWidth +
            _sliderRangeGap;
        final double pillWidth = _buildPreviewPillWidth(
          context: context,
          surahName: displayInfo.surahName,
          pageNumber: _previewPage,
          availableWidth: constraints.maxWidth - 24,
        );
        final double normalizedValue = (_previewPage - 1) / (_totalPages - 1);
        final double thumbTravelWidth = sliderWidth - _sliderThumbSize;
        final double thumbCenterX =
            sliderInset +
            (_sliderThumbSize / 2) +
            ((1 - normalizedValue) * thumbTravelWidth);
        final double pillLeft = (thumbCenterX - (pillWidth / 2)).clamp(
          _barMarginHorizontal,
          constraints.maxWidth - pillWidth - _barMarginHorizontal,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: _barMarginHorizontal,
                right: _barMarginHorizontal,
                bottom: bottomPadding + _barMarginBottom,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_barBorderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: _barPadding,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(_barBorderRadius),
                        border: Border.all(color: borderColor, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
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
                          _SliderSection(
                            totalPages: _totalPages,
                            sliderValue: _sliderValue,
                            primaryColor: primaryColor,
                            textColor: textColor,
                            borderColor: borderColor,
                            isDark: isDark,
                            sliderRangeStyle: sliderRangeStyle,
                            onChanged: _handleSliderChanged,
                            onChangeStart: _handleSliderChangeStart,
                            onChangeEnd: _handleSliderChangeEnd,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _NavigationIndexCard(
                                    pageNumber: displayPage,
                                    surahNumber: getPageData(
                                      displayPage,
                                    ).first['surah']!,
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
                                _NavigationActionButton(
                                  size: _headerActionSize,
                                  icon: Icons.share_rounded,
                                  backgroundColor: primaryColor.withValues(
                                    alpha: isDark ? 0.16 : 0.1,
                                  ),
                                  foregroundColor: primaryColor,
                                  borderColor: primaryColor.withValues(
                                    alpha: isDark ? 0.18 : 0.12,
                                  ),
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).shareButtonLabel,
                                  onTap: widget.onShare,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_showPreviewPill)
              Positioned(
                top: -_previewPillTopOffset,
                left: pillLeft,
                child: IgnorePointer(
                  child: _SliderPreviewPill(
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

class _SliderPreviewPill extends StatelessWidget {
  const _SliderPreviewPill({
    required this.width,
    required this.surahName,
    required this.pageNumber,
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.isDark,
  });

  final double width;
  final String surahName;
  final int pageNumber;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color mutedTextColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color pillBg = backgroundColor;
    final Color pillBorder = primaryColor.withValues(
      alpha: isDark ? 0.34 : 0.2,
    );

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: pillBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.12),
            blurRadius: 18,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                surahName,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${context.l10n.page} $pageNumber',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationIndexCard extends StatelessWidget {
  const _NavigationIndexCard({
    required this.pageNumber,
    required this.surahNumber,
    required this.surahName,
    required this.juzNumber,
    required this.hizbLabel,
    required this.primaryColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.surfaceColor,
    required this.outlineColor,
    required this.isDark,
    required this.onTap,
  });

  final int pageNumber;
  final int surahNumber;
  final String surahName;
  final int juzNumber;
  final String hizbLabel;
  final Color primaryColor;
  final Color textColor;
  final Color mutedTextColor;
  final Color surfaceColor;
  final Color outlineColor;
  final bool isDark;
  final VoidCallback onTap;

  String _buildContextSummary(BuildContext context) {
    final StringBuffer buffer = StringBuffer()
      ..write('${context.l10n.juzPart} $juzNumber');

    if (hizbLabel.isNotEmpty) {
      buffer.write(' • $hizbLabel');
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color cardColor = surfaceColor.withValues(alpha: isDark ? 0.4 : 0.7);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: outlineColor.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                blurRadius: 14,
                spreadRadius: -7,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
                  ),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(
                              alpha: isDark ? 0.15 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primaryColor.withValues(
                                alpha: isDark ? 0.2 : 0.12,
                              ),
                            ),
                          ),
                          child: Text(
                            '$pageNumber',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                String.fromCharCode(0xF100 + surahNumber - 1),
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontFamily: 'QCF_BSML',
                                  fontSize: 32,
                                  height: 1.2,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: mutedTextColor.withValues(alpha: 0.4),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildContextSummary(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationActionButton extends StatelessWidget {
  const _NavigationActionButton({
    required this.size,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.tooltip,
    required this.onTap,
  });

  final double size;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, size: 20, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}

class _BaseSlider extends StatelessWidget {
  const _BaseSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeStart,
    required this.onChangeEnd,
    required this.activeColor,
    required this.isDark,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChangeEnd;
  final Color activeColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const double trackHeight = 4;
    final double thumbSize = _PageNavigationBarState._sliderThumbSize;
    final double thumbRadius = thumbSize / 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double normalizedValue = (value - min) / (max - min);
        double interactionValue = value;
        final double trackWidth = (width - thumbSize).clamp(0.0, width);
        // Slider is RTL in Mushaf view: 1 is on the right, 604 on the left.
        final double thumbLeft = (1 - normalizedValue) * trackWidth;
        final double activeTrackWidth = trackWidth - thumbLeft;

        return GestureDetector(
          onHorizontalDragStart: (details) {
            interactionValue = _getValueFromPos(
              details.localPosition.dx,
              width,
            );
            onChangeStart(interactionValue);
          },
          onHorizontalDragUpdate: (details) {
            interactionValue = _getValueFromPos(
              details.localPosition.dx,
              width,
            );
            onChanged(interactionValue);
          },
          onHorizontalDragEnd: (details) {
            onChangeEnd(interactionValue);
          },
          onTapDown: (details) {
            interactionValue = _getValueFromPos(
              details.localPosition.dx,
              width,
            );
            onChangeStart(interactionValue);
            onChanged(interactionValue);
            onChangeEnd(interactionValue);
          },
          child: Container(
            height: 36,
            width: double.infinity,
            color: Colors.transparent, // Hit test area
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Track
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: thumbRadius),
                  child: Container(
                    height: trackHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                    ),
                  ),
                ),
                // Active Track (drawn RTL)
                Positioned(
                  right: thumbRadius,
                  child: Container(
                    height: trackHeight,
                    width: activeTrackWidth,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                    ),
                  ),
                ),
                // Thumb
                Positioned(
                  left: thumbLeft,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.black : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _getValueFromPos(double x, double width) {
    // RTL logic: x=0 is max, x=width is min
    final double normalized = (1 - (x / width)).clamp(0.0, 1.0);
    return min + (normalized * (max - min));
  }
}

class _SliderSection extends StatelessWidget {
  const _SliderSection({
    required this.totalPages,
    required this.sliderValue,
    required this.primaryColor,
    required this.textColor,
    required this.borderColor,
    required this.isDark,
    required this.sliderRangeStyle,
    required this.onChanged,
    required this.onChangeStart,
    required this.onChangeEnd,
  });

  final int totalPages;
  final double sliderValue;
  final Color primaryColor;
  final Color textColor;
  final Color borderColor;
  final bool isDark;
  final TextStyle sliderRangeStyle;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChangeEnd;

  static const _sliderSectionPadding = EdgeInsets.symmetric(horizontal: 14);
  static const _sliderSectionRadius = 28.0;
  static const _sliderHeight = 28.0;
  static const _sliderStageHeight = 36.0;
  static const _sliderRangeGap = 8.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _sliderSectionPadding,
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: isDark ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(_sliderSectionRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
            blurRadius: 12,
            spreadRadius: -8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        height: _sliderStageHeight,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            spacing: _sliderRangeGap,
            mainAxisAlignment: .spaceBetween,
            children: [
              Text('$totalPages', style: sliderRangeStyle),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: _sliderHeight,
                    child: _BaseSlider(
                      value: sliderValue,
                      min: 1,
                      max: totalPages.toDouble(),
                      onChanged: onChanged,
                      onChangeStart: onChangeStart,
                      onChangeEnd: onChangeEnd,
                      activeColor: primaryColor,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
              Text('1', style: sliderRangeStyle),
            ],
          ),
        ),
      ),
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

  static _PagePreviewInfo fromPage(BuildContext context, int pageNumber) {
    final pageData = getPageData(pageNumber);
    final bool isArabic = context.l10n.localeName == 'ar';
    final Set<int> uniqueSurahNumbers = pageData
        .map((entry) => entry['surah']!)
        .toSet();

    final int juzNumber = getJuzNumber(
      pageData.first['surah']!,
      pageData.first['start']!,
    );

    final int? quarterNumber = pageNumber == 1 || pageNumber == 2
        ? null
        : getQuarterNumber(pageData.first['surah']!, pageData.first['start']!);

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

    return _PagePreviewInfo(
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
  }
}
