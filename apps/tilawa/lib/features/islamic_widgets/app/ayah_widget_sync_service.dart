import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_logger.dart';
import '../data/daily_ayah_widget_repository.dart';
import '../domain/entities/ayah_widget_payload.dart';

/// Startup/date-change gate for the Ayah widget snapshot (spec 041, T022).
///
/// Runs once per local calendar day: composing the snapshot renders two PNG
/// artifacts, so the daily dedup keeps app launches cheap. Best-effort by
/// design — on failure the widget keeps its last published day (never a blank
/// frame, FR-014) and the next launch retries.
class AyahWidgetSyncService {
  AyahWidgetSyncService({
    required this._repository,
    required this._prefs,
    @visibleForTesting this._isSupportedOverride,
  });

  static const String _lastPublishedDateKey =
      'islamic_widget_ayah_last_published_date';

  /// Bump when the rendered artifact format/typography changes so existing
  /// installs re-render on next launch instead of serving stale artwork.
  static const int artifactRevision = 3;

  final DailyAyahWidgetRepository _repository;
  final SharedPreferencesAsync _prefs;
  final bool? _isSupportedOverride;

  bool get isSupported => _isSupportedOverride ?? Platform.isAndroid;

  /// Publishes today's snapshot unless it was already published today.
  Future<void> syncIfNeeded({DateTime? now}) async {
    if (!isSupported) return;
    final DateTime instant = now ?? DateTime.now();
    final String publishStamp = '${_dateKey(instant)}#r$artifactRevision';
    try {
      final String? lastPublished = await _prefs.getString(
        _lastPublishedDateKey,
      );
      if (lastPublished == publishStamp) {
        return;
      }
      final AyahWidgetPayload? published = await _repository.publishFor(
        instant,
      );
      if (published == null) {
        // Fonts not downloaded yet — leave the stamp unset so the next launch
        // retries once the QCF bundle has streamed in.
        return;
      }
      await _prefs.setString(_lastPublishedDateKey, publishStamp);
    } catch (e, stackTrace) {
      logger.w(
        '[AyahWidgetSyncService] sync failed (widget keeps last snapshot): $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
