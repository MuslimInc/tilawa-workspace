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
  String? _draggedLetter;
  String? _lastNotifiedLetter;
  String? _lastActiveLetter;
  bool _isScrubbing = false;
  bool _pointerMoved = false;
  String? _pointerDownSelectedLetter;
  Offset? _pointerDownPosition;
  int? _activePointer;

  static const double _kPointerMoveSlop = 8;

  @override
  void dispose() {
    _detachPointerRoute();
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
    final resolvedPadding = componentTokens.verticalPadding.resolve(
      Directionality.of(context),
    );
    final trackTop = resolvedPadding.top;
    final trackBottom = box.size.height - resolvedPadding.bottom;
    final trackHeight = trackBottom - trackTop;
    if (trackHeight <= 0) {
      return widget.letters.first;
    }

    final y = localPosition.dy.clamp(trackTop, trackBottom);
    final normalized = (y - trackTop) / trackHeight;
    final letterIndex = (normalized * widget.letters.length)
        .floor()
        .clamp(0, widget.letters.length - 1);
    return widget.letters[letterIndex];
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
    final primaryColor = theme.colorScheme.primary;
    final unselectedColor = theme.colorScheme.onSurfaceVariant.withValues(
      alpha: tokens.opacityEmphasis,
    );

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
                  color: theme.colorScheme.onPrimary,
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
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: componentTokens.overlayShadowColor,
                            blurRadius: componentTokens.overlayShadowBlur,
                            offset: componentTokens.overlayShadowOffset,
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
            child: Container(
              key: _trackKey,
              width: componentTokens.width,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(
                  alpha: tokens.opacityGlass,
                ),
                borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
              ),
              child: Padding(
                padding: componentTokens.verticalPadding,
                child: Column(
                  children: [
                    for (final letter in widget.letters)
                      Expanded(
                        child: _buildLetterItem(
                          letter: letter,
                          primaryColor: primaryColor,
                          unselectedColor: unselectedColor,
                          componentTokens: componentTokens,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLetterItem({
    required String letter,
    required Color primaryColor,
    required Color unselectedColor,
    required TilawaAlphabetScrollbarTokens componentTokens,
  }) {
    final activeLetter = _activeLetter;
    final isSelected = letter == activeLetter;
    final wasActive = letter == _lastActiveLetter;

    if (isSelected != wasActive || !_itemCache.containsKey(letter)) {
      _itemCache[letter] = _LetterItem(
        key: ValueKey(letter),
        letter: letter,
        isSelected: isSelected,
        semanticsIdentifier: isSelected
            ? widget.selectedLetterStableSemanticsId ??
                widget.selectedLetterSemanticsId?.call(letter)
            : null,
        selectedIndicatorSize: componentTokens.selectedIndicatorExtent,
        fontSize: componentTokens.letterFontSize,
        primaryColor: primaryColor,
        unselectedColor: unselectedColor,
      );
    }

    return _itemCache[letter]!;
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
    required this.semanticsIdentifier,
    required this.selectedIndicatorSize,
    required this.fontSize,
    required this.primaryColor,
    required this.unselectedColor,
  });

  final String letter;
  final bool isSelected;
  final String? semanticsIdentifier;
  final double selectedIndicatorSize;
  final double fontSize;
  final Color primaryColor;
  final Color unselectedColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        identifier: semanticsIdentifier,
        selected: isSelected,
        label: letter,
        child: isSelected
            ? Container(
                width: selectedIndicatorSize,
                height: selectedIndicatorSize,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              )
            : Text(
                letter,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: unselectedColor,
                ),
              ),
      ),
    );
  }
}
