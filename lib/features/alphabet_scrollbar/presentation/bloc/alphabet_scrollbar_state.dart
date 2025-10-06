part of 'alphabet_scrollbar_bloc.dart';

abstract class AlphabetScrollbarState extends Equatable {
  const AlphabetScrollbarState();

  @override
  List<Object?> get props => [];
}

class AlphabetScrollbarInitial extends AlphabetScrollbarState {
  const AlphabetScrollbarInitial();
}

class AlphabetScrollbarLoaded extends AlphabetScrollbarState {
  final String? selectedLetter;
  final bool isDragging;

  const AlphabetScrollbarLoaded({this.selectedLetter, this.isDragging = false});

  @override
  List<Object?> get props => [selectedLetter, isDragging];

  AlphabetScrollbarLoaded copyWith({String? selectedLetter, bool? isDragging}) {
    return AlphabetScrollbarLoaded(
      selectedLetter: selectedLetter ?? this.selectedLetter,
      isDragging: isDragging ?? this.isDragging,
    );
  }
}
