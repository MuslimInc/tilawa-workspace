import 'package:dartz_plus/dartz_plus.dart';

import '../entities/booking_block_reason.dart';
import '../entities/manual_payment_price.dart';
import '../entities/quran_teacher.dart';
import '../entities/session_pricing_quote.dart';
import '../entities/session_pricing_type.dart';
import '../entities/teacher_list_item.dart';
import '../failures/quran_sessions_failure.dart';
import '../repositories/teacher_repository.dart';
import 'get_booking_pricing_quote_usecase.dart';
import 'get_teachers_usecase.dart';

/// Resolved, ready-to-render page of teacher rows.
///
/// [items] are the rows the discovery list should show — teachers whose quote
/// is bookable or only transiently blocked. [rawTeacherCount] is the number of
/// teachers the page returned before the bookability filter, so the caller can
/// tell "no teachers matched the filter" apart from "teachers exist but none
/// are bookable right now".
class TeacherListResult {
  const TeacherListResult({
    required this.items,
    required this.rawTeacherCount,
    required this.nextCursor,
    this.hiddenByBlockReason = const {},
  });

  final List<TeacherListItem> items;
  final int rawTeacherCount;
  final String? nextCursor;

  /// Durable block reasons for teachers hidden from discovery.
  final Map<BookingBlockReason, int> hiddenByBlockReason;

  bool get hasMore => nextCursor != null;
}

/// Fetches a page of teachers and resolves each row's server pricing quote,
/// then applies the domain bookability rule — hiding teachers with a durable
/// [BookingBlockReason] while keeping transiently-blocked ones visible.
///
/// This is the single place the pricing/bookability policy lives for discovery:
/// the BLoC only maps the result to view states. Quote fetches are deduplicated
/// per teacher id and run concurrently, so resolving a page is O(unique ids)
/// round-trips with O(1) id → quote joins.
class ResolveTeacherListUseCase {
  const ResolveTeacherListUseCase(
    this._getTeachers, {
    this._getPricingQuote,
    this._getPricingQuotes,
  });

  final GetTeachersUseCase _getTeachers;

  /// Optional: when unwired (legacy markets without server quotes), every
  /// teacher stays visible and no quote is attached.
  final GetBookingPricingQuoteUseCase? _getPricingQuote;

  /// Optional batch resolver. When wired it prices a whole page in one call
  /// (removing the per-teacher N+1); a batch transport failure falls back to
  /// the per-teacher [_getPricingQuote] so a flaky batch never blanks the page.
  final GetBookingPricingQuotesUseCase? _getPricingQuotes;

  /// Fetches a page and resolves quotes in one call. Kept for pagination and
  /// callers that don't need progressive rendering; the teacher-list BLoC drives
  /// the two phases ([fetchTeachers] then [resolveQuotes]) separately so it can
  /// show teachers before the (cold-start-prone) pricing call returns.
  Future<Either<QuranSessionsFailure, TeacherListResult>> call({
    String? specialization,
    String? language,
    String? cursor,
  }) async {
    final result = await fetchTeachers(
      specialization: specialization,
      language: language,
      cursor: cursor,
    );
    if (result.isLeft()) {
      return Left(
        result.fold(
          (failure) => failure,
          (_) => throw StateError('unreachable'),
        ),
      );
    }

    final page = result.fold((_) => throw StateError('unreachable'), (p) => p);
    return Right(
      await resolveQuotes(page.teachers, nextCursor: page.nextCursor),
    );
  }

  /// Phase 1: the raw teacher page, before any pricing/bookability resolution.
  /// Cheap and fast — the discovery list renders these immediately while
  /// [resolveQuotes] runs.
  Future<Either<QuranSessionsFailure, TeacherPage>> fetchTeachers({
    String? specialization,
    String? language,
    String? cursor,
  }) => _getTeachers(
    specialization: specialization,
    language: language,
    cursor: cursor,
  );

  /// Phase 2: resolve each teacher's server quote and apply the bookability
  /// filter. This is where the pricing/bookability policy lives — teachers with
  /// a durable [BookingBlockReason] are hidden; transiently-blocked ones stay.
  Future<TeacherListResult> resolveQuotes(
    List<QuranTeacher> teachers, {
    String? nextCursor,
  }) async {
    final quotes = await _resolveQuotes(teachers);
    final items = [
      for (final teacher in teachers)
        TeacherListItem(
          teacher: _applyQuoteToTeacher(teacher, quotes[teacher.id]),
          pricingQuote: quotes[teacher.id],
        ),
    ];
    final visible = items.where((item) => item.isVisibleInList).toList();
    final hiddenByBlockReason = <BookingBlockReason, int>{};
    for (final item in items.where((item) => !item.isVisibleInList)) {
      final reason = item.blockReason;
      hiddenByBlockReason[reason] = (hiddenByBlockReason[reason] ?? 0) + 1;
    }
    return TeacherListResult(
      items: visible,
      rawTeacherCount: teachers.length,
      nextCursor: nextCursor,
      hiddenByBlockReason: hiddenByBlockReason,
    );
  }

  /// Resolves quotes for the page's *unique* teacher ids, keyed by id for O(1)
  /// joins. Prefers the single batch call ([_getPricingQuotes]); ids absent
  /// from any resolution stay unquoted (treated as transiently unresolved).
  Future<Map<String, SessionPricingQuote>> _resolveQuotes(
    List<QuranTeacher> teachers,
  ) async {
    if (teachers.isEmpty) return const {};
    final uniqueIds = [
      for (final id in {for (final teacher in teachers) teacher.id}) id,
    ];

    final getPricingQuotes = _getPricingQuotes;
    if (getPricingQuotes != null) {
      final batch = await getPricingQuotes(teacherIds: uniqueIds);
      final resolved = batch.fold((_) => null, (quotes) => quotes);
      // Only fall back per-teacher when the batch call itself failed; an empty
      // map is a valid result (no ids resolvable) and must not re-trigger N+1.
      if (resolved != null) return resolved;
    }

    return _resolveQuotesPerTeacher(uniqueIds);
  }

  /// Legacy per-teacher fan-out (one quote call per id, concurrently). Used when
  /// the batch resolver is unwired or a batch call fails. Ids whose quote
  /// transport failed are absent from the returned map.
  Future<Map<String, SessionPricingQuote>> _resolveQuotesPerTeacher(
    List<String> uniqueIds,
  ) async {
    final getPricingQuote = _getPricingQuote;
    if (getPricingQuote == null) return const {};

    final entries = await Future.wait(
      uniqueIds.map((teacherId) async {
        final quote = await getPricingQuote(teacherId: teacherId);
        return MapEntry(teacherId, quote.fold((_) => null, (q) => q));
      }),
    );
    return {
      for (final entry in entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }
}

QuranTeacher _applyQuoteToTeacher(
  QuranTeacher teacher,
  SessionPricingQuote? quote,
) {
  if (quote == null || !quote.isPaid) return teacher;
  return QuranTeacher(
    id: teacher.id,
    displayName: teacher.displayName,
    bio: teacher.bio,
    avatarUrl: teacher.avatarUrl,
    gender: teacher.gender,
    verificationStatus: teacher.verificationStatus,
    supportedCallTypes: teacher.supportedCallTypes,
    pricingType: SessionPricingType.fixedPerSession,
    specializations: teacher.specializations,
    languages: teacher.languages,
    averageRating: teacher.averageRating,
    totalReviews: teacher.totalReviews,
    totalSessionsCompleted: teacher.totalSessionsCompleted,
    price: quote.price ?? teacher.price,
    manualPaymentPrice: quote.isManualOffApp
        ? ManualPaymentPrice(
            amountMinor: (quote.amount * 100).round(),
            currencyCode: quote.currencyCode,
          )
        : teacher.manualPaymentPrice,
    cityName: teacher.cityName,
    countryName: teacher.countryName,
    credentials: teacher.credentials,
  );
}
