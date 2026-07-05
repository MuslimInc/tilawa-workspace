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
