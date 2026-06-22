/// Fixed, renderer-owned copy that the AI can never author.
///
/// The disclosure and fallback strings are defined here (not supplied by the
/// model) so they cannot be removed or reworded by a payload. They are kept as
/// constants for the MVP; the follow-up wiring task moves them to `context.l10n`
/// (`GenUiAssistantStrings` ⇄ `.arb` keys) without changing any call site shape.
abstract final class GenUiStrings {
  const GenUiStrings._();

  /// Standing disclosure shown above every AI-generated surface.
  static const String aiDisclosure =
      'AI-assisted suggestion · not a religious ruling';

  /// Shown in place of a component the client cannot render.
  static const String unknownComponent = 'This part could not be shown';

  /// Shown when the whole document fails validation.
  static const String surfaceUnavailable =
      'The assistant could not prepare this view';
}
