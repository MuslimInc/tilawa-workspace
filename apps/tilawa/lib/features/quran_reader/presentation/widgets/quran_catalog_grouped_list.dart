import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Flat grouped catalog list — one white panel with hairline row dividers.
///
/// Matches Settings / Home More grouped-list chrome for long Quran hub lists.
class QuranCatalogGroupedList extends StatelessWidget {
  const QuranCatalogGroupedList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.bottomPadding = 0,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        QuranCatalogGroupedSliver(
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        ),
        if (bottomPadding > 0)
          SliverPadding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
      ],
    );
  }
}

/// Grouped catalog panel as a sliver — panel height follows list content only.
class QuranCatalogGroupedSliver extends StatelessWidget {
  const QuranCatalogGroupedSliver({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final TilawaSettingsGroupTokens groupTokens =
        theme.componentTokens.settingsGroup;
    final double radius = tokens.resolveRadius(
      family: TilawaRadiusFamily.section,
    );
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final BorderSide containerSide = BorderSide(
      color: groupTokens.groupContainerBorderColor,
      width: groupTokens.tileDividerThickness,
    );

    return SliverPadding(
      padding: EdgeInsetsDirectional.fromSTEB(
        groupTokens.groupHorizontalPadding,
        0,
        groupTokens.groupHorizontalPadding,
        0,
      ),
      sliver: SliverList.separated(
        itemCount: itemCount,
        separatorBuilder: (context, index) => _GroupedCatalogDivider(
          groupTokens: groupTokens,
          containerSide: containerSide,
        ),
        itemBuilder: (context, index) {
          return _GroupedCatalogItemShell(
            isFirst: index == 0,
            isLast: index == itemCount - 1,
            borderRadius: borderRadius,
            containerSide: containerSide,
            surfaceColor: groupTokens.groupSurfaceColor,
            child: itemBuilder(context, index),
          );
        },
      ),
    );
  }
}

class _GroupedCatalogItemShell extends StatelessWidget {
  const _GroupedCatalogItemShell({
    required this.isFirst,
    required this.isLast,
    required this.borderRadius,
    required this.containerSide,
    required this.surfaceColor,
    required this.child,
  });

  final bool isFirst;
  final bool isLast;
  final BorderRadius borderRadius;
  final BorderSide containerSide;
  final Color surfaceColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          left: containerSide,
          right: containerSide,
          top: isFirst ? containerSide : BorderSide.none,
          bottom: isLast ? containerSide : BorderSide.none,
        ),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? borderRadius.topLeft : Radius.zero,
          bottom: isLast ? borderRadius.bottomLeft : Radius.zero,
        ),
      ),
      child: child,
    );
  }
}

class _GroupedCatalogDivider extends StatelessWidget {
  const _GroupedCatalogDivider({
    required this.groupTokens,
    required this.containerSide,
  });

  final TilawaSettingsGroupTokens groupTokens;
  final BorderSide containerSide;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: groupTokens.groupSurfaceColor,
        border: Border(
          left: containerSide,
          right: containerSide,
        ),
      ),
      child: Padding(
        padding: groupTokens.tileDividerPadding,
        child: Divider(
          height: groupTokens.tileDividerHeight,
          thickness: groupTokens.tileDividerThickness,
          color: groupTokens.selectionTileDividerColor,
        ),
      ),
    );
  }
}
