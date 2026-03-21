import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui/theme/color_scheme.dart';

class MoshafSelector extends StatelessWidget {
  const MoshafSelector({super.key, required this.reciter, required this.state});
  final ReciterEntity reciter;
  final ReciterDetailsState state;

  @override
  Widget build(BuildContext context) {
    final List<MoshafEntity> uniqueMoshaf = reciter.moshaf.toSet().toList();
    final MoshafEntity selectedMoshaf =
        state.selectedMoshaf ?? uniqueMoshaf.first;
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ButtonTheme(
          alignedDropdown: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MoshafEntity>(
              isExpanded: true,
              dropdownColor: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 24,
                color: theme.primaryColor,
              ),
              value: uniqueMoshaf.contains(selectedMoshaf)
                  ? selectedMoshaf
                  : uniqueMoshaf.first,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              padding: EdgeInsets.symmetric(horizontal: 8),
              items: uniqueMoshaf.map((moshaf) {
                return DropdownMenuItem<MoshafEntity>(
                  value: moshaf,
                  child: Text(
                    moshaf.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                );
              }).toList(),
              onChanged: (MoshafEntity? moshaf) {
                if (moshaf != null) {
                  context.read<ReciterDetailsBloc>().add(
                    LoadSurahList(reciter: reciter, moshaf: moshaf),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
