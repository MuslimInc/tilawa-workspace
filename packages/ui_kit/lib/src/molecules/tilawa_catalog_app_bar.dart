import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';
import 'tilawa_app_bar.dart';
import 'tilawa_search_field.dart';

/// Pinterest-style feature header: white [TilawaAppBarSurface.parchment],
/// left-aligned title, optional search row — matches Reciters catalog chrome.
///
/// Prefer this over a raw [TilawaAppBar] on list/catalog screens. Pass
/// [preferredHeight] from [TilawaAppBarConfig.catalogTitleOnlyHeight],
/// [TilawaAppBarConfig.catalogTitleAndSearchHeight], or
/// [TilawaAppBarConfig.catalogTitleAndContentHeight].
class TilawaCatalogAppBar extends StatelessWidget implements PreferredSizeWidget {
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

  /// Title-only catalog header.
  factory TilawaCatalogAppBar.titleOnly(
    BuildContext context, {
    Key? key,
    required String title,
    Widget? leading,
    List<Widget>? actions,
    bool automaticallyImplyLeading = false,
    VoidCallback? onBackPressed,
    bool showBottomHairline = TilawaAppBarConfig.showBottomHairline,
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
    final Widget titleChild =
        titleWidget ?? Text(title!, style: titleStyle);

    return TilawaAppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      surface: TilawaAppBarSurface.parchment,
      centerTitle: false,
      toolbarHeight: 0,
      showBottomHairline: showBottomHairline,
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
  });

  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    final List<Widget>? spacedActions = TilawaAppBarChrome.spacedActions(
      actions,
      tokens,
    );

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
}
