/// Abstraction for handling navigation when a download notification is tapped.
///
/// Implemented in the presentation layer where routing is available.
abstract class DownloadNotificationNavigator {
  /// Navigate to the reciter identified by [reciterId] or [reciterName].
  Future<void> navigateToReciter({
    String? reciterId,
    String? reciterName,
  });
}
