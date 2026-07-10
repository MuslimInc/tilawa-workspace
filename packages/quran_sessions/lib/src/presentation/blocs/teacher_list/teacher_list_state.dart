import 'package:equatable/equatable.dart';

import '../../../domain/entities/booking_block_reason.dart';
import '../../../domain/entities/quran_teacher.dart';
import '../../../domain/entities/session_pricing_quote.dart';
import '../../../domain/entities/teacher_list_item.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../models/teacher_availability_summary.dart';

sealed class TeacherListState extends Equatable {
  const TeacherListState();

  @override
  List<Object?> get props => [];
}

final class TeacherListInitial extends TeacherListState {
  const TeacherListInitial();
}

final class TeacherListLoading extends TeacherListState {
  const TeacherListLoading();
}

final class TeacherListSuccess extends TeacherListState {
  TeacherListSuccess({
    required this.items,
    required this.hasMore,
    this.availabilitySummaries = const {},
    this.nextCursor,
    this.isLoadingMore = false,
    this.activeSpecialization,
    this.activeLanguage,
  });

  /// Resolved rows (teacher + server quote + bookability), already filtered to
  /// the ones the list should show. Source of truth for the derived views below.
  final List<TeacherListItem> items;

  final bool hasMore;
  final String? nextCursor;
  final Map<String, TeacherAvailabilitySummary> availabilitySummaries;

  /// True while appending the next page; existing [items] stay visible.
  final bool isLoadingMore;

  final String? activeSpecialization;
  final String? activeLanguage;

  /// Visible teachers. Computed once per state instance (not per rebuild).
  late final List<QuranTeacher> teachers = List.unmodifiable(
    items.map((item) => item.teacher),
  );

  /// O(1) teacher-id → resolved item lookup for row rendering.
  late final Map<String, TeacherListItem> itemsById = {
    for (final item in items) item.teacherId: item,
  };

  /// Server-authoritative pricing per visible teacher, keyed by id for O(1)
  /// lookup. A teacher is absent only when its quote transport failed; such
  /// rows stay visible and the booking screen surfaces neutral retry copy.
  late final Map<String, SessionPricingQuote> pricingQuotes = {
    for (final item in items)
      if (item.pricingQuote != null) item.teacherId: item.pricingQuote!,
  };

  /// Pricing for the first visible row. Retained for backward compatibility;
  /// prefer the per-teacher [pricingQuotes] map.
  SessionPricingQuote? get pricingQuote =>
      items.isEmpty ? null : items.first.pricingQuote;

  @override
  List<Object?> get props => [
    items,
    hasMore,
    availabilitySummaries,
    nextCursor,
    isLoadingMore,
    activeSpecialization,
    activeLanguage,
  ];

  TeacherListSuccess copyWith({
    List<TeacherListItem>? items,
    bool? hasMore,
    Map<String, TeacherAvailabilitySummary>? availabilitySummaries,
    String? nextCursor,
    bool? isLoadingMore,
    String? activeSpecialization,
    String? activeLanguage,
  }) => TeacherListSuccess(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    availabilitySummaries: availabilitySummaries ?? this.availabilitySummaries,
    nextCursor: nextCursor ?? this.nextCursor,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    activeSpecialization: activeSpecialization ?? this.activeSpecialization,
    activeLanguage: activeLanguage ?? this.activeLanguage,
  );
}

/// Teachers exist but none are bookable for this viewer right now — every
/// resolved quote reported a durable [BookingBlockReason] (typically a paid
/// teacher while the payment provider is disabled). The student must not reach
/// a dead-end booking screen, so the list shows a dedicated empty state instead
/// of paid-but-unbookable rows.
final class TeacherListNoBookableTeachers extends TeacherListState {
  const TeacherListNoBookableTeachers({
    this.activeSpecialization,
    this.activeLanguage,
    this.hiddenByBlockReason = const {},
  });

  final String? activeSpecialization;
  final String? activeLanguage;
  final Map<BookingBlockReason, int> hiddenByBlockReason;

  BookingBlockReason? get primaryBlockReason {
    if (hiddenByBlockReason.isEmpty) return null;
    final sorted = hiddenByBlockReason.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  @override
  List<Object?> get props => [
    activeSpecialization,
    activeLanguage,
    hiddenByBlockReason,
  ];
}

/// No results after applying the current filters.
final class TeacherListEmpty extends TeacherListState {
  const TeacherListEmpty({
    this.activeSpecialization,
    this.activeLanguage,
  });

  final String? activeSpecialization;
  final String? activeLanguage;

  @override
  List<Object?> get props => [activeSpecialization, activeLanguage];
}

final class TeacherListFailure extends TeacherListState {
  const TeacherListFailure(this.failure);

  final QuranSessionsFailure failure;

  @override
  List<Object?> get props => [failure];
}
