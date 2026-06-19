import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';
import 'tilawa_app_bar.dart';
import 'tilawa_search_field.dart';

/// Pinterest-style feature header: white [TilawaAppBarSurface.parchment],
/// left-aligned title, optional search row — the kit's catalog screen chrome.
///
/// Prefer this over a raw [TilawaAppBar] on list/catalog screens. Pass
/// [preferredHeight] from [TilawaAppBarConfig.catalogTitleOnlyHeight],
/// [TilawaAppBarConfig.catalogTitleAndSearchHeight], or
/// [TilawaAppBarConfig.catalogTitleAndContentHeight].
class TilawaCatalogAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const TilawaCatalogAppBar({
    super.key,
    required this.preferredHeight,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottomContent,
    this.automaticallyImplyLeading = false,
    this.onBackPressed,
    this.showBottomHairline = TilawaAppBarConfig.showBottomHairline,
    this.showElevationShadow = TilawaAppBarConfig.showElevationShadow,
    this.centerTitle = false,
  }) : assert(title != null || titleWidget != null);

  /// Must match laid-out column height (use [TilawaAppBarConfig] helpers).
  final double preferredHeight;

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;

  /// Placed below the title row (search field, filters, segments).
  ///
  /// Do not wrap in [TilawaSearchFieldSlot]; this bar applies catalog padding.
  final Widget? bottomContent;
  final bool automaticallyImplyLeading;

  /// GoRouter-friendly back handler; defaults to [Navigator.maybePop].
  final VoidCallback? onBackPressed;
  final bool showBottomHairline;
  final bool showElevationShadow;

  /// When true, the title is centered between balanced leading/trailing slots.
  final bool centerTitle;

  /// Title-only catalog header.
  factory TilawaCatalogAppBar.titleOnly(
    BuildContext context, {
    Key? key,
    required String title,
    Widget? leading,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
    VoidCallback? onBackPressed,
    bool showBottomHairline = TilawaAppBarConfig.showBottomHairline,
    bool showElevationShadow = TilawaAppBarConfig.showElevationShadow,
    bool centerTitle = false,
  }) {
    return TilawaCatalogAppBar(
      key: key,
      preferredHeight: TilawaAppBarConfig.catalogTitleOnlyHeight(context),
      title: title,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      onBackPressed: onBackPressed,
      showBottomHairline: showBottomHairline,
      showElevationShadow: showElevationShadow,
      centerTitle: centerTitle,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(preferredHeight);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final TextStyle? titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final Widget titleChild = titleWidget ?? Text(title!, style: titleStyle);

    return TilawaAppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      surface: TilawaAppBarSurface.parchment,
      centerTitle: centerTitle,
      toolbarHeight: 0,
      showBottomHairline: showBottomHairline,
      showElevationShadow: showElevationShadow,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(preferredHeight),
        child: Semantics(
          header: true,
          label: title,
          explicitChildNodes: true,
          child: TilawaSearchFieldSlot(
            padding: TilawaAppBarConfig.catalogChromePadding(tokens),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.spaceSmall,
              children: [
                _CatalogTitleRow(
                  centerTitle: centerTitle,
                  leading: TilawaAppBarChrome.resolveCatalogRowLeading(
                    context,
                    leading: leading,
                    automaticallyImplyLeading: automaticallyImplyLeading,
                    onBackPressed: onBackPressed,
                  ),
                  title: titleChild,
                  actions: actions,
                ),
                ?bottomContent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogTitleRow extends StatelessWidget {
  const _CatalogTitleRow({
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle = false,
  });

  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    final List<Widget>? spacedActions = TilawaAppBarChrome.spacedActions(
      actions,
      tokens,
    );

    if (!centerTitle) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...<Widget>[
            leading!,
            SizedBox(width: tokens.spaceSmall),
          ],
          Expanded(child: title),
          ...?spacedActions,
        ],
      );
    }

    final double sideSlotWidth = tokens.minInteractiveDimension;
    final Widget? trailing = spacedActions == null
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: spacedActions,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: sideSlotWidth,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: leading,
          ),
        ),
        Expanded(
          child: Center(child: title),
        ),
        if (trailing != null) trailing else SizedBox(width: sideSlotWidth),
      ],
    );
  }
}
