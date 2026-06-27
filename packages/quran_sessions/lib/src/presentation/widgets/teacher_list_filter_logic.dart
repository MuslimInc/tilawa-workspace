import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';

import '../../domain/entities/quran_teacher.dart';
import '../../domain/entities/session_price.dart';
import '../../utils/price_formatter.dart';
import '../models/teacher_availability_summary.dart';
import '../widgets/teacher_list_filter_bar.dart';

/// Default budget ceiling when no paid prices are loaded (EGP-scale markets).
const double kTeacherListDefaultBudgetThreshold = 500;

/// Filters loaded teachers by a case-insensitive substring of [displayName].
List<QuranTeacher> filterTeachersByNameQuery(
  List<QuranTeacher> teachers,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return teachers;
  return teachers
      .where(
        (teacher) => teacher.displayName.toLowerCase().contains(normalized),
      )
      .toList();
}

/// Resolves the numeric ceiling for [TeacherListFilter.budget] from loaded rows.
double resolveTeacherBudgetPriceThreshold(List<QuranTeacher> teachers) {
  final paidAmounts = teachers
      .where((teacher) => !teacher.isFree && teacher.price != null)
      .map((teacher) => teacher.price!.amount)
      .toList();
  if (paidAmounts.isEmpty) return kTeacherListDefaultBudgetThreshold;
  paidAmounts.sort();
  final median = paidAmounts[paidAmounts.length ~/ 2];
  return median.clamp(100, kTeacherListDefaultBudgetThreshold);
}

/// Localised budget chip label derived from [teachers] on the current page.
String formatTeacherBudgetFilterLabel({
  required List<QuranTeacher> teachers,
  required QuranSessionsLocalizations l10n,
}) {
  final currencyCode = _resolveBudgetCurrencyCode(teachers);
  final threshold = resolveTeacherBudgetPriceThreshold(teachers);
  final amount = PriceFormatter.formatAmountOnly(
    amount: threshold,
    currencyCode: currencyCode,
  );
  return l10n.teacherFilterUnderPrice(amount);
}

SessionPrice? _referencePaidPrice(List<QuranTeacher> teachers) {
  for (final teacher in teachers) {
    if (!teacher.isFree && teacher.price != null) {
      return teacher.price;
    }
  }
  return null;
}

String _resolveBudgetCurrencyCode(List<QuranTeacher> teachers) {
  return _referencePaidPrice(teachers)?.currencyCode ?? 'EGP';
}

bool _matchesBudgetFilter(QuranTeacher teacher, double threshold) {
  if (teacher.isFree) return false;
  final price = teacher.price;
  if (price == null) return true;
  return price.amount <= threshold;
}

/// Applies client-side teacher list filters on top of repository results.
List<QuranTeacher> applyTeacherListClientFilter(
  List<QuranTeacher> teachers,
  TeacherListFilter filter,
  Map<String, TeacherAvailabilitySummary> availabilitySummaries, {
  double? budgetPriceThreshold,
}) {
  final budgetThreshold =
      budgetPriceThreshold ?? resolveTeacherBudgetPriceThreshold(teachers);

  return switch (filter) {
    TeacherListFilter.free =>
      teachers.where((teacher) => teacher.isFree).toList(),
    TeacherListFilter.paid =>
      teachers.where((teacher) => !teacher.isFree).toList(),
    TeacherListFilter.budget =>
      teachers
          .where((teacher) => _matchesBudgetFilter(teacher, budgetThreshold))
          .toList(),
    TeacherListFilter.availableToday =>
      teachers
          .where(
            (teacher) =>
                availabilitySummaries[teacher.id]?.status ==
                TeacherAvailabilityStatus.availableToday,
          )
          .toList(),
    _ => teachers,
  };
}

bool isTeacherListFilterEmptyForClientOnly(
  TeacherListFilter filter,
  List<QuranTeacher> teachers,
  Map<String, TeacherAvailabilitySummary> availabilitySummaries,
) {
  return applyTeacherListClientFilter(
    teachers,
    filter,
    availabilitySummaries,
  ).isEmpty;
}
