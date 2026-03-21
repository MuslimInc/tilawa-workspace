import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:tilawa_ui/theme/color_scheme.dart';

class ReciterSearchHeader extends StatelessWidget {
  const ReciterSearchHeader({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final InputBorder? themedInputBorder =
        theme.inputDecorationTheme.focusedBorder ??
        theme.inputDecorationTheme.enabledBorder ??
        theme.inputDecorationTheme.border;
    final BorderRadius inputBorderRadius =
        themedInputBorder is OutlineInputBorder
        ? themedInputBorder.borderRadius
        : BorderRadius.circular(16);
    final double screenWidth = MediaQuery.sizeOf(context).width;
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

    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyHeaderDelegate(
        minHeight: headerHeight,
        maxHeight: headerHeight,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: outerVerticalPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: context.l10n.searchSurah,
                          hintStyle: TextStyle(
                            color: theme.hintColor.withValues(alpha: 0.5),
                          ),
                          // Glassy input field
                          fillColor: theme.scaffoldBackgroundColor.withValues(
                            alpha: 0.5,
                          ),
                          filled: true,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: inputHorizontalPadding,
                            vertical: inputVerticalPadding,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: context.primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: inputBorderRadius,
                            borderSide: BorderSide(
                              color: context.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: inputBorderRadius,
                            borderSide: BorderSide(
                              color: context.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: inputBorderRadius,
                            borderSide: BorderSide(color: context.primaryColor),
                          ),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: controller,
                            builder: (context, value, child) {
                              if (value.text.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                color: theme.hintColor,
                                onPressed: () {
                                  controller.clear();
                                  context.read<ReciterDetailsBloc>().add(
                                    const FilterSurahs(''),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        onChanged: (query) {
                          context.read<ReciterDetailsBloc>().add(
                            FilterSurahs(query),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor.withValues(
                          alpha: 0.5,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.primaryColor.withValues(alpha: 0.1),
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
                                  color: context.primaryColor,
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
