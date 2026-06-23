import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/genui_document.dart';

/// Request for an AI-authored UI surface.
///
/// [trustedContext] carries app-resolved facts the model may *reference* (e.g.
/// the user's current plan id, today's wird range). It is never religious
/// content the model should author — it is grounding data so the model arranges
/// trusted material instead of inventing it.
class GenUiSurfaceRequest {
  const GenUiSurfaceRequest({
    required this.surface,
    this.userPrompt,
    this.trustedContext = const <String, Object?>{},
  });

  /// Logical surface to build, e.g. `smartQuranPlan`.
  final String surface;

  /// Optional free-text user ask. Constrained by the system prompt.
  final String? userPrompt;

  final Map<String, Object?> trustedContext;
}

/// Boundary between the assistant UI and the AI transport.
///
/// Implementations fetch a raw document from the transport and validate it
/// through the parser, returning a `GenUiDocument` or a `GenUiFailure`. No
/// model or network ever leaks above this interface, which keeps every layer
/// above it deterministic and unit-testable with canned payloads.
abstract interface class GenUiRepository {
  ResultFuture<GenUiDocument> requestSurface(GenUiSurfaceRequest request);
}
