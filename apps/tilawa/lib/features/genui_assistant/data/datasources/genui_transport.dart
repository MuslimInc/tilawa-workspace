import '../../domain/failures/genui_failure.dart';
import '../../domain/repositories/genui_repository.dart';

/// The *only* place an AI model is reachable.
///
/// A transport takes a grounded request and returns a raw document string (or a
/// [GenUiFailure]). Everything downstream — parser, registry, dispatcher,
/// renderer — is deterministic, so swapping a real model for
/// [GenUiFakeTransport] makes the entire pipeline testable without a network or
/// an API key.
abstract interface class GenUiTransport {
  GenUiResult<String> requestDocument(GenUiSurfaceRequest request);
}
