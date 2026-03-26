import 'package:flutter/material.dart';
import '../foundation/design_tokens.dart';

class ArabicAlphabetScrollbar extends StatelessWidget {
  const ArabicAlphabetScrollbar({
    super.key,
    required this.letters,
    required this.onLetterSelected,
    required this.selectedLetter,
    required this.onPanUpdate,
    required this.onPanStart,
    required this.onPanEnd,
  });

  final List<String> letters;
  final Function(String letter) onLetterSelected;
  final String? selectedLetter;
  final Function(DragUpdateDetails details) onPanUpdate;
  final Function(DragStartDetails details) onPanStart;
  final Function(DragEndDetails details) onPanEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return RepaintBoundary(
      child: Container(
        width: tokens.spaceExtraLarge * 1.5,
        margin: EdgeInsets.fromLTRB(
          tokens.spaceExtraSmall,
          tokens.spaceSmall,
          tokens.spaceMedium,
          tokens.spaceSmall,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(
            alpha: tokens.opacityGlass,
          ),
          borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: tokens.opacitySubtle / 3),
              blurRadius: tokens.radiusSmall,
              offset: tokens.shadowOffsetSmall,
            ),
          ],
        ),
        child: GestureDetector(
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spaceMedium),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: letters.map((letter) {
                  final isSelected = selectedLetter == letter;
                  return GestureDetector(
                    onTap: () => onLetterSelected(letter),
                    child: AnimatedContainer(
                      duration: tokens.durationFast,
                      height: tokens.spaceExtraLarge * 1.25,
                      width: tokens.spaceExtraLarge * 1.25,
                      margin: EdgeInsets.symmetric(
                        vertical: tokens.spaceExtraSmall / 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primaryColor
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(
                                    alpha: tokens.opacityMedium,
                                  ),
                                  blurRadius: tokens.radiusSmall,
                                  offset: tokens.shadowOffsetSmall,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant.withValues(
                                    alpha: tokens.opacityEmphasis,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
