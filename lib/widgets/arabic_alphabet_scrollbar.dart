import 'package:flutter/material.dart';
import 'package:muzakri/reciter_model.dart';

class ArabicAlphabetScrollbar extends StatefulWidget {
  final List<String> letters;
  final Function(String letter) onLetterSelected;
  final ScrollController scrollController;
  final List<dynamic> items; // List of items to search through
  final String Function(dynamic item)
  getItemLetter; // Function to get letter from item

  const ArabicAlphabetScrollbar({
    super.key,
    required this.letters,
    required this.onLetterSelected,
    required this.scrollController,
    required this.items,
    required this.getItemLetter,
  });

  @override
  State<ArabicAlphabetScrollbar> createState() =>
      _ArabicAlphabetScrollbarState();
}

class _ArabicAlphabetScrollbarState extends State<ArabicAlphabetScrollbar> {
  String? _selectedLetter;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _selectedLetter = widget.letters.isNotEmpty ? widget.letters.first : null;
  }

  void _onLetterTap(String letter) {
    setState(() {
      _selectedLetter = letter;
    });

    // Find the first item that starts with this letter
    final index = widget.items.indexWhere((item) {
      final itemLetter = widget.getItemLetter(item);
      return itemLetter == letter;
    });

    if (index != -1) {
      // Scroll to the item
      widget.scrollController.animateTo(
        index * 72.0, // Approximate height of each item (Card + margin)
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    widget.onLetterSelected(letter);
  }

  void clearSelection() {
    setState(() {
      _selectedLetter = null;
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final letterHeight = box.size.height / widget.letters.length;
    final letterIndex = (localPosition.dy / letterHeight)
        .clamp(0, widget.letters.length - 1)
        .floor();

    if (letterIndex >= 0 && letterIndex < widget.letters.length) {
      final letter = widget.letters[letterIndex];
      if (_selectedLetter != letter) {
        setState(() {
          _selectedLetter = letter;
        });
        _onLetterTap(letter);
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: widget.letters.map((letter) {
              final isSelected = _selectedLetter == letter;
              return GestureDetector(
                onTap: () => _onLetterTap(letter),
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
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
  }
}

// Helper class to create alphabet scrollbar for reciters
class ReciterAlphabetScrollbar extends StatefulWidget {
  final List<Reciter> reciters;
  final ScrollController scrollController;
  final Function(String letter) onLetterSelected;

  const ReciterAlphabetScrollbar({
    super.key,
    required this.reciters,
    required this.scrollController,
    required this.onLetterSelected,
  });

  @override
  State<ReciterAlphabetScrollbar> createState() =>
      ReciterAlphabetScrollbarState();
}

class ReciterAlphabetScrollbarState extends State<ReciterAlphabetScrollbar> {
  final GlobalKey<_ArabicAlphabetScrollbarState> _scrollbarKey =
      GlobalKey<_ArabicAlphabetScrollbarState>();

  void clearSelection() {
    _scrollbarKey.currentState?.clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    // Get unique letters from reciters, sorted
    final letters =
        widget.reciters.map((reciter) => reciter.letter).toSet().toList()
          ..sort();

    return ArabicAlphabetScrollbar(
      key: _scrollbarKey,
      letters: letters,
      onLetterSelected: widget.onLetterSelected,
      scrollController: widget.scrollController,
      items: widget.reciters,
      getItemLetter: (reciter) => reciter.letter,
    );
  }
}
