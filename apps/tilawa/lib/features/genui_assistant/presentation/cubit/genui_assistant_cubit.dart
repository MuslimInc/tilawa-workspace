import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/genui_repository.dart';
import 'genui_assistant_state.dart';

/// Drives an AI-generated surface: request a document, validate it, emit either
/// a ready or a safe-fallback state. Any failure becomes a fallback — the cubit
/// never rethrows model/transport errors into the UI.
class GenUiAssistantCubit extends Cubit<GenUiAssistantState> {
  GenUiAssistantCubit({required this._repository})
    : super(const GenUiAssistantInitial());

  final GenUiRepository _repository;

  Future<void> load(GenUiSurfaceRequest request) async {
    emit(const GenUiAssistantLoading());
    final result = await _repository.requestSurface(request);
    result.fold(
      (failure) => emit(GenUiAssistantFallback(failure)),
      (document) => emit(GenUiAssistantReady(document)),
    );
  }
}
