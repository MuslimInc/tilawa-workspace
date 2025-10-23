import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';

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
  });
  Future<void> logAudioPause(String audioId);
  Future<void> logAudioStop(String audioId);
  Future<void> logAudioSeek(String audioId, int position);

  /// Log download events
  Future<void> logDownloadStart(
    String downloadId, {
    String? fileName,
    int? fileSize,
  });
  Future<void> logDownloadComplete(
    String downloadId, {
    String? fileName,
    int? fileSize,
  });
  Future<void> logDownloadCancel(String downloadId, {String? fileName});

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

/// Firebase Analytics implementation
@Singleton(as: AnalyticsService)
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      // Log error but don't throw to avoid breaking app functionality
      print('Analytics error: $e');
    }
  }

  @override
  Future<void> logLogin({String? loginMethod}) async {
    await logEvent(
      'login',
      parameters: {if (loginMethod != null) 'method': loginMethod},
    );
  }

  @override
  Future<void> logSignUp({String? signUpMethod}) async {
    await logEvent(
      'sign_up',
      parameters: {if (signUpMethod != null) 'method': signUpMethod},
    );
  }

  @override
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    await logEvent(
      'screen_view',
      parameters: {
        'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
      },
    );
  }

  @override
  Future<void> logAudioPlay(
    String audioId, {
    String? audioName,
    String? artist,
  }) async {
    await logEvent(
      'audio_play',
      parameters: {
        'audio_id': audioId,
        if (audioName != null) 'audio_name': audioName,
        if (artist != null) 'artist': artist,
      },
    );
  }

  @override
  Future<void> logAudioPause(String audioId) async {
    await logEvent('audio_pause', parameters: {'audio_id': audioId});
  }

  @override
  Future<void> logAudioStop(String audioId) async {
    await logEvent('audio_stop', parameters: {'audio_id': audioId});
  }

  @override
  Future<void> logAudioSeek(String audioId, int position) async {
    await logEvent(
      'audio_seek',
      parameters: {'audio_id': audioId, 'position': position},
    );
  }

  @override
  Future<void> logDownloadStart(
    String downloadId, {
    String? fileName,
    int? fileSize,
  }) async {
    await logEvent(
      'download_start',
      parameters: {
        'download_id': downloadId,
        if (fileName != null) 'file_name': fileName,
        if (fileSize != null) 'file_size': fileSize,
      },
    );
  }

  @override
  Future<void> logDownloadComplete(
    String downloadId, {
    String? fileName,
    int? fileSize,
  }) async {
    await logEvent(
      'download_complete',
      parameters: {
        'download_id': downloadId,
        if (fileName != null) 'file_name': fileName,
        if (fileSize != null) 'file_size': fileSize,
      },
    );
  }

  @override
  Future<void> logDownloadCancel(String downloadId, {String? fileName}) async {
    await logEvent(
      'download_cancel',
      parameters: {
        'download_id': downloadId,
        if (fileName != null) 'file_name': fileName,
      },
    );
  }

  @override
  Future<void> logPurchase(
    String transactionId, {
    double? value,
    String? currency,
    String? itemId,
  }) async {
    await logEvent(
      'purchase',
      parameters: {
        'transaction_id': transactionId,
        if (value != null) 'value': value,
        if (currency != null) 'currency': currency,
        if (itemId != null) 'item_id': itemId,
      },
    );
  }

  @override
  Future<void> logSubscriptionStart(
    String subscriptionId, {
    String? planId,
    double? value,
    String? currency,
  }) async {
    await logEvent(
      'subscription_start',
      parameters: {
        'subscription_id': subscriptionId,
        if (planId != null) 'plan_id': planId,
        if (value != null) 'value': value,
        if (currency != null) 'currency': currency,
      },
    );
  }

  @override
  Future<void> logSubscriptionCancel(
    String subscriptionId, {
    String? planId,
  }) async {
    await logEvent(
      'subscription_cancel',
      parameters: {
        'subscription_id': subscriptionId,
        if (planId != null) 'plan_id': planId,
      },
    );
  }

  @override
  Future<void> logSearch(String searchTerm, {int? resultCount}) async {
    await logEvent(
      'search',
      parameters: {
        'search_term': searchTerm,
        if (resultCount != null) 'result_count': resultCount,
      },
    );
  }

  @override
  Future<void> logShare(String contentType, {String? itemId}) async {
    await logEvent(
      'share',
      parameters: {
        'content_type': contentType,
        if (itemId != null) 'item_id': itemId,
      },
    );
  }

  @override
  Future<void> logFavorite(String itemId, {String? itemType}) async {
    await logEvent(
      'favorite',
      parameters: {
        'item_id': itemId,
        if (itemType != null) 'item_type': itemType,
      },
    );
  }

  @override
  Future<void> logRating(int rating, {String? itemId, String? itemType}) async {
    await logEvent(
      'rating',
      parameters: {
        'rating': rating,
        if (itemId != null) 'item_id': itemId,
        if (itemType != null) 'item_type': itemType,
      },
    );
  }

  @override
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      print('Analytics setUserId error: $e');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      print('Analytics setUserProperty error: $e');
    }
  }

  @override
  Future<void> resetAnalyticsData() async {
    try {
      await _analytics.resetAnalyticsData();
    } catch (e) {
      print('Analytics reset error: $e');
    }
  }
}
