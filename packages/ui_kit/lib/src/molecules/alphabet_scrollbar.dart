import 'package:flutter/material.dart';

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
  final ValueChanged<String> onLetterSelected;
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
  String? _lastSelectedLetter;
  final Map<String, Widget> _itemCache = {};
  final _overlayController = OverlayPortalController();
  String? _draggedLetter;
  Offset? _draggedOffset;

  @override
  void initState() {
    super.initState();
    _lastSelectedLetter = widget.selectedLetter;
  }

  @override
  void didUpdateWidget(covariant ArabicAlphabetScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _lastSelectedLetter = oldWidget.selectedLetter;
    // Clear cache when selection changes
    _itemCache.clear();
  }

  void _updateDraggedLetter(Offset globalPosition) {
    final box = context.findRenderObject()! as RenderBox;
    final localPosition = box.globalToLocal(globalPosition);
    final theme = Theme.of(context);
    final componentTokens = theme.componentTokens.alphabetScrollbar;

    final double contentHeight =
        box.size.height - (componentTokens.verticalPadding.vertical);
    final double letterHeight = contentHeight / widget.letters.length;

    // Adjust localPosition by vertical padding
    final double relativeY =
        localPosition.dy - (componentTokens.verticalPadding.vertical / 2);

    final letterIndex = (relativeY / letterHeight)
        .clamp(0, widget.letters.length - 1)
        .floor();

    if (letterIndex >= 0 && letterIndex < widget.letters.length) {
      setState(() {
        _draggedLetter = widget.letters[letterIndex];
        // Keep offset within scrollbar bounds for positioning the overlay
        _draggedOffset = localPosition;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final componentTokens = theme.componentTokens.alphabetScrollbar;
    final primaryColor = theme.primaryColor;
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
                  width: componentTokens.overlaySize,
                  height: componentTokens.overlaySize,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
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
          behavior: .opaque,
          onPanStart: (details) {
            _updateDraggedLetter(details.globalPosition);
            _overlayController.show();
            widget.onPanStart(details);
          },
          onPanUpdate: (details) {
            _updateDraggedLetter(details.globalPosition);
            widget.onPanUpdate(details);
          },
          onPanEnd: (details) {
            setState(() {
              _draggedLetter = null;
              _draggedOffset = null;
            });
            _overlayController.hide();
            widget.onPanEnd(details);
          },
          onLongPressStart: (details) {
            _updateDraggedLetter(details.globalPosition);
            _overlayController.show();
            widget.onLongPressStart?.call(details);
          },
          onLongPressMoveUpdate: (details) {
            _updateDraggedLetter(details.globalPosition);
            widget.onLongPressMoveUpdate?.call(details);
          },
          onLongPressEnd: (details) {
            setState(() {
              _draggedLetter = null;
              _draggedOffset = null;
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
              padding: componentTokens.verticalPadding,
              physics: const ClampingScrollPhysics(),
              itemCount: widget.letters.length,
              itemExtent: componentTokens.itemExtent,
              itemBuilder: (context, index) {
                final letter = widget.letters[index];
                final isSelected = letter == widget.selectedLetter;
                final wasSelected = letter == _lastSelectedLetter;

                // Only create new widget if selection state changed for this item
                // Otherwise reuse cached widget
                if (isSelected != wasSelected ||
                    !_itemCache.containsKey(letter)) {
                  _itemCache[letter] = _LetterItem(
                    key: ValueKey(letter),
                    letter: letter,
                    isSelected: isSelected,
                    onTap: widget.onLetterSelected,
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
    required this.onTap,
    required this.size,
    required this.selectedIndicatorSize,
    required this.fontSize,
    required this.primaryColor,
    required this.unselectedColor,
  });

  final String letter;
  final bool isSelected;
  final ValueChanged<String> onTap;
  final double size;
  final double selectedIndicatorSize;
  final double fontSize;
  final Color primaryColor;
  final Color unselectedColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: () => onTap(letter),
        borderRadius: BorderRadius.circular(size),
        child: SizedBox(
          height: size,
          width: size,
          child: isSelected
              ? Container(
                  width: selectedIndicatorSize,
                  height: selectedIndicatorSize,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: .circle,
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: .bold,
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
                      fontWeight: .w500,
                      color: unselectedColor,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
