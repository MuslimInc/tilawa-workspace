import 'khatma_plan.dart';
import '../khatma_plan_boundaries.dart';

enum KhatmaSessionKind { previous, current, upcoming }

/// One planned daily slice of a Khatma (page range).
final class KhatmaSession {
  const KhatmaSession({
    required this.index,
    required this.startPage,
    required this.endPage,
    required this.kind,
  });

  /// 1-based session number within the plan.
  final int index;
  final int startPage;
  final int endPage;
  final KhatmaSessionKind kind;

  int get pageCount => endPage - startPage + 1;

  ({int surah, int ayah})? get startVerse =>
      KhatmaPlanBoundaries.firstVerseOnPage(startPage);

  ({int surah, int ayah})? get endVerse =>
      KhatmaPlanBoundaries.lastVerseOnPage(endPage);
}

/// Builds inspectable previous / current / upcoming sessions from plan math.
abstract final class KhatmaSessionSchedule {
  static List<KhatmaSession> build(KhatmaPlan plan) {
    final List<({int start, int end})> slices = _slices(
      startPage: plan.startPage,
      targetPage: plan.targetPage,
      durationDays: plan.durationDays,
    );
    if (slices.isEmpty) return const [];

    final int currentIndex = _currentSliceIndex(
      slices,
      assignmentStart: plan.assignmentStartPage,
      assignmentEnd: plan.assignmentEndPage,
    );

    return [
      for (var i = 0; i < slices.length; i++)
        KhatmaSession(
          index: i + 1,
          startPage: slices[i].start,
          endPage: slices[i].end,
          kind: i < currentIndex
              ? KhatmaSessionKind.previous
              : i == currentIndex
              ? KhatmaSessionKind.current
              : KhatmaSessionKind.upcoming,
        ),
    ];
  }

  static int previousCount(KhatmaPlan plan) =>
      build(plan).where((s) => s.kind == KhatmaSessionKind.previous).length;

  static int upcomingCount(KhatmaPlan plan) =>
      build(plan).where((s) => s.kind == KhatmaSessionKind.upcoming).length;

  static List<KhatmaSession> previous(KhatmaPlan plan) =>
      build(plan).where((s) => s.kind == KhatmaSessionKind.previous).toList();

  static List<KhatmaSession> upcoming(KhatmaPlan plan) =>
      build(plan).where((s) => s.kind == KhatmaSessionKind.upcoming).toList();

  static List<({int start, int end})> _slices({
    required int startPage,
    required int targetPage,
    required int durationDays,
  }) {
    if (startPage > targetPage || durationDays < 1) return const [];
    final int totalPages = targetPage - startPage + 1;
    final int safeDuration = durationDays.clamp(1, totalPages);
    final List<({int start, int end})> result = [];
    var cursor = startPage;
    for (var day = 0; day < safeDuration && cursor <= targetPage; day++) {
      final int remainingDays = safeDuration - day;
      final int remainingPages = targetPage - cursor + 1;
      final int assigned = (remainingPages / remainingDays).ceil().clamp(
        1,
        remainingPages,
      );
      final int end = cursor + assigned - 1;
      result.add((start: cursor, end: end));
      cursor = end + 1;
    }
    return result;
  }

  static int _currentSliceIndex(
    List<({int start, int end})> slices, {
    required int assignmentStart,
    required int assignmentEnd,
  }) {
    for (var i = 0; i < slices.length; i++) {
      final slice = slices[i];
      if (slice.start == assignmentStart && slice.end == assignmentEnd) {
        return i;
      }
      if (assignmentStart >= slice.start && assignmentStart <= slice.end) {
        return i;
      }
    }
    return slices.length - 1;
  }
}
