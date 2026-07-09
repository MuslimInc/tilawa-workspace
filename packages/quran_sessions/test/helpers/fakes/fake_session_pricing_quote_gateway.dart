import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/src/domain/entities/session_pricing_quote.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/gateways/session_pricing_quote_gateway.dart';

/// Fake server pricing quote gateway for booking bloc tests.
///
/// Returns a single [quote]/[failure] for every teacher by default. Pass
/// [quotesByTeacher] to differentiate per teacher id (e.g. one free-bookable
/// row and one paid-unbookable row), which the teacher-list bookability filter
/// relies on.
class FakeSessionPricingQuoteGateway implements SessionPricingQuoteGateway {
  FakeSessionPricingQuoteGateway({
    this.quote,
    this.failure,
    this.quotesByTeacher,
    this.batchFailure,
    this.quoteDelay,
  });

  SessionPricingQuote? quote;
  QuranSessionsFailure? failure;
  Map<String, SessionPricingQuote>? quotesByTeacher;
  int callCount = 0;

  /// When set, [getPricingQuote] resolves after this delay so tests can observe
  /// the booking screen render slots while the quote is still in flight.
  Duration? quoteDelay;

  /// Per-teacher quote calls (the legacy N+1 path). Batch calls increment
  /// [batchCallCount] instead, so tests can assert which path resolved a page.
  int get perTeacherCallCount => callCount;

  /// Number of [getPricingQuotes] batch calls.
  int batchCallCount = 0;

  /// When set, batch calls fail with this — used to exercise the per-teacher
  /// fallback inside `ResolveTeacherListUseCase`.
  final QuranSessionsFailure? batchFailure;

  @override
  Future<Either<QuranSessionsFailure, SessionPricingQuote>> getPricingQuote({
    required String teacherId,
  }) async {
    callCount += 1;
    final delay = quoteDelay;
    if (delay != null) await Future<void>.delayed(delay);
    final perTeacher = quotesByTeacher?[teacherId];
    if (perTeacher != null) return Right(perTeacher);
    final f = failure;
    if (f != null) return Left(f);
    final q = quote;
    if (q != null) return Right(q);
    return const Left(UnknownFailure());
  }

  @override
  Future<Either<QuranSessionsFailure, Map<String, SessionPricingQuote>>>
  getPricingQuotes({required List<String> teacherIds}) async {
    batchCallCount += 1;
    final f = batchFailure;
    if (f != null) return Left(f);
    final resolved = <String, SessionPricingQuote>{};
    for (final teacherId in teacherIds) {
      final perTeacher = quotesByTeacher?[teacherId] ?? quote;
      if (perTeacher != null) resolved[teacherId] = perTeacher;
    }
    return Right(resolved);
  }
}
