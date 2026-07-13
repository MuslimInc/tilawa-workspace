import 'dart:math' as math;

enum KhatmaReadingStyle { pages }

enum KhatmaPlanAdjustment { none, extended }

final class KhatmaPlan {
  const KhatmaPlan({
    required this.id,
    required this.createdAt,
    required this.startDate,
    required this.durationDays,
    required this.startPage,
    required this.targetPage,
    required this.assignmentDate,
    required this.assignmentStartPage,
    required this.assignmentEndPage,
    this.confirmedCompletedThroughPage,
    this.adjustment = KhatmaPlanAdjustment.none,
    this.adjustmentDate,
  });

  static const int firstQuranPage = 1;
  static const int lastQuranPage = 604;

  final String id;
  final DateTime createdAt;
  final DateTime startDate;
  final int durationDays;
  final int startPage;
  final int targetPage;
  final int? confirmedCompletedThroughPage;
  final DateTime assignmentDate;
  final int assignmentStartPage;
  final int assignmentEndPage;
  final KhatmaPlanAdjustment adjustment;
  final DateTime? adjustmentDate;

  KhatmaReadingStyle get readingStyle => KhatmaReadingStyle.pages;

  int get totalPages => targetPage - startPage + 1;

  int get completedPages {
    final int? confirmed = confirmedCompletedThroughPage;
    if (confirmed == null) return 0;
    return (confirmed - startPage + 1).clamp(0, totalPages);
  }

  int get remainingPages => totalPages - completedPages;

  double get progress => totalPages <= 0 ? 0 : completedPages / totalPages;

  bool get isCompleted => confirmedCompletedThroughPage == targetPage;

  int get confirmedTodayPages {
    final int? confirmed = confirmedCompletedThroughPage;
    if (confirmed == null || confirmed < assignmentStartPage) return 0;
    return (confirmed - assignmentStartPage + 1).clamp(
      0,
      assignedTodayPages,
    );
  }

  int get assignedTodayPages => assignmentEndPage - assignmentStartPage + 1;

  int get remainingTodayPages => assignedTodayPages - confirmedTodayPages;

  bool get isTodayCompleted => remainingTodayPages == 0;

  int get resumePage {
    final int firstUnconfirmed =
        (confirmedCompletedThroughPage ?? assignmentStartPage - 1) + 1;
    return firstUnconfirmed.clamp(assignmentStartPage, assignmentEndPage);
  }

  DateTime get expectedCompletionDate =>
      startDate.add(Duration(days: durationDays - 1));

  int currentDay(DateTime now) {
    final int elapsed = _dateOnly(now).difference(_dateOnly(startDate)).inDays;
    return (elapsed + 1).clamp(1, durationDays);
  }

  int remainingDays(DateTime now) {
    final int elapsed = _dateOnly(now).difference(_dateOnly(startDate)).inDays;
    return (durationDays - elapsed).clamp(1, durationDays);
  }

  int plannedDailyPages() =>
      (totalPages / durationDays).ceil().clamp(1, lastQuranPage);

  int targetPagesFor(DateTime now) {
    if (isCompleted) return 0;
    return math.min(
      remainingPages,
      (remainingPages / remainingDays(now)).ceil().clamp(1, lastQuranPage),
    );
  }

  int missedDays(DateTime now) {
    final int expectedPages = math.min(
      totalPages,
      plannedDailyPages() * currentDay(now),
    );
    final int debt = expectedPages - completedPages;
    return debt <= 0 ? 0 : (debt / plannedDailyPages()).ceil();
  }

  KhatmaPlan copyWith({
    int? confirmedCompletedThroughPage,
    bool clearConfirmedCompletedThroughPage = false,
    int? durationDays,
    DateTime? assignmentDate,
    int? assignmentStartPage,
    int? assignmentEndPage,
    KhatmaPlanAdjustment? adjustment,
    DateTime? adjustmentDate,
  }) {
    return KhatmaPlan(
      id: id,
      createdAt: createdAt,
      startDate: startDate,
      durationDays: durationDays ?? this.durationDays,
      startPage: startPage,
      targetPage: targetPage,
      confirmedCompletedThroughPage: clearConfirmedCompletedThroughPage
          ? null
          : confirmedCompletedThroughPage ?? this.confirmedCompletedThroughPage,
      assignmentDate: assignmentDate ?? this.assignmentDate,
      assignmentStartPage: assignmentStartPage ?? this.assignmentStartPage,
      assignmentEndPage: assignmentEndPage ?? this.assignmentEndPage,
      adjustment: adjustment ?? this.adjustment,
      adjustmentDate: adjustmentDate ?? this.adjustmentDate,
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

final class KhatmaTodayTarget {
  const KhatmaTodayTarget({required this.plan, required this.missedDays});

  final KhatmaPlan plan;
  final int missedDays;

  int get startPage => plan.assignmentStartPage;
  int get endPage => plan.assignmentEndPage;
  int get pages => plan.assignedTodayPages;
  int get completedPages => plan.confirmedTodayPages;
  int get remainingTodayPages => plan.remainingTodayPages;
  double get progress => plan.progress;
  int get remainingPages => plan.remainingPages;
}
