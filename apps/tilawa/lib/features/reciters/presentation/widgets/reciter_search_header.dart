import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:tilawa/features/reciters/presentation/reciter_semantics_ids.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Pinned search + view-toggle row under [ReciterDetailsAppBar].
///
/// Matches reciters list header chrome: quiet [ColorScheme.surfaceContainerHigh]
/// with a hairline bottom edge — no glass blur or custom responsive lerps.
double reciterDetailsSearchHeaderExtent(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  return theme.componentTokens.searchField.height +
      (theme.tokens.spaceMedium * 2);
}

/// [RefreshIndicator.edgeOffset] below pinned app bar + search header.
///
/// [SliverAppBar] with `primary: true` includes [MediaQuery.padding] top; omitting
/// it places the spinner over the search field.
double reciterDetailsRefreshIndicatorEdgeOffset(BuildContext context) {
  return MediaQuery.paddingOf(context).top +
      kToolbarHeight +
      reciterDetailsSearchHeaderExtent(context);
}

class ReciterSearchHeader extends StatelessWidget {
  const ReciterSearchHeader({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final double extent = reciterDetailsSearchHeaderExtent(context);

    return SliverPersistentHeader(
      pinned: true,
      delegate: _ReciterSearchHeaderDelegate(
        extent: extent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant,
                width: tokens.borderWidthThin,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: tokens.contentMaxWidthMedia,
                  ),
                  child: Row(
                    spacing: tokens.spaceSmall,
                    children: [
                      Expanded(
                        child: Semantics(
                          identifier:
                              ReciterSemanticsIds.reciterDetailsSurahSearch,
                          child: TilawaSearchField(
                            controller: controller,
                            hintText: context.l10n.searchSurah,
                            prefixIcon: FluentIcons.search_24_regular,
                            clearIcon: FluentIcons.dismiss_24_regular,
                            borderRadius: BorderRadius.circular(
                              tokens.radiusLarge,
                            ),
                            showShadow: true,
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
                            onTapOutside: (_) =>
                                FocusScope.of(context).unfocus(),
                          ),
                        ),
                      ),
                      Semantics(
                        identifier:
                            ReciterSemanticsIds.reciterDetailsViewToggle,
                        child:
                            BlocBuilder<
                              ReciterDetailsBloc,
                              ReciterDetailsState
                            >(
                              buildWhen:
                                  (ReciterDetailsState previous,
                                      ReciterDetailsState current) =>
                                      previous.viewMode != current.viewMode,
                              builder: (BuildContext context, state) {
                                final bool isList =
                                    state.viewMode == ReciterViewMode.list;
                                return TilawaIconActionButton(
                                  icon: isList
                                      ? FluentIcons.grid_24_regular
                                      : FluentIcons.list_24_regular,
                                  isActive: !isList,
                                  toggled: !isList,
                                  backgroundColor: colorScheme.surface,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReciterSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ReciterSearchHeaderDelegate({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: extent, child: child);
  }

  @override
  bool shouldRebuild(_ReciterSearchHeaderDelegate oldDelegate) {
    return extent != oldDelegate.extent || child != oldDelegate.child;
  }
}
