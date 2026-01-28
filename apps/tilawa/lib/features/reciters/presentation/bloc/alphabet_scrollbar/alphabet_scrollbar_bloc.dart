import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

part 'alphabet_scrollbar_bloc.freezed.dart';
part 'alphabet_scrollbar_event.dart';
part 'alphabet_scrollbar_state.dart';

@injectable
class AlphabetScrollbarBloc
    extends Bloc<AlphabetScrollbarEvent, AlphabetScrollbarState> {
  AlphabetScrollbarBloc() : super(const AlphabetScrollbarState()) {
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
    emit(state.copyWith(selectedLetter: event.letter));
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<AlphabetScrollbarState> emit,
  ) {
    emit(state.copyWith(selectedLetter: null));
  }

  void _onStartDragging(
    StartDragging event,
    Emitter<AlphabetScrollbarState> emit,
  ) {
    emit(state.copyWith(isDragging: true));
  }

  void _onUpdateDragLetter(
    UpdateDragLetter event,
    Emitter<AlphabetScrollbarState> emit,
  ) {
    emit(state.copyWith(selectedLetter: event.letter));
  }

  void _onEndDragging(EndDragging event, Emitter<AlphabetScrollbarState> emit) {
    emit(state.copyWith(isDragging: false));
  }
}
