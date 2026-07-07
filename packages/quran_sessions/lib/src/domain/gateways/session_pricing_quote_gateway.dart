import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_pricing_quote.dart';
import '../failures/quran_sessions_failure.dart';

/// Server boundary for the authoritative booking pricing preview
/// (`getBookingPricingQuote` callable).
abstract interface class SessionPricingQuoteGateway {
  Future<Either<QuranSessionsFailure, SessionPricingQuote>> getPricingQuote({
    required String teacherId,
  });

  /// Batch variant (`getBookingPricingQuotes` callable): resolves the shared
  /// student/market/platform context once and returns a `teacherId → quote`
  /// map, eliminating the per-teacher N+1 on list load. A teacher id absent
  /// from the returned map has no quote (treated as transiently unresolved).
  Future<Either<QuranSessionsFailure, Map<String, SessionPricingQuote>>>
  getPricingQuotes({required List<String> teacherIds});
}
