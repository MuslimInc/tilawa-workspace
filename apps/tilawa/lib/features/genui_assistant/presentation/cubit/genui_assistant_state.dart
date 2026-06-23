import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/genui_document.dart';

/// State for the AI-generated assistant surface.
sealed class GenUiAssistantState {
  const GenUiAssistantState();
}

final class GenUiAssistantInitial extends GenUiAssistantState {
  const GenUiAssistantInitial();
}

final class GenUiAssistantLoading extends GenUiAssistantState {
  const GenUiAssistantLoading();
}

/// A validated document is ready to render.
final class GenUiAssistantReady extends GenUiAssistantState {
  const GenUiAssistantReady(this.document);

  final GenUiDocument document;
}

/// The document could not be produced or validated. The UI shows a safe
/// fallback; it never surfaces a stack trace or partial AI output.
final class GenUiAssistantFallback extends GenUiAssistantState {
  const GenUiAssistantFallback(this.failure);

  final Failure failure;
}
