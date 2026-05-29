import 'package:tilawa/router/deep_link_resolver.dart';

/// Resolves notification payload data into a go_router location and optional
/// route extra.
///
/// Kept as a stable façade for existing callers/tests; the real logic now lives
/// in the single [DeepLinkResolver] so route resolution has one source of truth.
class NotificationNavigationResolver {
  NotificationNavigationResolver._();

  static String resolveLocation(Map<String, dynamic> data) =>
      DeepLinkResolver.resolveLocation(data);

  /// Returns route extra when the payload carries enough data to render without
  /// an async loader (e.g. embedded `reciter` JSON).
  static Object? resolveExtra(Map<String, dynamic> data, String location) =>
      DeepLinkResolver.resolveExtra(data, location);

  static Map<String, dynamic>? notificationDataFromPayload(String? payload) =>
      DeepLinkResolver.notificationDataFromPayload(payload);
}
