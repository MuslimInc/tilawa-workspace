import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../theme/quran_sessions_theme.dart';

/// Filter chips for the teacher discovery list.
enum TeacherListFilter {
  all,
  free,
  availableToday,
  recitation,
  tajweed,
  hifz,
}

extension TeacherListFilterX on TeacherListFilter {
  String label(QuranSessionsLocalizations l10n) => switch (this) {
    TeacherListFilter.all => l10n.teacherFilterAll,
    TeacherListFilter.free => l10n.teacherFilterFree,
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
    TeacherListFilter.free || TeacherListFilter.availableToday => true,
    _ => false,
  };
}

class TeacherListFilterBar extends StatelessWidget {
  const TeacherListFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final TeacherListFilter selected;
  final ValueChanged<TeacherListFilter> onSelected;

  static const filters = TeacherListFilter.values;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final feature = context.quranSessionsTheme;
    final tokens = Theme.of(context).tokens;

    return SizedBox(
      height: feature.filterBarHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: feature.screenPadding,
        itemCount: filters.length,
        separatorBuilder: (_, _) => SizedBox(width: tokens.spaceExtraSmall),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selected;
          return FilterChip(
            label: Text(
              filter.label(l10n),
              style: feature.chipLabelStyle.copyWith(
                color: isSelected
                    ? feature.filterSelectedForeground
                    : feature.filterUnselectedForeground,
              ),
            ),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(filter),
            selectedColor: feature.filterSelectedBackground,
            backgroundColor: feature.filterTrackColor,
            side: BorderSide(
              color: isSelected
                  ? feature.filterSelectedBackground
                  : feature.cardBorderColor,
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
