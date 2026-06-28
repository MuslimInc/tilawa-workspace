import 'package:shared_preferences/shared_preferences.dart';

/// Persists which local-notification launch was already routed.
///
/// On Android and iOS, `getNotificationAppLaunchDetails()` can keep reporting
/// the same launch tap after a Flutter hot restart (same OS process, Dart statics
/// reset). Signatures are scoped to [lastNotifPidKey]; a process kill starts a
/// new pid so a genuine cold start is never blocked.
///
/// ## Signature format (most specific wins)
///
/// 1. `p:<payload>` when payload is non-empty.
/// 2. `i:<notificationId>` when payload is empty but id is present.
/// 3. No signature when both are missing.
///
/// [persist] never downgrades `p:` to `i:` in the same process. [isProcessedLaunch]
/// repairs legacy id-only entries when a payload replay is detected.
class NotificationLaunchDedup {
  NotificationLaunchDedup._();

  static const String lastNotifIdKey = '_last_notif_id';
  static const String lastNotifPidKey = '_last_notif_pid';
  static const String lastNotifPayloadSigKey = '_last_notif_payload_sig';
  static const String schemaVersionKey = '_notif_launch_dedup_schema_v';
  static const int currentSchemaVersion = 2;

  static Future<void> ensureSchemaCurrent({
    required SharedPreferencesAsync prefs,
  }) async {
    final int version = await prefs.getInt(schemaVersionKey) ?? 1;
    if (version >= currentSchemaVersion) {
      return;
    }
    await prefs.setInt(schemaVersionKey, currentSchemaVersion);
  }

  static String? launchSignature({
    int? notificationId,
    String? payload,
  }) {
    final String trimmedPayload = payload?.trim() ?? '';
    if (trimmedPayload.isNotEmpty) {
      return 'p:$trimmedPayload';
    }
    if (notificationId != null) {
      return 'i:$notificationId';
    }
    return null;
  }

  static Future<void> persist({
    int? notificationId,
    String? payload,
    required SharedPreferencesAsync prefs,
    required int pid,
  }) async {
    final String? signature = launchSignature(
      notificationId: notificationId,
      payload: payload,
    );
    if (signature == null) {
      return;
    }

    final int? storedPid = await prefs.getInt(lastNotifPidKey);
    if (storedPid == pid) {
      final String? storedSignature = await prefs.getString(
        lastNotifPayloadSigKey,
      );
      if (storedSignature != null &&
          storedSignature.startsWith('p:') &&
          signature.startsWith('i:')) {
        if (notificationId != null) {
          await prefs.setInt(lastNotifIdKey, notificationId);
        }
        return;
      }
    }

    await prefs.setInt(lastNotifPidKey, pid);
    await prefs.setString(lastNotifPayloadSigKey, signature);
    if (notificationId != null) {
      await prefs.setInt(lastNotifIdKey, notificationId);
    }
  }

  static Future<int?> readStoredNotificationId({
    required SharedPreferencesAsync prefs,
    required int pid,
  }) async {
    final int? storedPid = await prefs.getInt(lastNotifPidKey);
    if (storedPid != pid) {
      return null;
    }
    return prefs.getInt(lastNotifIdKey);
  }

  static Future<String?> readStoredSignature({
    required SharedPreferencesAsync prefs,
    required int pid,
  }) async {
    final int? storedPid = await prefs.getInt(lastNotifPidKey);
    if (storedPid != pid) {
      return null;
    }
    return prefs.getString(lastNotifPayloadSigKey);
  }

  static Future<bool> isProcessedLaunch({
    required int? launchNotificationId,
    String? launchPayload,
    required SharedPreferencesAsync prefs,
    required int pid,
  }) async {
    await ensureSchemaCurrent(prefs: prefs);

    final int? storedPid = await prefs.getInt(lastNotifPidKey);
    if (storedPid != pid) {
      return false;
    }

    final String? incomingSignature = launchSignature(
      notificationId: launchNotificationId,
      payload: launchPayload,
    );
    if (incomingSignature == null) {
      return false;
    }

    final String? storedSignature = await prefs.getString(
      lastNotifPayloadSigKey,
    );
    if (storedSignature != null) {
      if (storedSignature == incomingSignature) {
        return true;
      }
      if (_isLegacyIdOnlyReplay(
        storedSignature: storedSignature,
        launchNotificationId: launchNotificationId,
        incomingSignature: incomingSignature,
      )) {
        await persist(
          notificationId: launchNotificationId,
          payload: launchPayload,
          prefs: prefs,
          pid: pid,
        );
        return true;
      }
      return false;
    }

    final int? storedId = await prefs.getInt(lastNotifIdKey);
    if (storedId == null) {
      return false;
    }
    return launchNotificationId == null || storedId == launchNotificationId;
  }

  static bool _isLegacyIdOnlyReplay({
    required String storedSignature,
    required int? launchNotificationId,
    required String incomingSignature,
  }) {
    if (!storedSignature.startsWith('i:') ||
        !incomingSignature.startsWith('p:') ||
        launchNotificationId == null) {
      return false;
    }
    final int? storedId = int.tryParse(storedSignature.substring(2));
    return storedId == launchNotificationId;
  }
}
