import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/alphabet_scrollbar/presentation/bloc/alphabet_scrollbar_bloc.dart';
import '../models/reciter_model.dart';

class ArabicAlphabetScrollbar extends StatelessWidget {
  // Function to get letter from item

  const ArabicAlphabetScrollbar({
    super.key,
    required this.letters,
    required this.onLetterSelected,
    required this.scrollController,
    required this.items,
    required this.getItemLetter,
  });
  final List<String> letters;
  final Function(String letter) onLetterSelected;
  final ScrollController scrollController;
  final List<dynamic> items; // List of items to search through
  final String Function(Reciter item) getItemLetter;

  void _onLetterTap(String letter, BuildContext context) {
    context.read<AlphabetScrollbarBloc>().add(SelectLetter(letter));

    // Find the first item that starts with this letter
    final int index = items.indexWhere((item) {
      final String itemLetter = getItemLetter(item);
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

  void clearSelection(BuildContext context) {
    context.read<AlphabetScrollbarBloc>().add(const ClearSelection());
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
    return BlocBuilder<AlphabetScrollbarBloc, AlphabetScrollbarState>(
      builder: (context, state) {
        final String? selectedLetter = state.selectedLetter;

        return Container(
          width: 40,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: GestureDetector(
            onPanStart: (details) => _onPanStart(details, context),
            onPanUpdate: (details) => _onPanUpdate(details, context),
            onPanEnd: (details) => _onPanEnd(details, context),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: letters.map((letter) {
                  final isSelected = selectedLetter == letter;
                  return GestureDetector(
                    onTap: () => _onLetterTap(letter, context),
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Helper class to create alphabet scrollbar for reciters
class ReciterAlphabetScrollbar extends StatelessWidget {
  const ReciterAlphabetScrollbar({
    super.key,
    required this.reciters,
    required this.scrollController,
    required this.onLetterSelected,
  });
  final List<Reciter> reciters;
  final ScrollController scrollController;
  final Function(String letter) onLetterSelected;

  void clearSelection(BuildContext context) {
    context.read<AlphabetScrollbarBloc>().add(const ClearSelection());
  }

  @override
  Widget build(BuildContext context) {
    // Get unique letters from reciters, sorted
    final List<String> letters =
        reciters.map((reciter) => reciter.letter).toSet().toList()..sort();

    return ArabicAlphabetScrollbar(
      letters: letters,
      onLetterSelected: onLetterSelected,
      scrollController: scrollController,
      items: reciters,
      getItemLetter: (dynamic item) {
        final reciter = item as Reciter;
        return reciter.letter;
      },
    );
  }
}
