import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/widgets.dart' show Locale;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa_core/config/language_config.dart';

import '../../../core/logging/app_logger.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../smart_khatma/domain/entities/wird_progress_summary.dart';
import '../../smart_khatma/domain/usecases/get_wird_progress_summary_use_case.dart';
import '../data/widget_snapshot_bridge.dart';
import '../domain/entities/widget_snapshot_envelope.dart';
import '../domain/entities/wird_progress_widget_payload.dart';
import '../presentation/adapters/wird_progress_widget_adapter.dart';

/// Pushes the Daily Wird / Khatma progress snapshot to the native widget store
/// (spec 041 amendment, T-041A1-e).
///
/// This is the last Flutter step before the native boundary: it reads the
/// semantic summary owned by Spec 023 ([GetWirdProgressSummaryUseCase]), runs
/// the Spec 041 presentation adapter, and dispatches the versioned
/// [WirdProgressWidgetPayload] over the existing [WidgetSnapshotBridge]. The
/// native provider (T-041A1-c) decodes and renders it verbatim.
///
/// Best-effort by design (FR-041A1.4 — never a blank frame): on any failure the
/// native widget keeps its last published snapshot and the next trigger retries.
/// A content signature suppresses redundant dispatches while still allowing
/// intra-day updates (e.g. after the user completes part of today's Wird).
class WirdProgressWidgetSyncService {
  WirdProgressWidgetSyncService({
    required this._useCase,
    required this._bridge,
    required this._prefs,
    WirdProgressWidgetAdapter? adapter,
    AppLocalizations Function(String languageCode)? localizationsResolver,
    WirdWidgetNumeralSystem Function(String languageCode)?
    numeralSystemResolver,
    DateTime Function()? now,
    @visibleForTesting this._isSupportedOverride,
  }) : _adapter = adapter ?? WirdProgressWidgetAdapter(),
       _localizationsResolver = localizationsResolver ?? _defaultLocalizations,
       _numeralSystemResolver = numeralSystemResolver ?? _numeralForLanguage,
       _now = now ?? DateTime.now;

  static const String _lastSignatureKey = 'islamic_widgets.wird.last_signature';

  final GetWirdProgressSummaryUseCase _useCase;
  final WidgetSnapshotBridge _bridge;
  final SharedPreferencesAsync _prefs;
  final WirdProgressWidgetAdapter _adapter;
  final AppLocalizations Function(String languageCode) _localizationsResolver;
  final WirdWidgetNumeralSystem Function(String languageCode)
  _numeralSystemResolver;
  final DateTime Function() _now;
  final bool? _isSupportedOverride;

  bool get isSupported => _isSupportedOverride ?? Platform.isAndroid;

  /// Publishes the current Wird snapshot unless nothing the user sees changed
  /// since the last publish.
  Future<void> syncIfNeeded({DateTime? now}) async {
    if (!isSupported) return;
    final DateTime instant = now ?? _now();
    try {
      final String languageCode =
          await _prefs.getString(LanguageConfig.languageKey) ??
          LanguageConfig.defaultLanguageCode;

      final WirdProgressSummary? summary = (await _useCase.call(
        now: instant,
      )).fold((_) => null, (WirdProgressSummary value) => value);
      if (summary == null) {
        // Plan data was unreadable: keep the last snapshot rather than clearing
        // the widget (FR-041A1.4). The next trigger retries.
        logger.w(
          '[WirdProgressWidgetSyncService] summary unavailable; '
          'widget keeps last snapshot',
        );
        return;
      }

      final WirdProgressWidgetPayload payload = _adapter.adapt(
        summary: summary,
        localizations: _localizationsResolver(languageCode),
        numeralSystem: _numeralSystemResolver(languageCode),
      );

      final String signature = _signatureFor(payload);
      if (await _prefs.getString(_lastSignatureKey) == signature) {
        return;
      }

      await _bridge.dispatchSnapshot(
        WidgetSnapshotEnvelope<WirdProgressWidgetPayload>(
          schemaVersion: payload.schemaVersion,
          widgetType: IslamicWidgetType.wird,
          generatedAt: payload.generatedAt,
          validUntil: payload.expiresAt,
          payload: payload,
        ),
      );
      await _prefs.setString(_lastSignatureKey, signature);
    } catch (e, stackTrace) {
      logger.w(
        '[WirdProgressWidgetSyncService] sync failed '
        '(widget keeps last snapshot): $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// A stable digest of everything the user sees, excluding the volatile
  /// timestamps (`generatedAt`/`expiresAt`) so a same-state relaunch dedups but
  /// any progress change re-publishes.
  String _signatureFor(WirdProgressWidgetPayload p) => <String>[
    p.locale,
    p.textDirection.name,
    p.localizedTitle,
    p.localizedSubtitle,
    p.formattedAssignedAmount,
    p.formattedCompletedAmount,
    p.formattedRemainingAmount,
    p.progressValue.toString(),
    p.action.name,
  ].join('|');

  static AppLocalizations _defaultLocalizations(String languageCode) =>
      lookupAppLocalizations(Locale(languageCode));

  /// No in-app numeral preference exists yet, so the numeral system follows the
  /// locale (Contract B digit rule: locale + any in-app preference). Arabic uses
  /// Arabic-Indic digits; every other locale uses Latin. Independent of text
  /// direction by construction.
  static WirdWidgetNumeralSystem _numeralForLanguage(String languageCode) =>
      languageCode.startsWith('ar')
      ? WirdWidgetNumeralSystem.arabicIndic
      : WirdWidgetNumeralSystem.latin;
}
