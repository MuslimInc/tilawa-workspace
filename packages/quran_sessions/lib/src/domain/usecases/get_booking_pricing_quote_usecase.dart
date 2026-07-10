import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_pricing_quote.dart';
import '../failures/quran_sessions_failure.dart';
import '../gateways/session_pricing_quote_gateway.dart';

/// Fetches the server-authoritative price preview shown before booking.
class GetBookingPricingQuoteUseCase {
  const GetBookingPricingQuoteUseCase(this._gateway);

  final SessionPricingQuoteGateway _gateway;

  Future<Either<QuranSessionsFailure, SessionPricingQuote>> call({
    required String teacherId,
  }) => _gateway.getPricingQuote(teacherId: teacherId);
}

/// Fetches server-authoritative price previews for many teachers in one call,
/// so the discovery list resolves a whole page without a per-teacher N+1.
class GetBookingPricingQuotesUseCase {
  const GetBookingPricingQuotesUseCase(this._gateway);

  final SessionPricingQuoteGateway _gateway;

  Future<Either<QuranSessionsFailure, Map<String, SessionPricingQuote>>> call({
    required List<String> teacherIds,
  }) => _gateway.getPricingQuotes(teacherIds: teacherIds);
}
