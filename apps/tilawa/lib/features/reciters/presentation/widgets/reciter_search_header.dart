import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:tilawa/features/reciters/presentation/reciter_semantics_ids.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Height of [ReciterDetailsSearchBar] inside [TilawaSliverAppBar.bottom].
double reciterDetailsSearchHeaderExtent(BuildContext context) {
  return TilawaAppBarConfig.catalogSearchRowHeight(context);
}

/// [RefreshIndicator.edgeOffset] below pinned app bar (title + search bottom).
///
/// [SliverAppBar] with `primary: true` includes [MediaQuery.padding] top.
double reciterDetailsRefreshIndicatorEdgeOffset(BuildContext context) {
  return MediaQuery.paddingOf(context).top +
      kToolbarHeight +
      reciterDetailsSearchHeaderExtent(context);
}

/// Search + view-toggle row for [ReciterDetailsAppBar.bottom].
///
/// Chrome (vellum fill, hairline, elevation shadow) comes from [TilawaSliverAppBar].
class ReciterDetailsSearchBar extends StatelessWidget {
  const ReciterDetailsSearchBar({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    return TilawaSearchFieldSlot(
      padding: TilawaAppBarConfig.catalogChromePadding(tokens),
      child: Row(
        spacing: tokens.spaceSmall,
        children: [
          Expanded(
            child: Semantics(
              identifier: ReciterSemanticsIds.reciterDetailsSurahSearch,
              child: TilawaSearchField(
                controller: controller,
                hintText: context.l10n.searchSurah,
                prefixIcon: FluentIcons.search_24_regular,
                clearIcon: FluentIcons.dismiss_24_regular,
                showShadow: false,
                // Pinned in [SliverAppBar.bottom]; shell already insets for
                // keyboard — default scrollPadding scrolls the surah list away.
                scrollPadding: EdgeInsets.zero,
                onClear: () {
                  controller.clear();
                  context.read<ReciterDetailsBloc>().add(
                    const FilterSurahs(''),
                  );
                },
                onChanged: (String query) {
                  context.read<ReciterDetailsBloc>().add(
                    FilterSurahs(query),
                  );
                },
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
              ),
            ),
          ),
          Semantics(
            identifier: ReciterSemanticsIds.reciterDetailsViewToggle,
            child: BlocBuilder<ReciterDetailsBloc, ReciterDetailsState>(
              buildWhen:
                  (ReciterDetailsState previous, ReciterDetailsState current) =>
                      previous.viewMode != current.viewMode,
              builder: (BuildContext context, state) {
                final bool isList = state.viewMode == ReciterViewMode.list;
                return TilawaIconActionButton(
                  icon: isList
                      ? FluentIcons.grid_24_regular
                      : FluentIcons.list_24_regular,
                  isActive: !isList,
                  toggled: !isList,
                  onTap: () {
                    context.read<ReciterDetailsBloc>().add(
                      const ToggleViewMode(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
