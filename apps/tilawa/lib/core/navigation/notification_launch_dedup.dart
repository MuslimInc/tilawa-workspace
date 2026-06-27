import 'package:shared_preferences/shared_preferences.dart';

/// Persists which local-notification launch was already routed.
///
/// ## Why this exists
///
/// On Android and iOS, [NotificationAppLaunchDetails] from
/// `getNotificationAppLaunchDetails()` can keep reporting the same launch tap
/// after a Flutter **hot restart** (same OS process, Dart statics reset).
///
/// ## Dedup key (most specific wins)
///
/// 1. **Payload signature** when [launchPayload] is non-empty — distinguishes
///    same notification id with different destinations (e.g. dynamic Athkar ids).
/// 2. **Notification id** when payload is empty but id is present.
/// 3. **No key** when both are missing — caller must not navigate from launch
///    probe (Athkar service already rejects empty payloads).
///
/// We intentionally do **not** dedup on route-only or coarse timestamps: that
/// would block legitimate new notifications that reuse an id (Athkar 1001/1002,
/// prayer id blocks) in a later OS process.
///
/// ## Process scoping
///
/// Signatures are scoped to [_lastNotifPidKey]. A real process kill starts a
/// new pid, so a genuine notification cold start is never blocked by stale state.
///
/// ## Preference bounds
///
/// Three fixed keys only (`_last_notif_id`, `_last_notif_pid`,
/// `_last_notif_payload_sig`). Values are int/string primitives — no sensitive
/// data, no unbounded growth. Keys are overwritten on each handled launch, never
/// appended.
class NotificationLaunchDedup {
  NotificationLaunchDedup._();

  static const String lastNotifIdKey = '_last_notif_id';
  static const String lastNotifPidKey = '_last_notif_pid';
  static const String lastNotifPayloadSigKey = '_last_notif_payload_sig';

  /// Bumped when launch-dedup storage rules change. Marker only; repair happens
  /// in [isProcessedLaunch] and [persist].
  static const String schemaVersionKey = '_notif_launch_dedup_schema_v';
  static const int currentSchemaVersion = 2;

  /// Ensures preference schema is current before reading launch dedup state.
  static Future<void> ensureSchemaCurrent({
    required SharedPreferencesAsync prefs,
  }) async {
    final int version = await prefs.getInt(schemaVersionKey) ?? 1;
    if (version >= currentSchemaVersion) {
      return;
    }
    await prefs.setInt(schemaVersionKey, currentSchemaVersion);
  }

  /// Builds the dedup signature for an incoming or stored launch.
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
      // Bootstrap stores payload signatures; later consume clears pending
      // response and may persist id-only. Never downgrade p: → i: or hot
      // restart replays mismatch and re-navigate to Athkar/prayer routes.
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

  /// Whether this launch was already handled in [pid].
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
      if (_isCorruptedIdOnlyReplay(
        storedSignature: storedSignature,
        launchNotificationId: launchNotificationId,
        incomingSignature: incomingSignature,
      )) {
        // Pre-fix consume wrote id-only over payload sig. Repair cache so the
        // next hot restart matches by payload instead of replaying Athkar routes.
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

    // Backward compatibility for installs that only stored id before payload sig.
    final int? storedId = await prefs.getInt(lastNotifIdKey);
    if (storedId == null) {
      return false;
    }
    return launchNotificationId == null || storedId == launchNotificationId;
  }

  static bool _isCorruptedIdOnlyReplay({
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
