import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_pricing_quote.dart';
import '../failures/quran_sessions_failure.dart';

/// Server boundary for the authoritative booking pricing preview
/// (`getBookingPricingQuote` callable).
abstract interface class SessionPricingQuoteGateway {
  Future<Either<QuranSessionsFailure, SessionPricingQuote>> getPricingQuote({
    required String teacherId,
  });
}
