import 'package:flutter/material.dart';

import '../foundation/design_tokens.dart';
import 'tilawa_app_bar_config.dart';

export 'tilawa_app_bar_config.dart';

/// Standard scaffold app bar for Tilawa feature screens.
///
/// Leading and [TilawaIconActionButton] actions inherit toolbar control fill
/// from [TilawaAppBarScope]. Defaults live in [TilawaAppBarConfig]; set
/// [showLeadingControlBackground] or [showActionControlBackground] to `false`
/// to disable the pill fill on this bar.
class TilawaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TilawaAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = TilawaAppBarConfig.centerTitle,
    this.automaticallyImplyLeading =
        TilawaAppBarConfig.automaticallyImplyLeading,
    this.surface = TilawaAppBarConfig.surface,
    this.showLeadingControlBackground =
        TilawaAppBarConfig.showLeadingControlBackground,
    this.showActionControlBackground =
        TilawaAppBarConfig.showActionControlBackground,
    this.showBottomHairline = TilawaAppBarConfig.showBottomHairline,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final TilawaAppBarSurface surface;
  final bool showLeadingControlBackground;
  final bool showActionControlBackground;
  final bool showBottomHairline;

  @override
  Size get preferredSize {
    final double bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    return TilawaAppBarScope(
      surface: surface,
      showLeadingControlBackground: showLeadingControlBackground,
      showActionControlBackground: showActionControlBackground,
      child: _TilawaAppBarBody(
        title: title,
        titleWidget: titleWidget,
        leading: leading,
        actions: actions,
        bottom: bottom,
        centerTitle: centerTitle,
        automaticallyImplyLeading: automaticallyImplyLeading,
        surface: surface,
        showBottomHairline: showBottomHairline,
      ),
    );
  }
}

class _TilawaAppBarBody extends StatelessWidget {
  const _TilawaAppBarBody({
    required this.surface,
    required this.showBottomHairline,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = TilawaAppBarConfig.centerTitle,
    this.automaticallyImplyLeading =
        TilawaAppBarConfig.automaticallyImplyLeading,
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
    this.centerTitle = TilawaAppBarConfig.centerTitle,
    this.automaticallyImplyLeading =
        TilawaAppBarConfig.automaticallyImplyLeading,
    this.pinned = TilawaAppBarConfig.pinned,
    this.floating = TilawaAppBarConfig.floating,
    this.snap = TilawaAppBarConfig.snap,
    this.stretch = TilawaAppBarConfig.stretch,
    this.expandedHeight,
    this.surface = TilawaAppBarConfig.surface,
    this.showLeadingControlBackground =
        TilawaAppBarConfig.showLeadingControlBackground,
    this.showActionControlBackground =
        TilawaAppBarConfig.showActionControlBackground,
    this.showBottomHairline = TilawaAppBarConfig.showBottomHairline,
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
  final bool showLeadingControlBackground;
  final bool showActionControlBackground;
  final bool showBottomHairline;

  @override
  Widget build(BuildContext context) {
    return TilawaAppBarScope(
      surface: surface,
      showLeadingControlBackground: showLeadingControlBackground,
      showActionControlBackground: showActionControlBackground,
      child: _TilawaSliverAppBarBody(
        title: title,
        titleWidget: titleWidget,
        leading: leading,
        actions: actions,
        bottom: bottom,
        centerTitle: centerTitle,
        automaticallyImplyLeading: automaticallyImplyLeading,
        pinned: pinned,
        floating: floating,
        snap: snap,
        stretch: stretch,
        expandedHeight: expandedHeight,
        surface: surface,
        showBottomHairline: showBottomHairline,
      ),
    );
  }
}

class _TilawaSliverAppBarBody extends StatelessWidget {
  const _TilawaSliverAppBarBody({
    required this.surface,
    required this.showBottomHairline,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = TilawaAppBarConfig.centerTitle,
    this.automaticallyImplyLeading =
        TilawaAppBarConfig.automaticallyImplyLeading,
    this.pinned = TilawaAppBarConfig.pinned,
    this.floating = TilawaAppBarConfig.floating,
    this.snap = TilawaAppBarConfig.snap,
    this.stretch = TilawaAppBarConfig.stretch,
    this.expandedHeight,
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
