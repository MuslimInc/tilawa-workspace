import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

/// Surface tier for [TilawaAppBar] / [TilawaSliverAppBar].
///
/// * [vellum] — [ColorScheme.surfaceContainerHigh] (feature chrome).
/// * [parchment] — [ColorScheme.surface] (Quran reader chrome).
enum TilawaAppBarSurface {
  vellum,
  parchment,
}

/// Shared colors and shape for Tilawa app bar chrome.
abstract final class TilawaAppBarChrome {
  static Color backgroundColor(
    ColorScheme scheme,
    TilawaAppBarSurface surface,
  ) {
    return switch (surface) {
      TilawaAppBarSurface.vellum => scheme.surfaceContainerHigh,
      TilawaAppBarSurface.parchment => scheme.surface,
    };
  }

  static Color foregroundColor(ColorScheme scheme) => scheme.onSurface;

  static ShapeBorder bottomHairline(
    ColorScheme scheme,
    TilawaDesignTokens tokens,
  ) {
    return RoundedRectangleBorder(
      side: BorderSide(
        color: scheme.outlineVariant,
        width: tokens.borderWidthThin,
      ),
    );
  }

  static TextStyle? titleTextStyle(ThemeData theme) {
    return theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: foregroundColor(theme.colorScheme),
    );
  }

  static List<Widget>? spacedActions(
    List<Widget>? actions,
    TilawaDesignTokens tokens,
  ) {
    if (actions == null || actions.isEmpty) {
      return null;
    }
    if (actions.length == 1) {
      return actions;
    }
    return <Widget>[
      for (int i = 0; i < actions.length; i++) ...<Widget>[
        if (i > 0) SizedBox(width: tokens.spaceSmall),
        actions[i],
      ],
    ];
  }

  /// Fill behind toolbar leading icons (matches [TilawaIconActionButton] on vellum).
  static Color leadingControlBackground(ColorScheme scheme) => scheme.surface;

  static BorderRadius toolbarIconBorderRadius(ThemeData theme) {
    return BorderRadius.circular(
      theme.componentTokens.iconActionButton.borderRadius,
    );
  }

  /// 48×48 leading icon with surface fill and ink splash clipped to [borderRadius].
  static Widget framedToolbarIcon({
    required BuildContext context,
    required Widget icon,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    final ThemeData theme = Theme.of(context);
    final TilawaDesignTokens tokens = theme.tokens;
    final double hit = tokens.minInteractiveDimension;
    final BorderRadius radius = toolbarIconBorderRadius(theme);

    Widget body = SizedBox(
      width: hit,
      height: hit,
      child: Material(
        color: leadingControlBackground(theme.colorScheme),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: Center(child: icon),
        ),
      ),
    );
    if (tooltip != null) {
      body = Tooltip(message: tooltip, child: body);
    }
    return body;
  }

  /// [framedToolbarIcon] plus start-edge inset, centered in the toolbar slot.
  static Widget edgePaddedLeadingIcon({
    required BuildContext context,
    required Widget icon,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    final TilawaDesignTokens tokens = Theme.of(context).tokens;
    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: tokens.appBarEdgePadding),
        child: framedToolbarIcon(
          context: context,
          icon: icon,
          onPressed: onPressed,
          tooltip: tooltip,
        ),
      ),
    );
  }

  /// Leading control with the same screen-edge inset as [appBarActionsPadding].
  static ({
    Widget? leading,
    bool automaticallyImplyLeading,
    double? leadingWidth,
  })
  resolveLeading({
    required BuildContext context,
    required Widget? leading,
    required bool automaticallyImplyLeading,
    required TilawaDesignTokens tokens,
  }) {
    final double hit = tokens.minInteractiveDimension;
    final double width = tokens.appBarEdgePadding + hit;

    Widget? resolved = leading;
    var implyLeading = automaticallyImplyLeading;

    if (resolved == null && automaticallyImplyLeading) {
      final ThemeData theme = Theme.of(context);
      final ScaffoldState? scaffold = Scaffold.maybeOf(context);
      final ModalRoute<dynamic>? route = ModalRoute.of(context);
      final MaterialLocalizations l10n = MaterialLocalizations.of(context);
      if (scaffold?.hasDrawer ?? false) {
        resolved = edgePaddedLeadingIcon(
          context: context,
          icon: Icon(
            Icons.menu_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: scaffold!.openDrawer,
          tooltip: l10n.openAppDrawerTooltip,
        );
        implyLeading = false;
      } else if (route?.impliesAppBarDismissal ?? false) {
        resolved = edgePaddedLeadingIcon(
          context: context,
          icon: IconTheme(
            data: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
            child: const BackButtonIcon(),
          ),
          onPressed: () => Navigator.maybePop(context),
          tooltip: l10n.backButtonTooltip,
        );
        implyLeading = false;
      }
    } else if (resolved != null) {
      // Custom leading must ship its own chrome (see app [TilawaBackButton]).
      implyLeading = false;
    }

    return (
      leading: resolved,
      automaticallyImplyLeading: implyLeading,
      leadingWidth: resolved != null ? width : null,
    );
  }
}

/// Standard scaffold app bar for Tilawa feature screens.
class TilawaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TilawaAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.surface = TilawaAppBarSurface.vellum,
    this.showBottomHairline = true,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final TilawaAppBarSurface surface;
  final bool showBottomHairline;

  @override
  Size get preferredSize {
    final double bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaDesignTokens tokens = theme.tokens;
    final Color backgroundColor = TilawaAppBarChrome.backgroundColor(
      colorScheme,
      surface,
    );
    final Color foregroundColor = TilawaAppBarChrome.foregroundColor(
      colorScheme,
    );

    final Widget? resolvedTitle =
        titleWidget ??
        (title != null
            ? Text(title!, style: TilawaAppBarChrome.titleTextStyle(theme))
            : null);
    final ({
      Widget? leading,
      bool automaticallyImplyLeading,
      double? leadingWidth,
    })
    leadingConfig = TilawaAppBarChrome.resolveLeading(
      context: context,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      tokens: tokens,
    );

    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: leadingConfig.automaticallyImplyLeading,
      leading: leadingConfig.leading,
      leadingWidth: leadingConfig.leadingWidth,
      actions: TilawaAppBarChrome.spacedActions(actions, tokens),
      actionsPadding: tokens.appBarActionsPadding,
      bottom: bottom,
      shape: showBottomHairline
          ? TilawaAppBarChrome.bottomHairline(colorScheme, tokens)
          : null,
      title: resolvedTitle,
    );
  }
}

/// Pinned (or floating) app bar sliver with the same chrome as [TilawaAppBar].
class TilawaSliverAppBar extends StatelessWidget {
  const TilawaSliverAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.stretch = false,
    this.expandedHeight,
    this.surface = TilawaAppBarSurface.vellum,
    this.showBottomHairline = true,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final bool pinned;
  final bool floating;
  final bool snap;
  final bool stretch;
  final double? expandedHeight;
  final TilawaAppBarSurface surface;
  final bool showBottomHairline;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TilawaDesignTokens tokens = theme.tokens;
    final Color backgroundColor = TilawaAppBarChrome.backgroundColor(
      colorScheme,
      surface,
    );
    final Color foregroundColor = TilawaAppBarChrome.foregroundColor(
      colorScheme,
    );

    final Widget? resolvedTitle =
        titleWidget ??
        (title != null
            ? Text(title!, style: TilawaAppBarChrome.titleTextStyle(theme))
            : null);
    final ({
      Widget? leading,
      bool automaticallyImplyLeading,
      double? leadingWidth,
    })
    leadingConfig = TilawaAppBarChrome.resolveLeading(
      context: context,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      tokens: tokens,
    );

    return SliverAppBar(
      pinned: pinned,
      floating: floating,
      snap: snap,
      stretch: stretch,
      expandedHeight: expandedHeight,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: leadingConfig.automaticallyImplyLeading,
      leading: leadingConfig.leading,
      leadingWidth: leadingConfig.leadingWidth,
      actions: TilawaAppBarChrome.spacedActions(actions, tokens),
      actionsPadding: tokens.appBarActionsPadding,
      bottom: bottom,
      shape: showBottomHairline
          ? TilawaAppBarChrome.bottomHairline(colorScheme, tokens)
          : null,
      title: resolvedTitle,
    );
  }
}
