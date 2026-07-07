import 'package:equatable/equatable.dart';

import 'booking_block_reason.dart';
import 'quran_teacher.dart';
import 'session_pricing_quote.dart';

/// A discovery-list row with its pricing/bookability already resolved.
///
/// One item per teacher, produced by `ResolveTeacherListUseCase`. Bundling the
/// teacher with its server quote lets the presentation layer render the row and
/// its price chip without re-deriving any business rule.
///
/// [pricingQuote] is null only when the per-teacher quote transport failed
/// (network/App Check/timeout). A null quote is treated as the transient
/// [BookingBlockReason.pricingQuoteUnavailable]: the row stays visible and the
/// booking screen resolves a fresh quote before allowing submit.
class TeacherListItem extends Equatable {
  const TeacherListItem({
    required this.teacher,
    this.pricingQuote,
  });

  final QuranTeacher teacher;
  final SessionPricingQuote? pricingQuote;

  String get teacherId => teacher.id;

  /// Server-reported reason, or [BookingBlockReason.pricingQuoteUnavailable]
  /// when the quote could not be fetched.
  BookingBlockReason get blockReason =>
      pricingQuote?.blockReason ?? BookingBlockReason.pricingQuoteUnavailable;

  /// Whether this row should appear in the discovery list.
  bool get isVisibleInList => !blockReason.hidesTeacherFromList;

  /// Whether the booking screen can accept a submission for this teacher right
  /// now. False for both durable blocks and unresolved quotes.
  bool get isBookable => blockReason == BookingBlockReason.none;

  @override
  List<Object?> get props => [teacher, pricingQuote];
}
