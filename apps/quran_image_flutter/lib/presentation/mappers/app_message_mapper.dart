import '../../domain/domain.dart';
import '../../l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// AppMessage → localized String
// ---------------------------------------------------------------------------

/// Maps every [AppMessage] variant to the corresponding localized string
/// from [AppLocalizations] using exhaustive pattern matching.
extension AppMessageL10n on AppMessage {
  String localize(AppLocalizations l10n) => switch (this) {
    // Cache lifecycle
    PreparingQuranMessage() => l10n.preparingQuran,
    QuranReadyMessage() => l10n.quranReady,
    CachePreparationFailedMessage() => l10n.somethingWentWrong,

    // Errors
    NetworkErrorMessage() => l10n.networkError,
    UnexpectedErrorMessage() => l10n.somethingWentWrong,
    NavigationInitFailedMessage() => l10n.somethingWentWrong,

    // UI labels
    AppTitleMessage() => l10n.appTitle,
    RetryMessage() => l10n.retry,
    PageIndicatorMessage(:final current, :final total) => l10n.pageIndicator(
      current,
      total,
    ),
  };
}

// ---------------------------------------------------------------------------
// QuranImageCachePhase → AppMessage
// ---------------------------------------------------------------------------

/// All progress phases map to the same user-friendly [PreparingQuranMessage],
/// hiding implementation details (downloading, extracting, etc.) from the user.
extension QuranImageCachePhaseMessage on QuranImageCachePhase {
  AppMessage toAppMessage() => switch (this) {
    QuranImageCachePhase.checking => const PreparingQuranMessage(),
    QuranImageCachePhase.downloadingImages => const PreparingQuranMessage(),
    QuranImageCachePhase.downloadingHeader => const PreparingQuranMessage(),
    QuranImageCachePhase.extracting => const PreparingQuranMessage(),
    QuranImageCachePhase.ready => const QuranReadyMessage(),
    QuranImageCachePhase.failed => const CachePreparationFailedMessage(),
  };
}

// ---------------------------------------------------------------------------
// Raw error String → AppMessage
// ---------------------------------------------------------------------------

/// Classifies a raw exception/error string into the appropriate
/// user-facing [AppMessage] for display.
extension RawErrorAppMessageMapper on String {
  AppMessage toAppMessage() {
    if (contains('SocketException') ||
        contains('Failed host lookup') ||
        contains('No address associated with hostname') ||
        contains('Connection refused')) {
      return const NetworkErrorMessage();
    }
    return const UnexpectedErrorMessage();
  }
}
