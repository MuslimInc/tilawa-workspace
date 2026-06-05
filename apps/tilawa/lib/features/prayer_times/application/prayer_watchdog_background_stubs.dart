import 'package:tilawa/core/navigation/notification_destination.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/features/prayer_times/data/datasources/location_datasource.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:tilawa_core/services/analytics_service.dart';

/// Location source for the background watchdog (no GPS in isolate).
class PrayerWatchdogLocationDataSource implements LocationDataSource {
  const PrayerWatchdogLocationDataSource();

  @override
  Future<LocationResult> getCurrentLocation({bool forceRefresh = false}) async {
    return LocationResult.error('Location lookup is disabled in watchdog');
  }

  @override
  Future<String?> getCountryCode(double latitude, double longitude) async {
    return null;
  }

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<bool> isLocationServiceEnabled() async => false;

  @override
  Future<bool> requestPermission({bool allowOpenSettings = false}) async =>
      false;
}

/// No routing from the background isolate.
class PrayerWatchdogNavigationService implements NavigationService {
  const PrayerWatchdogNavigationService();

  @override
  String? getCurrentLocation() => null;

  @override
  void navigateToNotification(String location, {Object? extra}) {}

  @override
  void routeToDestination(NotificationDestination destination) {}

  @override
  Future<void> push(String location, {Object? extra}) async {}
}

/// Analytics disabled in the background isolate.
class PrayerWatchdogAnalyticsService implements AnalyticsService {
  const PrayerWatchdogAnalyticsService();

  @override
  Future<void> logAthkarNotificationOpen(
    int categoryId,
    String categoryName,
  ) async {}

  @override
  Future<void> logAthkarReadStart(
    int categoryId,
    String categoryName, {
    required String source,
  }) async {}

  @override
  Future<void> logAudioPause(String audioId) async {}

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
  }) async {}

  @override
  Future<void> logAudioSeek(String audioId, int position) async {}

  @override
  Future<void> logAudioStop(String audioId) async {}

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> logFavorite(String itemId, {String? itemType}) async {}

  @override
  Future<void> logLogin({String? loginMethod}) async {}

  @override
  Future<void> logPurchase(
    String transactionId, {
    double? value,
    String? currency,
    String? itemId,
  }) async {}

  @override
  Future<void> logRating(
    int rating, {
    String? itemId,
    String? itemType,
  }) async {}

  @override
  Future<void> logScreenView(String screenName, {String? screenClass}) async {}

  @override
  Future<void> logSearch(String searchTerm, {int? resultCount}) async {}

  @override
  Future<void> logShare(String contentType, {String? itemId}) async {}

  @override
  Future<void> logSignUp({String? signUpMethod}) async {}

  @override
  Future<void> logSubscriptionCancel(
    String subscriptionId, {
    String? planId,
  }) async {}

  @override
  Future<void> logSubscriptionStart(
    String subscriptionId, {
    String? planId,
    double? value,
    String? currency,
  }) async {}

  @override
  Future<void> resetAnalyticsData() async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}
}
