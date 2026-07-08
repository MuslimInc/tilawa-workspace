import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/auth/domain/services/callable_session_payload_builder.dart';
import 'package:tilawa_core/services/performance_monitoring_service.dart';

import 'firebase_callable_failure_mapper.dart';
import 'firestore_performance_wrapper.dart';

/// Fetches the server-authoritative booking price preview
/// (`getBookingPricingQuote` callable).
class FirebaseSessionPricingQuoteGateway implements SessionPricingQuoteGateway {
  FirebaseSessionPricingQuoteGateway(
    this._functions,
    this._sessionPayloadBuilder, [
    this._perf,
  ]);

  final FirebaseFunctions _functions;
  final CallableSessionPayloadBuilder _sessionPayloadBuilder;
  final PerformanceMonitoringService? _perf;

  @override
  Future<Either<QuranSessionsFailure, SessionPricingQuote>> getPricingQuote({
    required String teacherId,
  }) async {
    return _perf.trace('functions_getBookingPricingQuote', () async {
      try {
        final callable = _functions.httpsCallable('getBookingPricingQuote');
        final response = await callable.call<Map<String, dynamic>>(
          await _sessionPayloadBuilder.withSessionEpoch({
            'teacherId': teacherId,
          }),
        );
        return Right(_quoteFromResponse(response.data));
      } on FirebaseFunctionsException catch (e) {
        return Left(
          mapQuranSessionsCallableFailure(e, teacherId: teacherId),
        );
      }
    });
  }

  @override
  Future<Either<QuranSessionsFailure, Map<String, SessionPricingQuote>>>
  getPricingQuotes({required List<String> teacherIds}) async {
    return _perf.trace('functions_getBookingPricingQuotes', () async {
      try {
        final callable = _functions.httpsCallable('getBookingPricingQuotes');
        final response = await callable.call<Map<String, dynamic>>(
          await _sessionPayloadBuilder.withSessionEpoch({
            'teacherIds': teacherIds,
          }),
        );
        final rawQuotes = (response.data['quotes'] as Map?) ?? const {};
        return Right(<String, SessionPricingQuote>{
          for (final entry in rawQuotes.entries)
            entry.key as String: _quoteFromResponse(
              Map<String, dynamic>.from(entry.value as Map),
            ),
        });
      } on FirebaseFunctionsException catch (e) {
        return Left(mapQuranSessionsCallableFailure(e));
      }
    });
  }

  SessionPricingQuote _quoteFromResponse(Map<String, dynamic> data) {
    final paymentRequired = data['paymentRequired'] as bool? ?? false;
    final paymentProviderAvailable =
        data['paymentProviderAvailable'] as bool? ?? false;
    final manualPaymentEnabled = data['manualPaymentEnabled'] as bool? ?? false;
    final paymentMode = SessionPaymentMode.fromString(
      data['paymentMode'] as String?,
    );

    // Backward-compat: a backend that has not yet shipped the typed
    // `blockReason` field returns only the loose booleans. Derive the paid-
    // unavailable reason from them so the booking screen still blocks a paid
    // session before submit — without this, a pre-deployment backend would
    // let the student tap Confirm and hit `payment_provider_unavailable`
    // server-side (9.8s wasted round-trip in live logs). Admin-disabled /
    // config-missing cannot be derived here; those still rely on the new
    // backend (or the submit-time failure mapper).
    final rawBlockReason = data['blockReason'] as String?;
    final blockReason = rawBlockReason != null && rawBlockReason != 'none'
        ? BookingBlockReason.fromString(rawBlockReason)
        : (paymentRequired &&
                  !paymentProviderAvailable &&
                  !manualPaymentEnabled &&
                  paymentMode != SessionPaymentMode.manualOffApp
              // Manual off-app is an available paid path; do not block it as a
              // missing online provider.
              ? BookingBlockReason.paymentProviderUnavailable
              : BookingBlockReason.none);

    return SessionPricingQuote(
      pricingType: data['pricingType'] == 'fixedPerSession'
          ? SessionPricingType.fixedPerSession
          : SessionPricingType.free,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      currencyCode: data['currencyCode'] as String? ?? 'USD',
      paymentRequired: paymentRequired,
      paymentProviderAvailable: paymentProviderAvailable,
      manualPaymentEnabled: manualPaymentEnabled,
      paymentMode: paymentMode,
      bookingEnabled: data['bookingEnabled'] as bool? ?? true,
      quranSessionsEnabled: data['quranSessionsEnabled'] as bool? ?? true,
      effectivePricingSource: EffectivePricingSource.fromString(
        data['effectivePricingSource'] as String?,
      ),
      blockReason: blockReason,
      countryCode: data['countryCode'] as String?,
      cityId: data['cityId'] as String?,
      policyVersion: data['policyVersion'] as String?,
    );
  }
}
