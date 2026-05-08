import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

class ArabicAlphabetScrollbar extends StatefulWidget {
  const ArabicAlphabetScrollbar({
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

  @override
  State<ArabicAlphabetScrollbar> createState() =>
      _ArabicAlphabetScrollbarState();
}

class _ArabicAlphabetScrollbarState extends State<ArabicAlphabetScrollbar> {
  final Map<String, Widget> _itemCache = {};
  final _overlayController = OverlayPortalController();
  final _scrollController = ScrollController();
  String? _draggedLetter;
  Offset? _draggedOffset;
  String? _lastNotifiedLetter;
  String? _lastActiveLetter;
  Timer? _hideOverlayTimer;

  @override
  void initState() {
    super.initState();
    _lastActiveLetter = widget.selectedLetter;
  }

  @override
  void dispose() {
    _hideOverlayTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ArabicAlphabetScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLetter != oldWidget.selectedLetter) {
      // If no pan/long-press is actively driving updates, the selection change
      // came from a tap that's already finished. The pending hide timer would
      // otherwise keep _draggedLetter set for 600ms, painting the selection
      // circle on the wrong letter. Reconcile immediately so the visual matches
      // the BLoC state.
      if (_lastNotifiedLetter == null) {
        _hideOverlayTimer?.cancel();
        _hideOverlayTimer = null;
        _draggedLetter = null;
        _draggedOffset = null;
        // Defer overlay mutation to avoid asserting in persistentCallbacks phase.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _overlayController.hide();
        });
      }
      _lastActiveLetter = oldWidget.selectedLetter;

      // Clear cache when selection changes to ensure fresh UI
      _itemCache.clear();

      // NOTE: Auto-scroll disabled for testing - uncomment to re-enable
      if (widget.selectedLetter != null) {
        _scrollToLetter(widget.selectedLetter!);
      }
    }
  }

  void _scrollToLetter(String letter) {
    if (!_scrollController.hasClients) return;
    final index = widget.letters.indexOf(letter);
    if (index != -1) {
      final theme = Theme.of(context);
      final componentTokens = theme.componentTokens.alphabetScrollbar;
      final target = index * componentTokens.itemExtent;
      _scrollController.animateTo(
        target.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String? _updateDraggedLetter(Offset globalPosition) {
    if (!mounted) return null;
    final renderObject = context.findRenderObject();
    if (renderObject == null || renderObject is! RenderBox) return null;
    final box = renderObject;

    final localPosition = box.globalToLocal(globalPosition);
    final theme = Theme.of(context);
    final componentTokens = theme.componentTokens.alphabetScrollbar;

    final double letterHeight = componentTokens.itemExtent;

    // Adjust localPosition by vertical padding and scroll offset
    final resolvedPadding = componentTokens.verticalPadding.resolve(
      Directionality.of(context),
    );
    final double scrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0;
    final double relativeY =
        localPosition.dy - resolvedPadding.top + scrollOffset;

    // Only select a letter when the pointer is inside an actual letter row.
    // Tapping in the whitespace above the first row or below the last row
    // should not select anything.
    if (relativeY < 0 || relativeY >= widget.letters.length * letterHeight) {
      return null;
    }

    final letterIndex = (relativeY / letterHeight).floor();

    if (letterIndex >= 0 && letterIndex < widget.letters.length) {
      final newLetter = widget.letters[letterIndex];
      if (newLetter != _draggedLetter) {
        debugPrint(
          '[SelectedLetter] [${DateTime.now()}] Hovered: $newLetter at index $letterIndex (Current selected: ${widget.selectedLetter})',
        );
        HapticFeedback.selectionClick();
        setState(() {
          _lastActiveLetter = _draggedLetter ?? widget.selectedLetter;
          _draggedLetter = newLetter;
          _draggedOffset = localPosition;
        });
      } else if (_draggedOffset != localPosition) {
        setState(() {
          _draggedOffset = localPosition;
        });
      }
      return newLetter;
    }
    return null;
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
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) {
          if (_draggedLetter == null || _draggedOffset == null) {
            return const SizedBox.shrink();
          }

          final RenderBox box = this.context.findRenderObject()! as RenderBox;
          final Offset globalOffset = box.localToGlobal(Offset.zero);
          final Size screenSize = MediaQuery.sizeOf(context);

          // Determine if the scrollbar is on the left or right side of the screen
          final bool isOnRightSide = globalOffset.dx > screenSize.width / 2;

          return Positioned(
            left: isOnRightSide
                ? null
                : globalOffset.dx +
                      componentTokens.width +
                      componentTokens.overlayOffset,
            right: isOnRightSide
                ? (screenSize.width - globalOffset.dx) +
                      componentTokens.overlayOffset
                : null,
            top:
                globalOffset.dy +
                _draggedOffset!.dy -
                (componentTokens.overlaySize / 2),
            child: DefaultTextStyle(
              style: theme.textTheme.displaySmall!.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: componentTokens.overlayFontSize,
              ),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: const Key('alphabet_scrollbar_overlay'),
                  width: componentTokens.overlaySize,
                  height: componentTokens.overlaySize,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                      componentTokens.overlayRadius,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: tokens.blurShadow,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(child: Text(_draggedLetter!)),
                ),
              ),
            ),
          );
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            // Cancel any pending hide so a quick second tap keeps the overlay visible
            _hideOverlayTimer?.cancel();
            _hideOverlayTimer = null;
            // Show overlay immediately on press, except when tapping the already-selected
            // letter — that tap toggles selection off, so the overlay would just flash.
            final letter = _updateDraggedLetter(details.globalPosition);
            if (letter != null && letter != widget.selectedLetter) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _overlayController.show();
              });
            }
          },
          onTapUp: (details) {
            // Delay long enough that a follow-up tap (double press) cancels the hide
            // before it fires, so the overlay stays visible across rapid presses.
            _hideOverlayTimer?.cancel();
            _hideOverlayTimer = Timer(const Duration(milliseconds: 600), () {
              _hideOverlayTimer = null;
              if (mounted) {
                setState(() {
                  _lastActiveLetter = _draggedLetter ?? widget.selectedLetter;
                  _draggedLetter = null;
                  _draggedOffset = null;
                });
                _overlayController.hide();
              }
            });
          },
          onTapCancel: () {
            // The outer tap can be cancelled because either (a) the inner letter
            // InkWell won the gesture arena and consumed the tap, or (b) a long-press/pan
            // is starting. In case (a) no further callback fires, so we must schedule
            // the auto-hide here. In case (b) the upcoming onLongPressStart / onPanStart
            // re-shows the overlay, and onLongPressEnd / onPanEnd hide it — but those
            // handlers also cancel this timer, so it's safe to schedule it unconditionally.
            _hideOverlayTimer?.cancel();
            _hideOverlayTimer = Timer(const Duration(milliseconds: 600), () {
              _hideOverlayTimer = null;
              if (mounted) {
                setState(() {
                  _lastActiveLetter = _draggedLetter ?? widget.selectedLetter;
                  _draggedLetter = null;
                  _draggedOffset = null;
                });
                _overlayController.hide();
              }
            });
          },
          onPanStart: (details) {
            // Cancel any auto-hide scheduled by the preceding onTapCancel
            _hideOverlayTimer?.cancel();
            _hideOverlayTimer = null;
            final letter = _updateDraggedLetter(details.globalPosition);
            if (letter != null) {
              _lastNotifiedLetter = letter;
              widget.onLetterSelected(letter);
            }
            _overlayController.show();
            widget.onPanStart(details);
          },
          onPanUpdate: (details) {
            final letter = _updateDraggedLetter(details.globalPosition);
            if (letter != null && letter != _lastNotifiedLetter) {
              _lastNotifiedLetter = letter;
              widget.onLetterSelected(letter);
            }
            widget.onPanUpdate(details);
          },
          onPanEnd: (details) {
            setState(() {
              _lastActiveLetter = _draggedLetter ?? widget.selectedLetter;
              _draggedLetter = null;
              _draggedOffset = null;
              _lastNotifiedLetter = null;
            });
            _overlayController.hide();
            widget.onPanEnd(details);
          },
          onLongPressStart: (details) {
            // Cancel any auto-hide scheduled by the preceding onTapCancel
            _hideOverlayTimer?.cancel();
            _hideOverlayTimer = null;
            final letter = _updateDraggedLetter(details.globalPosition);
            if (letter != null) {
              _lastNotifiedLetter = letter;
              debugPrint(
                '[SelectedLetter] [${DateTime.now()}] LongPress Select: $letter (Current selected: ${widget.selectedLetter})',
              );
              widget.onLetterSelected(letter);
            }
            // Show overlay after state is updated (ensures _draggedLetter is set)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _overlayController.show();
            });
            widget.onLongPressStart?.call(details);
          },
          onLongPressMoveUpdate: (details) {
            final letter = _updateDraggedLetter(details.globalPosition);
            if (letter != null && letter != _lastNotifiedLetter) {
              _lastNotifiedLetter = letter;
              debugPrint(
                '[SelectedLetter] [${DateTime.now()}] LongPress Move: $letter (Current selected: ${widget.selectedLetter})',
              );
              widget.onLetterSelected(letter);
            }
            widget.onLongPressMoveUpdate?.call(details);
          },
          onLongPressEnd: (details) {
            setState(() {
              _lastActiveLetter = _draggedLetter ?? widget.selectedLetter;
              _draggedLetter = null;
              _draggedOffset = null;
              _lastNotifiedLetter = null;
            });
            _overlayController.hide();
            widget.onLongPressEnd?.call(details);
          },
          child: Container(
            width: componentTokens.width,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(
                alpha: tokens.opacityGlass,
              ),
              borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
            ),
            child: ListView.builder(
              controller: _scrollController,
              padding: componentTokens.verticalPadding,
              physics: const ClampingScrollPhysics(),
              itemCount: widget.letters.length,
              itemExtent: componentTokens.itemExtent,
              itemBuilder: (context, index) {
                final letter = widget.letters[index];
                final activeLetter = _draggedLetter ?? widget.selectedLetter;
                final isSelected = letter == activeLetter;
                final wasActive = letter == _lastActiveLetter;

                // Only create new widget if selection state changed for this item
                // Otherwise reuse cached widget
                if (isSelected != wasActive ||
                    !_itemCache.containsKey(letter)) {
                  _itemCache[letter] = _LetterItem(
                    key: ValueKey(letter),
                    letter: letter,
                    isSelected: isSelected,
                    actualSelectedLetter: widget.selectedLetter,
                    onLetterSelected: widget.onLetterSelected,
                    size: componentTokens.itemExtent,
                    selectedIndicatorSize:
                        componentTokens.selectedIndicatorExtent,
                    fontSize: componentTokens.letterFontSize,
                    primaryColor: primaryColor,
                    unselectedColor: unselectedColor,
                  );
                }

                return _itemCache[letter]!;
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterItem extends StatelessWidget {
  const _LetterItem({
    super.key,
    required this.letter,
    required this.isSelected,
    required this.actualSelectedLetter,
    required this.onLetterSelected,
    required this.size,
    required this.selectedIndicatorSize,
    required this.fontSize,
    required this.primaryColor,
    required this.unselectedColor,
  });

  final String letter;
  final bool isSelected;
  final String? actualSelectedLetter;
  final ValueChanged<String?> onLetterSelected;
  final double size;
  final double selectedIndicatorSize;
  final double fontSize;
  final Color primaryColor;
  final Color unselectedColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          debugPrint(
            '[SelectedLetter] [${DateTime.now()}] ✓ TAP Toggle: $letter '
            '(Actual selected: $actualSelectedLetter)',
          );
          if (letter == actualSelectedLetter) {
            onLetterSelected(null);
          } else {
            onLetterSelected(letter);
          }
        },
        child: SizedBox(
          height: size,
          width: size,
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
              : Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: unselectedColor,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
