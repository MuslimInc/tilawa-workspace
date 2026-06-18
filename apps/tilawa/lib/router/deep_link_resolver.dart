import 'dart:convert';

import 'package:tilawa/core/navigation/navigation_source.dart';
import 'package:tilawa/core/navigation/notification_destination.dart';
import 'package:tilawa/core/services/tasbeeh_reminder_notification_service.dart';
import 'package:tilawa/features/athkar/domain/constants/tasbeeh_constants.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

/// Single source of truth for turning a notification/deep-link payload into a
/// resolved [NotificationDestination] (location + decoded extra + source).
///
/// This folds together what used to be split across
/// `FCMNotificationHandlerService.resolveLocation` (the canonical `type` switch)
/// and `NotificationNavigationResolver.resolveExtra` (embedded reciter / prayer
/// payload). Service-specific local notifications (Athkar string payloads,
/// prayer Adhan payloads) build their destinations through the typed factories
/// below so that route shapes live in exactly one place.
class DeepLinkResolver {
  const DeepLinkResolver();

  static const String athkarMorningCategoryName = 'أذكار الصباح';
  static const String athkarEveningCategoryName = 'أذكار المساء';
  static const int athkarMorningCategoryId = 1;
  static const int athkarEveningCategoryId = 2;

  /// Prefixes for the plain-string payloads emitted by the athkar local
  /// notifications (e.g. `morning_athkar_20260605`). These are NOT JSON, so
  /// the cold-start path must detect them before attempting [jsonDecode].
  static const String athkarMorningPayloadPrefix = 'morning_athkar_';
  static const String athkarEveningPayloadPrefix = 'evening_athkar_';

  /// Prefix for per-dhikr tasbeeh reminder local notifications.
  static const String tasbeehReminderPayloadPrefix =
      TasbeehConstants.reminderPayloadPrefix;

  // ---------------------------------------------------------------------------
  // Map (FCM / generic deep-link) resolution
  // ---------------------------------------------------------------------------

  /// Resolves a normalized payload map (FCM data or app-link extras) into a
  /// destination. Returns `null` only if nothing meaningful can be derived
  /// (callers fall back to home).
  NotificationDestination resolveFromData(
    Map<String, dynamic> data, {
    NavigationSource source = NavigationSource.notification,
  }) {
    final String location = resolveLocation(data);
    final Object? extra = resolveExtra(data, location);
    return NotificationDestination(
      location: location,
      extra: extra,
      source: source,
    );
  }

  /// Canonical payload `type` → location mapping. Preserves the previous
  /// cross-type fallbacks and inference exactly.
  static String resolveLocation(Map<String, dynamic> payload) {
    final Map<String, dynamic> data = normalizePayloadData(payload);
    final String type = data['type']?.toString() ?? 'home';
    final String? actionData = data['data']?.toString();

    switch (type) {
      case 'reciter':
        final String? reciterId = actionData?.trim().isNotEmpty == true
            ? actionData!.trim()
            : data['reciterId']?.toString();
        if (reciterId != null && reciterId.isNotEmpty) {
          return ReciterDetailsRoute(reciterId: reciterId).location;
        }
        return const HomeRoute().location;
      case 'athkar':
        final int? categoryId = int.tryParse(
          data['categoryId']?.toString() ?? '',
        );
        final String? categoryName = data['categoryName']?.toString();
        if (categoryId != null &&
            categoryName != null &&
            categoryName.trim().isNotEmpty) {
          return AthkarDetailsRoute(
            categoryId: categoryId,
            categoryName: categoryName,
            source: NavigationSource.notification.wireValue,
          ).location;
        }
        return const AthkarCategoriesRoute().location;
      case 'quran':
        final int? surahNumber = int.tryParse(
          actionData?.trim().isNotEmpty == true
              ? actionData!.trim()
              : data['surahNumber']?.toString() ?? '',
        );
        if (surahNumber != null && surahNumber >= 1 && surahNumber <= 114) {
          return QuranReaderRoute(surahNumber: surahNumber).location;
        }
        return const QuranIndexRoute().location;
      case 'settings':
        return const SettingsRoute().location;
      case 'prayer':
        return const PrayerTimesRoute().location;
      case 'tasbeeh':
        final String? dhikrId = data['dhikrId']?.toString();
        if (dhikrId != null && dhikrId.isNotEmpty) {
          return TasbeehRoute(dhikrId: dhikrId).location;
        }
        return const TasbeehRoute().location;
      case 'home':
      default:
        return const HomeRoute().location;
    }
  }

  /// Returns route [extra] when the payload carries enough data to render
  /// without an async loader (embedded reciter JSON, or the prayer payload
  /// string for the status screen).
  static Object? resolveExtra(Map<String, dynamic> data, String location) {
    final String path = Uri.parse(location).path;
    if (path.startsWith('/reciter/')) {
      return _resolveReciterExtra(data);
    }
    if (path == const PrayerNotificationStatusRoute().location) {
      final Object? payload = data['payload'] ?? data['adhanPayload'];
      if (payload is String && payload.isNotEmpty) {
        return payload;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Typed factories for service-specific local notifications
  // ---------------------------------------------------------------------------

  /// Morning Athkar destination (category id 1). Tags [source] so the read is
  /// attributed correctly (previously defaulted to `manual`).
  NotificationDestination athkarMorning({
    NavigationSource source = NavigationSource.notification,
  }) {
    return NotificationDestination(
      location: AthkarDetailsRoute(
        categoryId: athkarMorningCategoryId,
        categoryName: athkarMorningCategoryName,
        source: source.wireValue,
      ).location,
      source: source,
    );
  }

  /// Evening Athkar destination (category id 2).
  NotificationDestination athkarEvening({
    NavigationSource source = NavigationSource.notification,
  }) {
    return NotificationDestination(
      location: AthkarDetailsRoute(
        categoryId: athkarEveningCategoryId,
        categoryName: athkarEveningCategoryName,
        source: source.wireValue,
      ).location,
      source: source,
    );
  }

  /// Saved tasbeeh counting destination for a specific [dhikrId].
  NotificationDestination tasbeehDhikr(
    String dhikrId, {
    NavigationSource source = NavigationSource.notification,
  }) {
    return NotificationDestination(
      location: TasbeehRoute(dhikrId: dhikrId).location,
      source: source,
    );
  }

  /// Prayer notification status destination, carrying the raw adhan [payload]
  /// string as the route extra (unchanged contract for the status screen).
  NotificationDestination prayerStatus(String payload) {
    return NotificationDestination(
      location: const PrayerNotificationStatusRoute().location,
      extra: payload,
      source: NavigationSource.notification,
    );
  }

  // ---------------------------------------------------------------------------
  // Internal helpers (moved verbatim from the previous resolvers)
  // ---------------------------------------------------------------------------

  static ReciterEntity? _resolveReciterExtra(Map<String, dynamic> data) {
    final Object? embedded = data['reciter'] ?? data['reciterEntity'];
    if (embedded is Map) {
      try {
        return ReciterEntity.fromJson(Map<String, dynamic>.from(embedded));
      } catch (_) {
        return null;
      }
    }
    if (embedded is String && embedded.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(embedded);
        if (decoded is Map<String, dynamic>) {
          return ReciterEntity.fromJson(decoded);
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Parses a notification payload string into a normalized data map, or
  /// `null`. Handles both JSON payloads (FCM / generic deep links) and the
  /// plain-string athkar payloads emitted by the local athkar notifications.
  static Map<String, dynamic>? notificationDataFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }
    // Athkar local notifications use plain-string payloads (not JSON), so they
    // must be recognised here; otherwise the cold-start launch path drops them
    // and lands on home instead of the morning/evening athkar screen.
    final Map<String, dynamic>? athkar = _athkarDataFromPayload(payload);
    if (athkar != null) {
      return athkar;
    }
    final Map<String, dynamic>? tasbeeh = _tasbeehDataFromPayload(payload);
    if (tasbeeh != null) {
      return tasbeeh;
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(payload) as Map);
    } catch (_) {
      return null;
    }
  }

  /// Maps a plain-string athkar payload to the normalized `athkar` data map
  /// consumed by [resolveLocation], or `null` when [payload] is not athkar.
  static Map<String, dynamic>? _tasbeehDataFromPayload(String payload) {
    if (!payload.startsWith(TasbeehConstants.reminderPayloadPrefix)) {
      return null;
    }
    final String? dhikrId =
        TasbeehReminderNotificationService.dhikrIdFromPayload(
          payload,
        );
    if (dhikrId == null) {
      return null;
    }
    return <String, dynamic>{'type': 'tasbeeh', 'dhikrId': dhikrId};
  }

  static Map<String, dynamic>? _athkarDataFromPayload(String payload) {
    final bool isMorning = payload.startsWith(athkarMorningPayloadPrefix);
    final bool isEvening = payload.startsWith(athkarEveningPayloadPrefix);
    if (!isMorning && !isEvening) {
      return null;
    }
    return <String, dynamic>{
      'type': 'athkar',
      'categoryId': isMorning
          ? athkarMorningCategoryId
          : athkarEveningCategoryId,
      'categoryName': isMorning
          ? athkarMorningCategoryName
          : athkarEveningCategoryName,
    };
  }

  /// Normalizes legacy payload aliases (`actionType`→`type`, `actionData`→`data`)
  /// and infers `type` from well-known keys.
  static Map<String, dynamic> normalizePayloadData(
    Map<String, dynamic> payload,
  ) {
    final Map<String, dynamic> normalized = Map<String, dynamic>.from(payload);

    normalized['type'] ??= normalized['actionType'];
    normalized['data'] ??= normalized['actionData'];

    if (normalized['type'] == null) {
      if (normalized['reciterId'] != null) {
        normalized['type'] = 'reciter';
      } else if (normalized['surahNumber'] != null) {
        normalized['type'] = 'quran';
      } else if (normalized['categoryId'] != null ||
          normalized['categoryName'] != null) {
        normalized['type'] = 'athkar';
      }
    }

    return normalized;
  }
}
