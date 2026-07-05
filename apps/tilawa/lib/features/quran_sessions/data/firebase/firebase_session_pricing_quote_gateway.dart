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

  SessionPricingQuote _quoteFromResponse(Map<String, dynamic> data) {
    return SessionPricingQuote(
      pricingType: data['pricingType'] == 'fixedPerSession'
          ? SessionPricingType.fixedPerSession
          : SessionPricingType.free,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      currencyCode: data['currencyCode'] as String? ?? 'USD',
      paymentRequired: data['paymentRequired'] as bool? ?? false,
      paymentProviderAvailable:
          data['paymentProviderAvailable'] as bool? ?? false,
      countryCode: data['countryCode'] as String?,
      cityId: data['cityId'] as String?,
      policyVersion: data['policyVersion'] as String?,
    );
  }
}
