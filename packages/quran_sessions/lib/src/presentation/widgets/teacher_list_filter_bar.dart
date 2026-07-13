import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Filter chips for the teacher discovery list.
enum TeacherListFilter {
  all,
  free,
  paid,
  budget,
  availableToday,
  recitation,
  tajweed,
  hifz,
}

extension TeacherListFilterX on TeacherListFilter {
  String label(
    QuranSessionsLocalizations l10n, {
    String? budgetPriceLabel,
  }) => switch (this) {
    TeacherListFilter.all => l10n.teacherFilterAll,
    TeacherListFilter.free => l10n.teacherFilterFree,
    TeacherListFilter.paid => l10n.teacherFilterPaid,
    TeacherListFilter.budget =>
      budgetPriceLabel == null
          ? l10n.teacherFilterBudget
          : l10n.teacherFilterUnderPrice(budgetPriceLabel),
    TeacherListFilter.availableToday => l10n.teacherFilterAvailableToday,
    TeacherListFilter.recitation => l10n.specializationLabel('recitation'),
    TeacherListFilter.tajweed => l10n.specializationLabel('tajweed'),
    TeacherListFilter.hifz => l10n.specializationLabel('hifz'),
  };

  String? get specializationCode => switch (this) {
    TeacherListFilter.recitation => 'recitation',
    TeacherListFilter.tajweed => 'tajweed',
    TeacherListFilter.hifz => 'hifz',
    _ => null,
  };

  bool get isClientSideOnly => switch (this) {
    TeacherListFilter.free ||
    TeacherListFilter.paid ||
    TeacherListFilter.budget ||
    TeacherListFilter.availableToday => true,
    _ => false,
  };
}

class TeacherListFilterBar extends StatelessWidget {
  const TeacherListFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.budgetPriceLabel,
  });

  final TeacherListFilter selected;
  final ValueChanged<TeacherListFilter> onSelected;

  /// Formatted ceiling for [TeacherListFilter.budget], e.g. `500 ج.م.`.
  final String? budgetPriceLabel;

  static const List<TeacherListFilter> filters = TeacherListFilter.values;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;

    return SizedBox(
      height: tokens.minInteractiveDimension * 0.8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
        itemCount: filters.length,
        separatorBuilder: (_, _) => SizedBox(width: tokens.spaceExtraSmall),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selected;
          return FilterChip(
            label: Text(
              filter.label(l10n, budgetPriceLabel: budgetPriceLabel),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(filter),
            selectedColor: scheme.primary,
            backgroundColor: scheme.surfaceContainerHigh,
            side: BorderSide(
              color: isSelected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(
                      alpha: tokens.opacityEmphasis,
                    ),
            ),
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}
