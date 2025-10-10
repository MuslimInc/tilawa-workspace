import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'alphabet_scrollbar_event.dart';
part 'alphabet_scrollbar_state.dart';

@injectable
class AlphabetScrollbarBloc
    extends Bloc<AlphabetScrollbarEvent, AlphabetScrollbarState> {
  AlphabetScrollbarBloc() : super(const AlphabetScrollbarInitial()) {
    on<SelectLetter>(_onSelectLetter);
    on<ClearSelection>(_onClearSelection);
    on<StartDragging>(_onStartDragging);
    on<UpdateDragLetter>(_onUpdateDragLetter);
    on<EndDragging>(_onEndDragging);
  }

  void _onSelectLetter(
    SelectLetter event,
    Emitter<AlphabetScrollbarState> emit,
  ) {
    if (state is AlphabetScrollbarLoaded) {
      final currentState = state as AlphabetScrollbarLoaded;
      emit(currentState.copyWith(selectedLetter: event.letter));
    } else {
      emit(AlphabetScrollbarLoaded(selectedLetter: event.letter));
    }
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<AlphabetScrollbarState> emit,
  ) {
    if (state is AlphabetScrollbarLoaded) {
      final currentState = state as AlphabetScrollbarLoaded;
      emit(currentState.copyWith(selectedLetter: null));
    }
  }

  void _onStartDragging(
    StartDragging event,
    Emitter<AlphabetScrollbarState> emit,
  ) {
    if (state is AlphabetScrollbarLoaded) {
      final currentState = state as AlphabetScrollbarLoaded;
      emit(currentState.copyWith(isDragging: true));
    } else {
      emit(const AlphabetScrollbarLoaded(isDragging: true));
    }
  }

  void _onUpdateDragLetter(
    UpdateDragLetter event,
    Emitter<AlphabetScrollbarState> emit,
  ) {
    if (state is AlphabetScrollbarLoaded) {
      final currentState = state as AlphabetScrollbarLoaded;
      emit(currentState.copyWith(selectedLetter: event.letter));
    }
  }

  void _onEndDragging(EndDragging event, Emitter<AlphabetScrollbarState> emit) {
    if (state is AlphabetScrollbarLoaded) {
      final currentState = state as AlphabetScrollbarLoaded;
      emit(currentState.copyWith(isDragging: false));
    }
  }
}
