/// The single schema version this client understands.
///
/// The AI transport is instructed to emit documents tagged with exactly this
/// version. Any document whose `schemaVersion` does not match is rejected
/// wholesale (see `GenUiParser`) and the UI falls back safely. Bumping this
/// constant is therefore both a forward-compat lever and a kill-switch: ship a
/// new client, and every in-flight document authored against the old contract
/// stops rendering without touching the rest of the app.
abstract final class GenUiSchema {
  const GenUiSchema._();

  static const String version = '1';
}
