import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tilawa_core/entities/reciter_entity.dart';
import '../../features/reciters/presentation/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';

class ArabicAlphabetScrollbar extends StatelessWidget {
  const ArabicAlphabetScrollbar({
    super.key,
    required this.letters,
    required this.onLetterSelected,
    required this.scrollController,
    required this.items,
    required this.getItemLetter,
  });
  final List<String> letters;
  final Function(String? letter) onLetterSelected;
  final ScrollController scrollController;
  final List<dynamic> items; // List of items to search through
  final String Function(ReciterEntity item) getItemLetter;

  void _onLetterTap(String letter, BuildContext context) {
    final AlphabetScrollbarState currentState = context
        .read<AlphabetScrollbarBloc>()
        .state;

    if (currentState.selectedLetter == letter) {
      // Toggle off
      context.read<AlphabetScrollbarBloc>().add(const ClearSelection());
      onLetterSelected(null);
      return;
    }

    context.read<AlphabetScrollbarBloc>().add(SelectLetter(letter));

    // Find the first item that starts with this letter
    final int index = items.indexWhere((item) {
      final String itemLetter = getItemLetter(item as ReciterEntity);
      return itemLetter == letter;
    });

    if (index != -1) {
      // Scroll to the top of the list when a letter is selected
      scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    onLetterSelected(letter);
  }

  void _onPanStart(DragStartDetails details, BuildContext context) {
    context.read<AlphabetScrollbarBloc>().add(const StartDragging());
  }

  void _onPanUpdate(DragUpdateDetails details, BuildContext context) {
    final AlphabetScrollbarState currentState = context
        .read<AlphabetScrollbarBloc>()
        .state;
    if (!currentState.isDragging) {
      return;
    }

    final box = context.findRenderObject()! as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    final double letterHeight = box.size.height / letters.length;
    final int letterIndex = (localPosition.dy / letterHeight)
        .clamp(0, letters.length - 1)
        .floor();

    if (letterIndex >= 0 && letterIndex < letters.length) {
      final String letter = letters[letterIndex];
      if (currentState.selectedLetter != letter) {
        context.read<AlphabetScrollbarBloc>().add(UpdateDragLetter(letter));
        _onLetterTap(letter, context);
      }
    }
  }

  void _onPanEnd(DragEndDetails details, BuildContext context) {
    context.read<AlphabetScrollbarBloc>().add(const EndDragging());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return BlocBuilder<AlphabetScrollbarBloc, AlphabetScrollbarState>(
      builder: (context, state) {
        final String? selectedLetter = state.selectedLetter;

        return RepaintBoundary(
          child: Container(
            width: 36,
            margin: EdgeInsets.fromLTRB(4, 8, 12, 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: GestureDetector(
              onPanStart: (details) => _onPanStart(details, context),
              onPanUpdate: (details) => _onPanUpdate(details, context),
              onPanEnd: (details) => _onPanEnd(details, context),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: letters.map((letter) {
                      final isSelected = selectedLetter == letter;
                      return GestureDetector(
                        onTap: () => _onLetterTap(letter, context),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 30,
                          width: 30,
                          margin: EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.primaryColor
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
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
                                    : theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
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
      },
    );
  }
}

class ReciterAlphabetScrollbar extends StatelessWidget {
  const ReciterAlphabetScrollbar({
    super.key,
    required this.reciters,
    required this.scrollController,
    required this.onLetterSelected,
  });
  final List<ReciterEntity> reciters;
  final ScrollController scrollController;
  final Function(String? letter) onLetterSelected;

  @override
  Widget build(BuildContext context) {
    // Get unique letters from reciters, sorted
    final List<String> letters =
        reciters.map((reciter) => reciter.letter).toSet().toList()..sort();

    if (letters.isEmpty) {
      return const SizedBox.shrink();
    }

    return ArabicAlphabetScrollbar(
      letters: letters,
      onLetterSelected: onLetterSelected,
      scrollController: scrollController,
      items: reciters,
      getItemLetter: (item) => item.letter,
    );
  }
}
