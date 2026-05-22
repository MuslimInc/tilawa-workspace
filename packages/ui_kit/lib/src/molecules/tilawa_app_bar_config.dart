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

/// Default constructor values for Tilawa app bars.
abstract final class TilawaAppBarConfig {
  static const TilawaAppBarSurface surface = TilawaAppBarSurface.vellum;
  static const bool centerTitle = true;
  static const bool automaticallyImplyLeading = true;
  static const bool showLeadingControlBackground = false;
  static const bool showActionControlBackground = false;
  /// Hairline under the bar — primary chrome separation (see brand §5).
  static const bool showBottomHairline = true;

  /// Drop shadow under the bar. Off by default; vellum uses surface tier +
  /// [showBottomHairline] instead of Material elevation (brand §5).
  static const bool showElevationShadow = false;

  /// Material [AppBar.elevation] when [showElevationShadow] is true.
  static const double elevation = 1;

  /// Material [AppBar.scrolledUnderElevation] when [showElevationShadow] is true.
  static const double scrolledUnderElevation = 1;

  static const bool pinned = true;
  static const bool floating = false;
  static const bool snap = false;
  static const bool stretch = false;

  /// Default [AppBar.bottom] height for a single [TilawaSearchField] row.
  static double searchBottomHeight(ThemeData theme) {
    return theme.componentTokens.searchField.height +
        theme.tokens.spaceMedium * 2;
  }
}

/// Toolbar chrome policy for descendants of [TilawaAppBar] /
/// [TilawaSliverAppBar].
///
/// [TilawaIconActionButton] and [TilawaAppBarChrome.framedToolbarIcon] read
/// this scope when [TilawaIconActionButton.backgroundColor] is omitted.
class TilawaAppBarScope extends InheritedWidget {
  const TilawaAppBarScope({
    super.key,
    required this.surface,
    required this.showLeadingControlBackground,
    required this.showActionControlBackground,
    required super.child,
  });

  final TilawaAppBarSurface surface;
  final bool showLeadingControlBackground;
  final bool showActionControlBackground;

  /// Resolved fill for toolbar leading icons.
  Color leadingControlFillColor(ColorScheme scheme) =>
      TilawaAppBarChrome.toolbarControlBackground(
        scheme,
        surface,
        enabled: showLeadingControlBackground,
      );

  /// Resolved fill for toolbar trailing icon actions.
  Color actionControlFillColor(ColorScheme scheme) =>
      TilawaAppBarChrome.toolbarControlBackground(
        scheme,
        surface,
        enabled: showActionControlBackground,
      );

  static TilawaAppBarScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TilawaAppBarScope>();

  @override
  bool updateShouldNotify(TilawaAppBarScope oldWidget) =>
      surface != oldWidget.surface ||
      showLeadingControlBackground != oldWidget.showLeadingControlBackground ||
      showActionControlBackground != oldWidget.showActionControlBackground;
}

/// Colors, layout, and widgets for Tilawa app bar chrome.
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

  /// Optional drop shadow ([ColorScheme.shadow] × [opacityShadow]).
  ///
  /// Prefer [showBottomHairline]; elevation is opt-in for rare scroll chrome.
  static Color elevationShadowColor(
    ColorScheme scheme,
    TilawaDesignTokens tokens, {
    bool enabled = true,
  }) {
    if (!enabled) {
      return Colors.transparent;
    }
    return scheme.shadow.withValues(alpha: tokens.opacityShadow);
  }

  static double elevation({bool enabled = true}) {
    if (!enabled) {
      return 0;
    }
    return TilawaAppBarConfig.elevation;
  }

  static double scrolledUnderElevation({bool enabled = true}) {
    if (!enabled) {
      return 0;
    }
    return TilawaAppBarConfig.scrolledUnderElevation;
  }

  static ShapeBorder bottomHairline(
    ColorScheme scheme,
    TilawaDesignTokens tokens,
  ) {
    return RoundedRectangleBorder(
      side: BorderSide(
        color: scheme.outlineVariant.withValues(
          alpha: tokens.opacitySubtle * 2.5,
        ),
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

  /// Fill behind toolbar leading and action controls.
  ///
  /// * [vellum] — [ColorScheme.surface] pill on [surfaceContainerHigh] header.
  /// * [parchment] — [ColorScheme.surfaceContainerHigh] pill on [surface].
  /// When [enabled] is false, returns [Colors.transparent].
  static Color toolbarControlBackground(
    ColorScheme scheme,
    TilawaAppBarSurface surface, {
    required bool enabled,
  }) {
    if (!enabled) {
      return Colors.transparent;
    }
    return switch (surface) {
      TilawaAppBarSurface.vellum => scheme.surface,
      TilawaAppBarSurface.parchment => scheme.surfaceContainerHigh,
    };
  }

  static BorderRadius toolbarIconBorderRadius(ThemeData theme) {
    return BorderRadius.circular(
      theme.componentTokens.iconActionButton.borderRadius,
    );
  }

  /// 48×48 leading icon with toolbar fill and ink splash clipped to radius.
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
    final TilawaAppBarScope? scope = TilawaAppBarScope.maybeOf(context);
    final Color fill = scope != null
        ? scope.leadingControlFillColor(theme.colorScheme)
        : toolbarControlBackground(
            theme.colorScheme,
            TilawaAppBarConfig.surface,
            enabled: TilawaAppBarConfig.showLeadingControlBackground,
          );

    Widget body = SizedBox(
      width: hit,
      height: hit,
      child: Material(
        color: fill,
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
