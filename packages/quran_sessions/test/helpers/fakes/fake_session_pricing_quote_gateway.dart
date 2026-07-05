import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/src/domain/entities/session_pricing_quote.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/gateways/session_pricing_quote_gateway.dart';

/// Fake server pricing quote gateway for booking bloc tests.
class FakeSessionPricingQuoteGateway implements SessionPricingQuoteGateway {
  FakeSessionPricingQuoteGateway({this.quote, this.failure});

  SessionPricingQuote? quote;
  QuranSessionsFailure? failure;
  int callCount = 0;

  @override
  Future<Either<QuranSessionsFailure, SessionPricingQuote>> getPricingQuote({
    required String teacherId,
  }) async {
    callCount += 1;
    final f = failure;
    if (f != null) return Left(f);
    final q = quote;
    if (q != null) return Right(q);
    return const Left(UnknownFailure());
  }
}
