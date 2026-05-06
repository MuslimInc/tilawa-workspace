import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:tilawa/features/reciters/presentation/reciter_semantics_ids.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class ReciterSearchHeader extends StatelessWidget {
  const ReciterSearchHeader({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final InputBorder? themedInputBorder =
        theme.inputDecorationTheme.focusedBorder ??
        theme.inputDecorationTheme.enabledBorder ??
        theme.inputDecorationTheme.border;
    final BorderRadius inputBorderRadius =
        themedInputBorder is OutlineInputBorder
        ? themedInputBorder.borderRadius
        : BorderRadius.circular(tokens.radiusLarge);
    final double screenWidth = context.resolveContentWidth(
      TilawaContentKind.media,
    );
    final double textScaleFactor = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.3).toDouble();
    final double widthFactor = ((screenWidth - 320) / 120)
        .clamp(0.0, 1.0)
        .toDouble();
    final double headerScale = ((textScaleFactor - 1.0) / 0.3)
        .clamp(0.0, 1.0)
        .toDouble();
    final double headerHeight = lerpDouble(64, 72, headerScale)!;
    final double horizontalPadding = lerpDouble(12, 16, widthFactor)!;
    final double outerVerticalPadding = ((headerHeight - 48) / 2)
        .clamp(8.0, 12.0)
        .toDouble();
    final double inputHorizontalPadding = lerpDouble(12, 16, widthFactor)!;
    final double inputVerticalPadding =
        (lerpDouble(10, 12, widthFactor)! / textScaleFactor)
            .clamp(8.0, 12.0)
            .toDouble();
    final double headerBlur = tokens.blurGlass;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyHeaderDelegate(
        minHeight: headerHeight,
        maxHeight: headerHeight,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: headerBlur, sigmaY: headerBlur),
            child: Container(
              color: colorScheme.surface.withValues(
                alpha: tokens.opacityEmphasis,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: outerVerticalPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        identifier:
                            ReciterSemanticsIds.reciterDetailsSurahSearch,
                        child: TilawaSearchField(
                          controller: controller,
                          hintText: context.l10n.searchSurah,
                          backgroundColor: colorScheme.surfaceContainerLow
                              .withValues(alpha: tokens.opacityEmphasis),
                          borderRadius: inputBorderRadius,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: inputHorizontalPadding,
                            vertical: inputVerticalPadding,
                          ),
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: tokens.opacityMedium,
                            ),
                          ),
                          onClear: () {
                            controller.clear();
                            context.read<ReciterDetailsBloc>().add(
                              const FilterSurahs(''),
                            );
                          },
                          onChanged: (query) {
                            context.read<ReciterDetailsBloc>().add(
                              FilterSurahs(query),
                            );
                          },
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        ),
                      ),
                    ),
                    SizedBox(width: tokens.spaceSmall),
                    Semantics(
                      identifier: ReciterSemanticsIds.reciterDetailsViewToggle,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow.withValues(
                            alpha: tokens.opacityEmphasis,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary.withValues(
                              alpha: tokens.opacitySubtle,
                            ),
                          ),
                        ),
                        child: IconButton(
                          icon:
                              BlocBuilder<
                                ReciterDetailsBloc,
                                ReciterDetailsState
                              >(
                                buildWhen: (previous, current) =>
                                    previous.viewMode != current.viewMode,
                                builder: (context, state) {
                                  return Icon(
                                    state.viewMode == ReciterViewMode.list
                                        ? Icons.grid_view_rounded
                                        : Icons.view_list_rounded,
                                    color: colorScheme.primary,
                                  );
                                },
                              ),
                          onPressed: () {
                            context.read<ReciterDetailsBloc>().add(
                              const ToggleViewMode(),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
