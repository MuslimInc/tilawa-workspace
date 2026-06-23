import '../../domain/entities/genui_intent.dart';
import '../../domain/entities/genui_node.dart';
import 'genui_action_resolver.dart';

/// Performs a single allowlisted intent. Implementations bridge to GoRouter and
/// the relevant use-cases (Quran reader, today's wird, athkar, reminders,
/// plans). Kept abstract so the renderer/dispatcher stay testable without
/// navigation.
abstract interface class GenUiIntentExecutor {
  void execute(GenUiIntent intent);
}

/// Resolves a node's action and either executes the typed intent or routes the
/// rejection to [onRejected] (telemetry + optional non-blocking notice).
///
/// This is the only place a node turns into behaviour, and it can only ever
/// invoke [GenUiIntentExecutor.execute] with one of the five typed intents.
class GenUiActionDispatcher {
  const GenUiActionDispatcher({
    required this._executor,
    this._resolver = const GenUiActionResolver(),
    this._onRejected,
  });

  final GenUiIntentExecutor _executor;
  final GenUiActionResolver _resolver;
  final void Function(GenUiActionRejected rejection)? _onRejected;

  /// Returns the resolution so callers/tests can assert what happened.
  GenUiActionResolution dispatch(GenUiNode node) {
    final GenUiActionResolution resolution = _resolver.resolve(node);
    switch (resolution) {
      case GenUiActionAccepted(:final GenUiIntent intent):
        _executor.execute(intent);
      case GenUiActionRejected():
        _onRejected?.call(resolution);
    }
    return resolution;
  }
}
