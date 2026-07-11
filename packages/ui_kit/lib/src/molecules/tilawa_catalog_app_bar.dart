import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Pinterest-style feature header: white [TilawaAppBarSurface.parchment],
/// left-aligned title, optional search row — the kit's catalog screen chrome.
///
/// Prefer this over a raw [TilawaAppBar] on list/catalog screens.
class TilawaCatalogAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const TilawaCatalogAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottomContent,
    this.bottomContentHeight,
    this.automaticallyImplyLeading = true,
    this.onBackPressed,
    this.showBottomHairline = TilawaAppBarConfig.showBottomHairline,
    this.showElevationShadow = TilawaAppBarConfig.showElevationShadow,
    this.centerTitle = false,
  }) : assert(title != null || titleWidget != null);

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;

  /// Placed below the title row (search field, filters, segments).
  final Widget? bottomContent;

  /// Explicit height for [bottomContent]. If omitted, it will try to infer
  /// from standard search field height or fallback.
  final double? bottomContentHeight;

  final bool automaticallyImplyLeading;

  /// GoRouter-friendly back handler; defaults to [Navigator.maybePop].
  final VoidCallback? onBackPressed;
  final bool showBottomHairline;
  final bool showElevationShadow;

  /// When true, the title is centered between balanced leading/trailing slots.
  final bool centerTitle;

  /// Title-only catalog header.
  factory TilawaCatalogAppBar.titleOnly({
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

  double _resolveBottomHeight(BuildContext context) {
    if (bottomContent == null) return 0;
    if (bottomContentHeight != null) return bottomContentHeight!;

    // Default to search field height plus padding if no height was provided
    final searchHeight = Theme.of(context).componentTokens.searchField.height;
    return searchHeight + Theme.of(context).tokens.spaceMedium;
  }

  @override
  Size get preferredSize {
    // We must return a size before context is available in build().
    // Scaffold will still rely on this for the bounding box.
    // However, since we can't reliably get theme without context here,
    // if bottomContentHeight is missing, we use a rough estimate (48 + 16 = 64).
    final double bottomHeight = bottomContent != null
        ? (bottomContentHeight ?? 64.0)
        : 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    // Wrap bottom content in standard spacing and max-width slot.
    PreferredSizeWidget? resolvedBottom;
    if (bottomContent != null) {
      final double bottomHeight = _resolveBottomHeight(context);
      resolvedBottom = PreferredSize(
        preferredSize: Size.fromHeight(bottomHeight),
        child: Container(
          height: bottomHeight,
          alignment: Alignment.center,
          padding: EdgeInsets.only(bottom: Theme.of(context).tokens.spaceSmall),
          child: TilawaSearchFieldSlot(child: bottomContent!),
        ),
      );
    }

    final Widget? resolvedLeading = TilawaAppBarChrome.resolveCatalogRowLeading(
      context,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      onBackPressed: onBackPressed,
    );

    return TilawaAppBar(
      title: title,
      titleWidget: titleWidget,
      leading: resolvedLeading,
      actions: actions,
      bottom: resolvedBottom,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      surface: TilawaAppBarSurface.parchment,
      showBottomHairline: showBottomHairline,
      showElevationShadow: showElevationShadow,
    );
  }
}
