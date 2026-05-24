import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciter_catalog_chrome.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

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
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceExtraSmall,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ReciterCatalogChrome.idleFill(colorScheme),
          borderRadius: BorderRadius.circular(tokens.radiusLarge),
          border: Border.all(
            color: ReciterCatalogChrome.hairline(colorScheme, tokens),
            width: tokens.borderWidthThin,
          ),
        ),
        child: ButtonTheme(
          alignedDropdown: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MoshafEntity>(
              isExpanded: true,
              dropdownColor: colorScheme.surface,
              borderRadius: BorderRadius.circular(tokens.radiusLarge),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: tokens.iconSizeLarge,
                color: colorScheme.onSurface,
              ),
              value: uniqueMoshaf.contains(selectedMoshaf)
                  ? selectedMoshaf
                  : uniqueMoshaf.first,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
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
