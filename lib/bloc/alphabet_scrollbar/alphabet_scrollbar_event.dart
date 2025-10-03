part of 'alphabet_scrollbar_bloc.dart';

abstract class AlphabetScrollbarEvent extends Equatable {
  const AlphabetScrollbarEvent();

  @override
  List<Object?> get props => [];
}

class SelectLetter extends AlphabetScrollbarEvent {
  final String letter;

  const SelectLetter(this.letter);

  @override
  List<Object?> get props => [letter];
}

class ClearSelection extends AlphabetScrollbarEvent {
  const ClearSelection();
}

class StartDragging extends AlphabetScrollbarEvent {
  const StartDragging();
}

class UpdateDragLetter extends AlphabetScrollbarEvent {
  final String letter;

  const UpdateDragLetter(this.letter);

  @override
  List<Object?> get props => [letter];
}

class EndDragging extends AlphabetScrollbarEvent {
  const EndDragging();
}
