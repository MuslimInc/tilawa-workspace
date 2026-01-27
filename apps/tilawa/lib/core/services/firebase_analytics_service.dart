import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../main.dart';

/// Firebase Analytics implementation
@Singleton(as: AnalyticsService)
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics) {
    if (kDebugMode) {
      _analytics.setAnalyticsCollectionEnabled(false);
    }
  }

  final FirebaseAnalytics _analytics;

  @visibleForTesting
  bool testMode = false;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (kDebugMode && !testMode) {
      return;
    }
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      // Log error but don't throw to avoid breaking app functionality
      logger.d('Analytics error: $e');
    }
  }

  @override
  Future<void> logLogin({String? loginMethod}) async {
    await logEvent(
      AnalyticsEvents.login,
      parameters: _cleanParameters({AnalyticsParams.method: loginMethod}),
    );
  }

  @override
  Future<void> logSignUp({String? signUpMethod}) async {
    await logEvent(
      AnalyticsEvents.signUp,
      parameters: _cleanParameters({AnalyticsParams.method: signUpMethod}),
    );
  }

  @override
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    await logEvent(
      AnalyticsEvents.screenView,
      parameters: _cleanParameters({
        AnalyticsParams.screenName: screenName,
        AnalyticsParams.screenClass: screenClass,
      }),
    );
  }

  @override
  Future<void> logAudioPlay(
    String audioId, {
    String? audioName,
    String? artist,
    String? surahName,
    String? reciterName,
    String? moshafName,
    String? surahId,
    String? reciterId,
  }) async {
    await logEvent(
      AnalyticsEvents.audioPlay,
      parameters: _cleanParameters({
        AnalyticsParams.audioId: audioId,
        AnalyticsParams.audioName: audioName,
        AnalyticsParams.artist: artist,
        AnalyticsParams.surahName: surahName,
        AnalyticsParams.reciterName: reciterName,
        AnalyticsParams.moshafName: moshafName,
        AnalyticsParams.surahId: surahId,
        AnalyticsParams.reciterId: reciterId,
      }),
    );
  }

  @override
  Future<void> logAudioPause(String audioId) async {
    await logEvent(
      AnalyticsEvents.audioPause,
      parameters: {AnalyticsParams.audioId: audioId},
    );
  }

  @override
  Future<void> logAudioStop(String audioId) async {
    await logEvent(
      AnalyticsEvents.audioStop,
      parameters: {AnalyticsParams.audioId: audioId},
    );
  }

  @override
  Future<void> logAudioSeek(String audioId, int position) async {
    await logEvent(
      AnalyticsEvents.audioSeek,
      parameters: {
        AnalyticsParams.audioId: audioId,
        AnalyticsParams.position: position,
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
      AnalyticsEvents.purchase,
      parameters: _cleanParameters({
        AnalyticsParams.transactionId: transactionId,
        AnalyticsParams.value: value,
        AnalyticsParams.currency: currency,
        AnalyticsParams.itemId: itemId,
      }),
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
      AnalyticsEvents.subscriptionStart,
      parameters: _cleanParameters({
        AnalyticsParams.subscriptionId: subscriptionId,
        AnalyticsParams.planId: planId,
        AnalyticsParams.value: value,
        AnalyticsParams.currency: currency,
      }),
    );
  }

  @override
  Future<void> logSubscriptionCancel(
    String subscriptionId, {
    String? planId,
  }) async {
    await logEvent(
      AnalyticsEvents.subscriptionCancel,
      parameters: _cleanParameters({
        AnalyticsParams.subscriptionId: subscriptionId,
        AnalyticsParams.planId: planId,
      }),
    );
  }

  @override
  Future<void> logSearch(String searchTerm, {int? resultCount}) async {
    await logEvent(
      AnalyticsEvents.search,
      parameters: _cleanParameters({
        AnalyticsParams.searchTerm: searchTerm,
        AnalyticsParams.resultCount: resultCount,
      }),
    );
  }

  @override
  Future<void> logShare(String contentType, {String? itemId}) async {
    await logEvent(
      AnalyticsEvents.share,
      parameters: _cleanParameters({
        AnalyticsParams.contentType: contentType,
        AnalyticsParams.itemId: itemId,
      }),
    );
  }

  @override
  Future<void> logFavorite(String itemId, {String? itemType}) async {
    await logEvent(
      AnalyticsEvents.favorite,
      parameters: _cleanParameters({
        AnalyticsParams.itemId: itemId,
        AnalyticsParams.itemType: itemType,
      }),
    );
  }

  @override
  Future<void> logRating(int rating, {String? itemId, String? itemType}) async {
    await logEvent(
      AnalyticsEvents.rating,
      parameters: _cleanParameters({
        AnalyticsParams.ratingValue: rating,
        AnalyticsParams.itemId: itemId,
        AnalyticsParams.itemType: itemType,
      }),
    );
  }

  Map<String, Object> _cleanParameters(Map<String, Object?> parameters) {
    return Map<String, Object>.fromEntries(
      parameters.entries
          .where((entry) => entry.value != null)
          .map((entry) => MapEntry(entry.key, entry.value!)),
    );
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (kDebugMode && !testMode) {
      return;
    }
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      logger.d('Analytics setUserId error: $e');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    if (kDebugMode && !testMode) {
      return;
    }
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      logger.d('Analytics setUserProperty error: $e');
    }
  }

  @override
  Future<void> resetAnalyticsData() async {
    if (kDebugMode && !testMode) {
      return;
    }
    try {
      await _analytics.resetAnalyticsData();
    } catch (e) {
      logger.d('Analytics reset error: $e');
    }
  }
}
