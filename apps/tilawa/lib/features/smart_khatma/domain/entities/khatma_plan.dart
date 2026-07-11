import 'dart:math' as math;

enum KhatmaReadingStyle { pages, minutes }

enum KhatmaPlanStatus { active, completed }

final class KhatmaPlan {
  const KhatmaPlan({
    required this.id,
    required this.createdAt,
    required this.startDate,
    required this.durationDays,
    required this.startPage,
    required this.targetPage,
    required this.currentPage,
    this.readingStyle = KhatmaReadingStyle.pages,
    this.preferredMinutesPerDay,
    this.status = KhatmaPlanStatus.active,
  });

  static const int firstQuranPage = 1;
  static const int lastQuranPage = 604;

  final String id;
  final DateTime createdAt;
  final DateTime startDate;
  final int durationDays;
  final int startPage;
  final int targetPage;
  final int currentPage;
  final KhatmaReadingStyle readingStyle;
  final int? preferredMinutesPerDay;
  final KhatmaPlanStatus status;

  int get totalPages => targetPage - startPage + 1;

  int get completedPages {
    final int completed = currentPage - startPage;
    return completed.clamp(0, totalPages);
  }

  int get remainingPages => (targetPage - currentPage + 1).clamp(0, totalPages);

  double get progress => totalPages <= 0 ? 0 : completedPages / totalPages;

  bool get isCompleted =>
      status == KhatmaPlanStatus.completed || remainingPages == 0;

  int currentDay(DateTime now) {
    final int elapsed = _dateOnly(now).difference(_dateOnly(startDate)).inDays;
    return (elapsed + 1).clamp(1, durationDays);
  }

  int remainingDays(DateTime now) {
    final int elapsed = _dateOnly(now).difference(_dateOnly(startDate)).inDays;
    return (durationDays - elapsed).clamp(1, durationDays);
  }

  int plannedDailyPages() {
    return (totalPages / durationDays).ceil().clamp(1, lastQuranPage);
  }

  int todayTargetPages(DateTime now) {
    if (isCompleted) {
      return 0;
    }
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
    final int pageDebt = expectedPages - completedPages;
    if (pageDebt <= 0) {
      return 0;
    }
    return (pageDebt / plannedDailyPages()).ceil();
  }

  KhatmaPlan copyWith({
    int? currentPage,
    KhatmaPlanStatus? status,
    int? durationDays,
  }) {
    return KhatmaPlan(
      id: id,
      createdAt: createdAt,
      startDate: startDate,
      durationDays: durationDays ?? this.durationDays,
      startPage: startPage,
      targetPage: targetPage,
      currentPage: currentPage ?? this.currentPage,
      readingStyle: readingStyle,
      preferredMinutesPerDay: preferredMinutesPerDay,
      status: status ?? this.status,
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

final class KhatmaTodayTarget {
  const KhatmaTodayTarget({
    required this.plan,
    required this.startPage,
    required this.pages,
    required this.missedDays,
  });

  final KhatmaPlan plan;
  final int startPage;
  final int pages;
  final int missedDays;

  double get progress => plan.progress;

  int get remainingPages => plan.remainingPages;
}
