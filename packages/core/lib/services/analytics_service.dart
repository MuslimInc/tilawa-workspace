/// Abstract interface for analytics service
abstract class AnalyticsService {
  /// Log a custom event
  Future<void> logEvent(String name, {Map<String, Object>? parameters});

  /// Log user login event
  Future<void> logLogin({String? loginMethod});

  /// Log user signup event
  Future<void> logSignUp({String? signUpMethod});

  /// Log screen view event
  Future<void> logScreenView(String screenName, {String? screenClass});

  /// Log audio playback events
  Future<void> logAudioPlay(
    String audioId, {
    String? audioName,
    String? artist,
    String? surahName,
    String? reciterName,
    String? moshafName,
    String? surahId,
    String? reciterId,
  });
  Future<void> logAudioPause(String audioId);
  Future<void> logAudioStop(String audioId);
  Future<void> logAudioSeek(String audioId, int position);

  /// Log download events
  Future<void> logDownloadStart(
    String downloadId, {
    String? fileName,
    int? fileSize,
    String? surahId,
    String? reciterName,
  });
  Future<void> logDownloadComplete(
    String downloadId, {
    String? fileName,
    int? fileSize,
    String? surahId,
    String? reciterName,
  });
  Future<void> logDownloadCancel(
    String downloadId, {
    String? fileName,
    String? surahId,
    String? reciterName,
  });

  /// Log premium/subscription events
  Future<void> logPurchase(
    String transactionId, {
    double? value,
    String? currency,
    String? itemId,
  });
  Future<void> logSubscriptionStart(
    String subscriptionId, {
    String? planId,
    double? value,
    String? currency,
  });
  Future<void> logSubscriptionCancel(String subscriptionId, {String? planId});

  /// Log search events
  Future<void> logSearch(String searchTerm, {int? resultCount});

  /// Log user engagement events
  Future<void> logShare(String contentType, {String? itemId});
  Future<void> logFavorite(String itemId, {String? itemType});
  Future<void> logRating(int rating, {String? itemId, String? itemType});

  /// Set user properties
  Future<void> setUserId(String? userId);
  Future<void> setUserProperty(String name, String? value);

  /// Reset analytics data
  Future<void> resetAnalyticsData();
}
