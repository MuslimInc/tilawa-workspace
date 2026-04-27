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
  });

  final List<String> letters;
  final String? selectedLetter;
  final ValueChanged<String> onLetterSelected;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragStartCallback onPanStart;
  final GestureDragEndCallback onPanEnd;

  @override
  State<ArabicAlphabetScrollbar> createState() =>
      _ArabicAlphabetScrollbarState();
}

class _ArabicAlphabetScrollbarState extends State<ArabicAlphabetScrollbar> {
  String? _lastSelectedLetter;
  final Map<String, Widget> _itemCache = {};

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
      child: GestureDetector(
        behavior: .opaque,
        onPanStart: widget.onPanStart,
        onPanUpdate: widget.onPanUpdate,
        onPanEnd: widget.onPanEnd,
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
    return InkWell(
      onTap: () => onTap(letter),
      borderRadius: BorderRadius.circular(size),
      child: SizedBox(
        height: size,
        width: size,
        child: Center(
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
              : Text(
                  letter,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: .w500,
                    color: unselectedColor,
                  ),
                ),
        ),
      ),
    );
  }
}
