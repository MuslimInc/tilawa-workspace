part of 'alphabet_scrollbar_bloc.dart';

@freezed
abstract class AlphabetScrollbarState with _$AlphabetScrollbarState {
  const factory AlphabetScrollbarState({
    String? selectedLetter,
    @Default(false) bool isDragging,
  }) = _AlphabetScrollbarState;
}
