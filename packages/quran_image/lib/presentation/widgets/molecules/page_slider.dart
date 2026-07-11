import 'package:flutter/material.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Molecular component for page navigation slider.
///
/// A Slider widget styled according to design tokens for fast page navigation.
///
/// While dragging, the thumb follows a local value. After [onChangeEnd], the
/// thumb holds the released page until [committedPage] catches up — otherwise
/// [currentPage] can still reflect the old saved page for a frame (or longer
/// while navigation runs), which would make the thumb jump backward.
class PageSlider extends StatefulWidget {
  /// Display page (preview while scrubbing, else committed) — same source as
  /// the page indicator.
  final int currentPage;

  /// Last page committed in navigation state (ignores preview). Used to know
  /// when slider navigation has finished so the post-drag hold can end.
  final int committedPage;

  final int totalPages;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double screenWidth;

  const PageSlider({
    super.key,
    required this.currentPage,
    required this.committedPage,
    required this.totalPages,
    required this.onChanged,
    this.onChangeEnd,
    required this.screenWidth,
  });

  @override
  State<PageSlider> createState() => _PageSliderState();
}

class _PageSliderState extends State<PageSlider> {
  bool _dragging = false;
  double? _dragValue;

  /// Rounded page from the last [onChangeEnd]; cleared when [committedPage]
  /// reaches it or navigation is superseded.
  int? _pendingReleasePage;

  @override
  void didUpdateWidget(PageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolvePendingRelease(oldWidget);
    if (!_dragging && oldWidget.currentPage != widget.currentPage) {
      _dragValue = null;
    }
  }

  void _resolvePendingRelease(PageSlider oldWidget) {
    if (_pendingReleasePage == null || _dragging) return;

    if (widget.committedPage == _pendingReleasePage) {
      PerfLogger.logQuranPerf(
        '[QuranPerf][Slider]',
        'pendingRelease cleared committedPage=${widget.committedPage} '
            'matchedPending=$_pendingReleasePage',
      );
      _pendingReleasePage = null;
      return;
    }

    final committedMoved = oldWidget.committedPage != widget.committedPage;
    if (committedMoved && widget.committedPage != _pendingReleasePage) {
      PerfLogger.logQuranPerf(
        '[QuranPerf][Slider]',
        'pendingRelease cleared reason=superseded '
            'committedPage=${widget.committedPage} pendingWas=$_pendingReleasePage',
      );
      _pendingReleasePage = null;
    }
  }

  double get _sliderValue {
    final max = widget.totalPages.toDouble();
    if (_dragging && _dragValue != null) {
      return _dragValue!.clamp(1.0, max);
    }
    if (_pendingReleasePage != null) {
      return _pendingReleasePage!.clamp(1, widget.totalPages).toDouble();
    }
    return widget.currentPage.toDouble().clamp(1.0, max);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final thumbRadius = tokens.spaceSmall;
    final overlayRadius = tokens.iconSizeLarge;

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: tokens.progressHeight + tokens.borderWidthThin,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withValues(
          alpha: tokens.opacitySubtle,
        ),
        thumbColor: colorScheme.primary,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: thumbRadius,
          elevation: 0,
          pressedElevation: tokens.spaceTiny,
        ),
        overlayColor: colorScheme.primary.withValues(
          alpha: tokens.opacitySubtle,
        ),
        overlayShape: RoundSliderOverlayShape(overlayRadius: overlayRadius),
      ),
      child: RepaintBoundary(
        child: Slider(
          value: _sliderValue,
          min: 1,
          max: widget.totalPages.toDouble(),
          // divisions intentionally omitted — 603 tick marks are invisible at
          // this density and cause expensive CustomPainter repaints on every
          // animation frame when the nav overlay slides in/out.
          onChangeStart: (_) {
            if (_pendingReleasePage != null) {
              PerfLogger.logQuranPerf(
                '[QuranPerf][Slider]',
                'pendingRelease cleared reason=dragStart',
              );
            }
            setState(() {
              _pendingReleasePage = null;
              _dragging = true;
              _dragValue = _sliderValue;
            });
          },
          onChanged: (value) {
            setState(() => _dragValue = value);
            widget.onChanged(value);
          },
          onChangeEnd: (value) {
            final rounded = value.round().clamp(1, widget.totalPages);
            PerfLogger.logQuranPerf(
              '[QuranPerf][Slider]',
              'pendingRelease set page=$rounded',
            );
            setState(() {
              _dragging = false;
              _dragValue = null;
              _pendingReleasePage = rounded;
            });
            widget.onChangeEnd?.call(value);
          },
        ),
      ),
    );
  }
}
