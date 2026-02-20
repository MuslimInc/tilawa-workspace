import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciter_details_bloc.dart';
import 'package:tilawa_ui/theme/color_scheme.dart';

class ReciterSearchHeader extends StatelessWidget {
  const ReciterSearchHeader({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyHeaderDelegate(
        minHeight: 64.h,
        maxHeight: 64.h,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(
                alpha: 0.85,
              ), // Semi-transparent
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: context.l10n.searchSurah,
                          hintStyle: TextStyle(
                            color: Theme.of(
                              context,
                            ).hintColor.withValues(alpha: 0.5),
                          ),
                          // Glassy input field
                          fillColor: Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withValues(alpha: 0.5),
                          filled: true,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: context.primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              30.r,
                            ), // Pill shape
                            borderSide: BorderSide(
                              color: context.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.r),
                            borderSide: BorderSide(
                              color: context.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.r),
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
                                color: Theme.of(context).hintColor,
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
                    SizedBox(width: 8.w),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withValues(alpha: 0.5),
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
