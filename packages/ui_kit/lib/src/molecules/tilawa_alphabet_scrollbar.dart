import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

class TilawaAlphabetScrollbar extends StatefulWidget {
  const TilawaAlphabetScrollbar({
    super.key,
    required this.letters,
    required this.selectedLetter,
    required this.onLetterSelected,
    required this.onPanUpdate,
    required this.onPanStart,
    required this.onPanEnd,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    this.scrollbarSemanticsLabel,
    this.scrollbarSemanticsHint,
    this.scrollbarSemanticsIdentifier,
    this.overlaySemanticsIdentifier,
    this.selectedLetterSemanticsId,
    this.selectedLetterStableSemanticsId,
  });

  final List<String> letters;
  final String? selectedLetter;
  final ValueChanged<String?> onLetterSelected;

  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragStartCallback onPanStart;
  final GestureDragEndCallback onPanEnd;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;
  final GestureLongPressEndCallback? onLongPressEnd;

  /// Optional group label for the scrollbar (e.g. "Letter index").
  final String? scrollbarSemanticsLabel;

  /// Optional hint for drag-to-select behavior.
  final String? scrollbarSemanticsHint;

  /// Optional Maestro / a11y identifier for the scrubber rail container.
  final String? scrollbarSemanticsIdentifier;

  /// Optional Maestro / a11y identifier for the center scrub bubble.
  final String? overlaySemanticsIdentifier;

  /// Optional per-letter identifier for the actively selected rail row.
  final String Function(String letter)? selectedLetterSemanticsId;

  /// Optional locale-independent identifier for whichever letter is selected.
  final String? selectedLetterStableSemanticsId;

  @override
  State<TilawaAlphabetScrollbar> createState() =>
      _TilawaAlphabetScrollbarState();
}

class _TilawaAlphabetScrollbarState extends State<TilawaAlphabetScrollbar> {
  final Map<String, Widget> _itemCache = {};
  final _overlayController = OverlayPortalController();
  final _trackKey = GlobalKey();
  final ScrollController _railScrollController = ScrollController();
  String? _draggedLetter;
  String? _lastNotifiedLetter;
  String? _lastActiveLetter;
  bool _isScrubbing = false;
  bool _pointerMoved = false;
  String? _pointerDownSelectedLetter;
  Offset? _pointerDownPosition;
  int? _activePointer;
  bool _lastBuiltScrubbing = false;
  Brightness? _cachedItemThemeBrightness;

  static const double _kPointerMoveSlop = 8;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Brightness brightness = Theme.of(context).brightness;
    if (_cachedItemThemeBrightness != brightness) {
      _cachedItemThemeBrightness = brightness;
      _itemCache.clear();
    }
  }

  @override
  void dispose() {
    _detachPointerRoute();
    _railScrollController.dispose();
    super.dispose();
  }

  void _detachPointerRoute() {
    final pointer = _activePointer;
    if (pointer == null) {
      return;
    }
    GestureBinding.instance.pointerRouter.removeRoute(
      pointer,
      _handleGlobalPointerEvent,
    );
    _activePointer = null;
  }

  @override
  void initState() {
    super.initState();
    _lastActiveLetter = widget.selectedLetter;
  }

  @override
  void didUpdateWidget(covariant TilawaAlphabetScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLetter != oldWidget.selectedLetter) {
      // If no pan/long-press is actively driving updates, the selection change
      // came from a tap that's already finished. The pending hide timer would
      // otherwise keep _draggedLetter set for 600ms, painting the selection
      // circle on the wrong letter. Reconcile immediately so the visual matches
      // the BLoC state.
      if (_lastNotifiedLetter == null) {
        _draggedLetter = null;
        // Defer overlay mutation to avoid asserting in persistentCallbacks phase.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _overlayController.hide();
        });
      }
      _lastActiveLetter = oldWidget.selectedLetter;

      // Clear cache when selection changes to ensure fresh UI
      _itemCache.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToSelectedLetter();
        }
      });
    }
  }

  _AlphabetScrollbarTrackLayout _trackLayout(
    RenderBox box,
    TilawaAlphabetScrollbarTokens componentTokens,
  ) {
    return _AlphabetScrollbarTrackLayout.resolve(
      letterCount: widget.letters.length,
      maxTrackHeight: box.size.height,
      preferredSlotExtent: componentTokens.itemExtent,
    );
  }

  void _scrollToSelectedLetter() {
    final String? selectedLetter = widget.selectedLetter;
    if (selectedLetter == null || !_railScrollController.hasClients) {
      return;
    }

    final renderObject = _trackKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) {
      return;
    }

    final theme = Theme.of(context);
    final componentTokens = theme.componentTokens.alphabetScrollbar;
    final layout = _trackLayout(renderObject, componentTokens);
    if (!layout.isScrollable) {
      return;
    }

    final int index = widget.letters.indexOf(selectedLetter);
    if (index < 0) {
      return;
    }

    final double viewportHeight = renderObject.size.height;
    final double letterCenter = layout.centerForIndex(index);
    final double bottomClearance = componentTokens.selectedIndicatorExtent / 2;
    final double maxScrollExtent =
        _railScrollController.position.maxScrollExtent;

    final double targetOffset = switch (index) {
      0 => 0,
      final int last when last == widget.letters.length - 1 =>
        (layout.centerForIndex(index) +
                layout.slotHeight / 2 +
                bottomClearance -
                viewportHeight)
            .clamp(0.0, maxScrollExtent),
      _ => (letterCenter - viewportHeight / 2).clamp(0.0, maxScrollExtent),
    };
    _railScrollController.animateTo(
      targetOffset,
      duration: theme.tokens.durationFast,
      curve: Curves.easeOutCubic,
    );
  }

  void _autoScrollDuringScrub(double localY, double viewportHeight) {
    if (!_railScrollController.hasClients) {
      return;
    }

    const double edgeThreshold = 20;
    const double step = 14;
    final double maxExtent = _railScrollController.position.maxScrollExtent;
    if (maxExtent <= 0) {
      return;
    }

    if (localY > viewportHeight - edgeThreshold) {
      _railScrollController.jumpTo(
        math.min(_railScrollController.offset + step, maxExtent),
      );
    } else if (localY < edgeThreshold) {
      _railScrollController.jumpTo(
        math.max(_railScrollController.offset - step, 0),
      );
    }
  }

  String? _letterAtPosition(Offset globalPosition) {
    if (!mounted || widget.letters.isEmpty) return null;
    final renderObject = _trackKey.currentContext?.findRenderObject();
    if (renderObject == null || renderObject is! RenderBox) return null;
    final box = renderObject;

    final localPosition = box.globalToLocal(globalPosition);
    // During scrub, Android keeps mapping Y even when the finger drifts off the
    // narrow rail horizontally.
    if (!_isScrubbing &&
        (localPosition.dx < 0 || localPosition.dx > box.size.width)) {
      return null;
    }

    final theme = Theme.of(context);
    final componentTokens = theme.componentTokens.alphabetScrollbar;
    final layout = _trackLayout(box, componentTokens);
    return layout.letterAt(
      localPosition.dy,
      widget.letters,
      scrollOffset: _railScrollController.hasClients
          ? _railScrollController.offset
          : 0,
    );
  }

  String? get _activeLetter {
    if (_isScrubbing && _draggedLetter != null) {
      return _draggedLetter;
    }
    return widget.selectedLetter;
  }

  void _notifyPanStart(Offset globalPosition) {
    widget.onPanStart(
      DragStartDetails(globalPosition: globalPosition),
    );
    widget.onLongPressStart?.call(
      LongPressStartDetails(globalPosition: globalPosition),
    );
  }

  void _notifyPanUpdate(Offset globalPosition) {
    widget.onPanUpdate(
      DragUpdateDetails(globalPosition: globalPosition),
    );
    widget.onLongPressMoveUpdate?.call(
      LongPressMoveUpdateDetails(globalPosition: globalPosition),
    );
  }

  void _notifyPanEnd() {
    widget.onPanEnd(DragEndDetails());
    widget.onLongPressEnd?.call(const LongPressEndDetails());
  }

  void _beginScrub(Offset globalPosition) {
    final letter = _letterAtPosition(globalPosition);
    if (letter == null) {
      return;
    }

    setState(() {
      _isScrubbing = true;
      _draggedLetter = letter;
      _itemCache.clear();
    });
    _overlayController.show();
    _notifyPanStart(globalPosition);

    if (letter != _pointerDownSelectedLetter) {
      HapticFeedback.selectionClick();
      _lastNotifiedLetter = letter;
      widget.onLetterSelected(letter);
    }
  }

  void _updateScrub(Offset globalPosition) {
    if (!_isScrubbing) {
      return;
    }

    final letter = _letterAtPosition(globalPosition);
    if (letter == null) {
      return;
    }

    if (letter != _draggedLetter) {
      HapticFeedback.selectionClick();
      setState(() {
        _lastActiveLetter = _draggedLetter ?? widget.selectedLetter;
        _draggedLetter = letter;
      });
      if (letter != _lastNotifiedLetter) {
        _lastNotifiedLetter = letter;
        widget.onLetterSelected(letter);
      }
    }

    final renderObject = _trackKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      final localY = renderObject.globalToLocal(globalPosition).dy;
      _autoScrollDuringScrub(localY, renderObject.size.height);
    }

    _notifyPanUpdate(globalPosition);
  }

  void _finishScrub() {
    if (!_isScrubbing) {
      return;
    }

    if (!_pointerMoved &&
        _draggedLetter != null &&
        _draggedLetter == _pointerDownSelectedLetter) {
      widget.onLetterSelected(null);
    }

    setState(() {
      _isScrubbing = false;
      _lastActiveLetter = _draggedLetter ?? widget.selectedLetter;
      _draggedLetter = null;
      _lastNotifiedLetter = null;
      _pointerDownPosition = null;
      _itemCache.clear();
    });
    _overlayController.hide();
    _notifyPanEnd();
  }

  void _handlePointerDown(PointerDownEvent event) {
    // Ignore concurrent touches — only the first pointer drives the scrub.
    // Without this guard a second touch would overwrite _activePointer and
    // leak the first pointer's route in GestureBinding.pointerRouter forever.
    if (_activePointer != null) {
      return;
    }
    _pointerMoved = false;
    _pointerDownSelectedLetter = widget.selectedLetter;
    _pointerDownPosition = event.position;
    _activePointer = event.pointer;
    GestureBinding.instance.pointerRouter.addRoute(
      event.pointer,
      _handleGlobalPointerEvent,
    );
    _beginScrub(event.position);
  }

  void _handleGlobalPointerEvent(PointerEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }

    switch (event) {
      case PointerMoveEvent():
        _handlePointerMove(event);
      case PointerUpEvent():
        _detachPointerRoute();
        _finishScrub();
      case PointerCancelEvent():
        _detachPointerRoute();
        _finishScrub();
      default:
        break;
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isScrubbing) {
      return;
    }

    if (_pointerDownPosition != null &&
        (event.position - _pointerDownPosition!).distance > _kPointerMoveSlop) {
      _pointerMoved = true;
    }
    _updateScrub(event.position);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final componentTokens = theme.componentTokens.alphabetScrollbar;
    final ColorScheme colorScheme = theme.colorScheme;
    final Color primaryColor = colorScheme.primary;
    final Color unselectedColor = colorScheme.onSurface.withValues(
      alpha: _isScrubbing ? tokens.opacityEmphasis : tokens.opacityMedium,
    );
    final Color trackBorderColor = _isScrubbing
        ? primaryColor.withValues(alpha: tokens.opacityMedium)
        : colorScheme.outlineVariant.withValues(alpha: tokens.opacityMedium);

    return RepaintBoundary(
      child: _MaybeScrollbarSemantics(
        label: widget.scrollbarSemanticsLabel,
        hint: widget.scrollbarSemanticsHint,
        identifier: widget.scrollbarSemanticsIdentifier,
        child: OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: (context) {
            if (!_isScrubbing || _draggedLetter == null) {
              return const SizedBox.shrink();
            }

            final Size screenSize = MediaQuery.sizeOf(context);
            final double overlayLeft =
                (screenSize.width - componentTokens.overlaySize) / 2;
            final double overlayTop =
                (screenSize.height - componentTokens.overlaySize) / 2;

            return Positioned(
              left: overlayLeft,
              top: overlayTop,
              child: DefaultTextStyle(
                style: theme.textTheme.displaySmall!.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: componentTokens.overlayFontSize,
                ),
                child: TweenAnimationBuilder<double>(
                  duration: theme.tokens.durationFast,
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0.85, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Semantics(
                    identifier: widget.overlaySemanticsIdentifier,
                    liveRegion: true,
                    label: _draggedLetter,
                    child: Container(
                      key: const Key('alphabet_scrollbar_overlay'),
                      width: componentTokens.overlaySize,
                      height: componentTokens.overlaySize,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.onPrimary.withValues(
                            alpha: tokens.opacitySubtle,
                          ),
                          width: tokens.borderWidthThin * 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: componentTokens.overlayShadowColor,
                            blurRadius: componentTokens.overlayShadowBlur,
                            offset: componentTokens.overlayShadowOffset,
                          ),
                          BoxShadow(
                            color: primaryColor.withValues(
                              alpha: tokens.opacityShadow,
                            ),
                            blurRadius: tokens.blurShadow,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(child: Text(_draggedLetter!)),
                    ),
                  ),
                ),
              ),
            );
          },
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _handlePointerDown,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final BorderRadius borderRadius = BorderRadius.circular(
                  tokens.resolveRadius(family: TilawaRadiusFamily.card),
                );
                final _AlphabetScrollbarTrackLayout layout =
                    _AlphabetScrollbarTrackLayout.resolve(
                      letterCount: widget.letters.length,
                      maxTrackHeight: constraints.maxHeight,
                      preferredSlotExtent: componentTokens.itemExtent,
                    );

                final Widget letterStack = SizedBox(
                  height: layout.contentHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (
                        int index = 0;
                        index < widget.letters.length;
                        index++
                      )
                        Positioned(
                          top: layout.topForIndex(index),
                          left: 0,
                          right: 0,
                          height: layout.slotHeight,
                          child: _buildLetterItem(
                            letter: widget.letters[index],
                            slotHeight: layout.slotHeight,
                            primaryColor: primaryColor,
                            unselectedColor: unselectedColor,
                            componentTokens: componentTokens,
                            isScrubbing: _isScrubbing,
                          ),
                        ),
                    ],
                  ),
                );

                final Widget letterRail = layout.isScrollable
                    ? _AlphabetRailScrollView(
                        controller: _railScrollController,
                        physics: _isScrubbing
                            ? const NeverScrollableScrollPhysics()
                            : const ClampingScrollPhysics(),
                        child: letterStack,
                      )
                    : letterStack;

                return Align(
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: tokens.durationFast,
                    curve: Curves.easeOutCubic,
                    clipBehavior: Clip.antiAlias,
                    key: _trackKey,
                    width: componentTokens.width,
                    height: layout.trackHeight,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: borderRadius,
                      border: Border.all(
                        color: trackBorderColor,
                        width:
                            tokens.borderWidthThin * (_isScrubbing ? 2 : 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(
                            alpha: tokens.opacityShadow * 0.6,
                          ),
                          blurRadius: tokens.blurShadow / 2,
                          offset: tokens.shadowOffsetSmall,
                        ),
                      ],
                    ),
                    child: letterRail,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLetterItem({
    required String letter,
    required double slotHeight,
    required Color primaryColor,
    required Color unselectedColor,
    required TilawaAlphabetScrollbarTokens componentTokens,
    required bool isScrubbing,
  }) {
    final activeLetter = _activeLetter;
    final isSelected = letter == activeLetter;
    final wasActive = letter == _lastActiveLetter;
    final double selectedIndicatorSize = math.min(
      componentTokens.selectedIndicatorExtent,
      slotHeight * 0.92,
    );

    if (isSelected != wasActive ||
        isScrubbing != _lastBuiltScrubbing ||
        !_itemCache.containsKey(letter)) {
      _lastBuiltScrubbing = isScrubbing;
      _itemCache[letter] = _LetterItem(
        key: ValueKey(letter),
        letter: letter,
        isSelected: isSelected,
        isScrubbing: isScrubbing,
        semanticsIdentifier: isSelected
            ? widget.selectedLetterStableSemanticsId ??
                  widget.selectedLetterSemanticsId?.call(letter)
            : null,
        selectedIndicatorSize: selectedIndicatorSize,
        fontSize: componentTokens.letterFontSize,
        primaryColor: primaryColor,
        unselectedColor: unselectedColor,
      );
    }

    return _itemCache[letter]!;
  }
}

/// Keeps alphabet-rail scroll isolated from ancestor [ScrollView]s (e.g.
/// [NestedScrollView] on Reciters).
class _AlphabetRailScrollView extends StatelessWidget {
  const _AlphabetRailScrollView({
    required this.controller,
    required this.physics,
    required this.child,
  });

  final ScrollController controller;
  final ScrollPhysics physics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController.none(
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) => true,
        child: NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (OverscrollIndicatorNotification notification) {
            notification.disallowIndicator();
            return true;
          },
          child: SingleChildScrollView(
            key: const Key('alphabet_scrollbar_scroll'),
            controller: controller,
            physics: physics,
            child: child,
          ),
        ),
      ),
    );
  }
}

@immutable
class _AlphabetScrollbarTrackLayout {
  const _AlphabetScrollbarTrackLayout({
    required this.slotHeight,
    required this.contentHeight,
    required this.trackHeight,
    required this.isScrollable,
  });

  final double slotHeight;
  final double contentHeight;
  final double trackHeight;
  final bool isScrollable;

  static _AlphabetScrollbarTrackLayout resolve({
    required int letterCount,
    required double maxTrackHeight,
    required double preferredSlotExtent,
  }) {
    if (letterCount <= 0 || !maxTrackHeight.isFinite || maxTrackHeight <= 0) {
      return const _AlphabetScrollbarTrackLayout(
        slotHeight: 0,
        contentHeight: 0,
        trackHeight: 0,
        isScrollable: false,
      );
    }

    final double packedContentHeight = letterCount * preferredSlotExtent;
    if (packedContentHeight <= maxTrackHeight) {
      return _AlphabetScrollbarTrackLayout(
        slotHeight: preferredSlotExtent,
        contentHeight: packedContentHeight,
        trackHeight: packedContentHeight,
        isScrollable: false,
      );
    }

    return _AlphabetScrollbarTrackLayout(
      slotHeight: preferredSlotExtent,
      contentHeight: packedContentHeight,
      trackHeight: maxTrackHeight,
      isScrollable: true,
    );
  }

  double topForIndex(int index) => index * slotHeight;

  double centerForIndex(int index) => topForIndex(index) + (slotHeight / 2);

  String? letterAt(
    double localY,
    List<String> letters, {
    double scrollOffset = 0,
  }) {
    if (letters.isEmpty || contentHeight <= 0 || slotHeight <= 0) {
      return letters.isEmpty ? null : letters.first;
    }

    final double contentY = localY + scrollOffset;
    if (contentY < 0) {
      return letters.first;
    }
    if (contentY >= contentHeight) {
      return letters.last;
    }

    final int letterIndex = (contentY / slotHeight).floor().clamp(
      0,
      letters.length - 1,
    );
    return letters[letterIndex];
  }
}

class _MaybeScrollbarSemantics extends StatelessWidget {
  const _MaybeScrollbarSemantics({
    required this.label,
    required this.hint,
    required this.identifier,
    required this.child,
  });

  final String? label;
  final String? hint;
  final String? identifier;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (label == null && hint == null && identifier == null) {
      return child;
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      identifier: identifier,
      label: label,
      hint: hint,
      child: child,
    );
  }
}

class _LetterItem extends StatelessWidget {
  const _LetterItem({
    super.key,
    required this.letter,
    required this.isSelected,
    required this.isScrubbing,
    required this.semanticsIdentifier,
    required this.selectedIndicatorSize,
    required this.fontSize,
    required this.primaryColor,
    required this.unselectedColor,
  });

  final String letter;
  final bool isSelected;
  final bool isScrubbing;
  final String? semanticsIdentifier;
  final double selectedIndicatorSize;
  final double fontSize;
  final Color primaryColor;
  final Color unselectedColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final TextStyle baseStyle =
        theme.textTheme.labelSmall?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          height: 1,
        ) ??
        TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          height: 1,
        );

    return Center(
      child: Semantics(
        identifier: semanticsIdentifier,
        selected: isSelected,
        label: letter,
        child: AnimatedScale(
          scale: isSelected ? 1.0 : (isScrubbing ? 0.96 : 0.9),
          duration: tokens.durationFast,
          curve: Curves.easeOutCubic,
          child: isSelected
              ? Container(
                  width: selectedIndicatorSize,
                  height: selectedIndicatorSize,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(
                          alpha: tokens.opacityMedium,
                        ),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: baseStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                )
              : Text(
                  letter,
                  style: baseStyle.copyWith(color: unselectedColor),
                ),
        ),
      ),
    );
  }
}
