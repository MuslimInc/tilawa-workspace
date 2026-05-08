import 'dart:convert';

enum NotificationPayloadKind {
  localPrayer,
  nativeAdhan,
  genericFcmPrayer,
  unknown,
}

bool isPrayerPayloadOwnedByPrayerService(NotificationPayloadKind kind) {
  return kind == NotificationPayloadKind.localPrayer ||
      kind == NotificationPayloadKind.nativeAdhan;
}

NotificationPayloadKind classifyPrayerNotificationPayload(String? payload) {
  if (payload == null || payload.trim().isEmpty) {
    return NotificationPayloadKind.unknown;
  }

  try {
    final dynamic decoded = jsonDecode(payload);
    if (decoded is! Map) {
      return NotificationPayloadKind.unknown;
    }
    return classifyPrayerNotificationData(Map<String, dynamic>.from(decoded));
  } catch (_) {
    // Fallback for malformed payloads that still contain strong native marker.
    if (payload.contains('"prayer_key":')) {
      return NotificationPayloadKind.nativeAdhan;
    }
    return NotificationPayloadKind.unknown;
  }
}

NotificationPayloadKind classifyPrayerNotificationData(
  Map<String, dynamic> data,
) {
  final String? type = _normalizedType(data);
  final bool hasPrayerIdentity = _hasPrayerIdentity(data);
  final bool hasScheduleMarker =
      _hasNumericValue(data, 'scheduled_time_ms') ||
      _hasNumericValue(data, 'scheduled_ms');
  final bool hasPrayerKey = _hasNonEmptyString(data, 'prayer_key');

  // Native adhan payloads from MainActivity/method channel can include
  // scheduled fields, so prefer this classification when the live-adhan marker
  // is present.
  if (hasPrayerKey && _isNativeAdhanMarkerPresent(data)) {
    return NotificationPayloadKind.nativeAdhan;
  }

  if (type == 'prayer' && hasPrayerIdentity && hasScheduleMarker) {
    return NotificationPayloadKind.localPrayer;
  }

  if (type == 'prayer') {
    return NotificationPayloadKind.genericFcmPrayer;
  }

  return NotificationPayloadKind.unknown;
}

bool _hasNonEmptyString(Map<String, dynamic> data, String key) {
  final dynamic value = data[key];
  return value is String && value.trim().isNotEmpty;
}

bool _hasNumericValue(Map<String, dynamic> data, String key) {
  final dynamic value = data[key];
  return value is num ||
      (value is String &&
          value.trim().isNotEmpty &&
          num.tryParse(value) != null);
}

String? _normalizedType(Map<String, dynamic> data) {
  final dynamic rawType = data['type'] ?? data['actionType'];
  if (rawType == null) {
    return null;
  }
  final String type = rawType.toString().trim().toLowerCase();
  return type.isEmpty ? null : type;
}

bool _hasPrayerIdentity(Map<String, dynamic> data) {
  return _hasNonEmptyString(data, 'prayer') ||
      _hasNonEmptyString(data, 'prayer_name') ||
      _hasNonEmptyString(data, 'prayer_key');
}

bool _isNativeAdhanMarkerPresent(Map<String, dynamic> data) {
  final dynamic isAdhanPlaying = data['is_adhan_playing'];
  return isAdhanPlaying == true || data.containsKey('adhan_source');
}
