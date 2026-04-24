/// Type-safe, locale-independent representation of every user-facing message
/// in the Quran Image app.
///
/// Each subtype carries only the data the message needs (if any).
/// Localization is performed at the presentation layer via the
/// [AppMessageL10n] extension in `app_message_mapper.dart`.
sealed class AppMessage {
  const AppMessage();
}

// ---------------------------------------------------------------------------
// Cache lifecycle
// ---------------------------------------------------------------------------

final class PreparingQuranMessage extends AppMessage {
  const PreparingQuranMessage();
}

final class QuranReadyMessage extends AppMessage {
  const QuranReadyMessage();
}

final class CachePreparationFailedMessage extends AppMessage {
  const CachePreparationFailedMessage();
}

// ---------------------------------------------------------------------------
// Errors
// ---------------------------------------------------------------------------

final class NetworkErrorMessage extends AppMessage {
  const NetworkErrorMessage();
}

final class UnexpectedErrorMessage extends AppMessage {
  const UnexpectedErrorMessage();
}

final class NavigationInitFailedMessage extends AppMessage {
  const NavigationInitFailedMessage();
}

// ---------------------------------------------------------------------------
// UI labels
// ---------------------------------------------------------------------------

final class AppTitleMessage extends AppMessage {
  const AppTitleMessage();
}

final class RetryMessage extends AppMessage {
  const RetryMessage();
}

final class PageIndicatorMessage extends AppMessage {
  const PageIndicatorMessage({required this.current, required this.total});

  final String current;
  final String total;
}

final class PageNumberMessage extends AppMessage {
  const PageNumberMessage(this.number);
  final int number;
}

final class JuzMessage extends AppMessage {
  const JuzMessage(this.number);
  final int number;
}

final class HizbMessage extends AppMessage {
  const HizbMessage(this.number);
  final int number;
}
