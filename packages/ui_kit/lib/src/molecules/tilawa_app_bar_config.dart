import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../atoms/tilawa_icon_button.dart';
import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/tilawa_icons.dart';
import '../foundation/tilawa_type_scale.dart';

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
  /// Pinterest-style catalog screens (browsing/list surfaces).
  static const TilawaAppBarSurface surface = TilawaAppBarSurface.parchment;

  /// Left-aligned titles in catalog chrome.
  static const bool centerTitle = false;
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

  /// Insets for [TilawaCatalogAppBar] and catalog search slots.
  static EdgeInsets catalogChromePadding(
    MeMuslimDesignTokens tokens, {
    bool includeBottomInset = true,
  }) {
    return EdgeInsets.fromLTRB(
      tokens.spaceMedium,
      tokens.spaceSmall,
      tokens.spaceMedium,
      includeBottomInset ? tokens.spaceSmall : 0,
    );
  }

  /// Catalog chrome padding with status-bar inset folded into the top inset.
  static EdgeInsets catalogChromePaddingWithStatusBar(
    BuildContext context,
    MeMuslimDesignTokens tokens, {
    bool includeBottomInset = true,
  }) {
    return catalogChromePadding(
      tokens,
      includeBottomInset: includeBottomInset,
    ).copyWith(
      top: _catalogStatusBarTopInset(context) + tokens.spaceSmall,
    );
  }

  static double _catalogStatusBarTopInset(BuildContext context) {
    return MediaQuery.paddingOf(context).top;
  }

  static double _catalogChromeHeight(BuildContext context, double raw) {
    return tilawaLayoutHeight(context, raw);
  }

  /// Bold [titleLarge] row height (matches catalog app bar title).
  static double catalogTitleRowHeight(
    BuildContext context, {
    String? title,
    double? titleMaxWidth,
    bool hasLeading = true,
    int actionCount = 0,
    bool centerTitle = false,
    double? titleBlockHeight,
    bool enforceMinTouchTarget = true,
  }) {
    if (titleBlockHeight != null) {
      return math.max(
        titleBlockHeight,
        enforceMinTouchTarget ? kMeMuslimMinInteractiveDimension : 0,
      );
    }

    final ThemeData theme = Theme.of(context);
    final TextStyle? titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final double resolvedMaxWidth =
        titleMaxWidth ??
        (title != null
            ? catalogTitleAreaWidth(
                context,
                hasLeading: hasLeading,
                actionCount: actionCount,
                centerTitle: centerTitle,
              )
            : 0);

    final double titleHeight = title != null && resolvedMaxWidth > 0
        ? tilawaMeasureTextHeight(
            context: context,
            style: titleStyle,
            text: title,
            maxWidth: resolvedMaxWidth,
          )
        : tilawaMeasureTextHeight(context: context, style: titleStyle);

    final double minHeight = enforceMinTouchTarget
        ? kMeMuslimMinInteractiveDimension
        : 0;

    return math.max(titleHeight, minHeight) +
        (MediaQuery.textScalerOf(context).scale(1.0) > 1.0
            ? 1.0 / MediaQuery.devicePixelRatioOf(context)
            : 0);
  }

  /// Title area width inside catalog chrome (title row [Expanded] slot).
  static double catalogTitleAreaWidth(
    BuildContext context, {
    bool hasLeading = true,
    int actionCount = 0,
    bool centerTitle = false,
  }) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final EdgeInsets padding = catalogChromePadding(tokens);
    var width = MediaQuery.sizeOf(context).width - padding.horizontal;
    if (centerTitle) {
      width -= tokens.minInteractiveDimension * 2;
      if (actionCount > 0) {
        width -=
            (actionCount - 1) * tokens.minInteractiveDimension +
            math.max(0, actionCount - 1) * tokens.spaceSmall;
      }
      return math.max(0, width);
    }
    if (hasLeading) {
      width -= tokens.minInteractiveDimension + tokens.spaceSmall;
    }
    if (actionCount > 0) {
      width -= actionCount * tokens.minInteractiveDimension;
      if (actionCount > 1) {
        width -= (actionCount - 1) * tokens.spaceSmall;
      }
    }
    return math.max(0, width);
  }

  /// Title-only catalog header (Settings, Favorites, Athkar).
  static double catalogTitleOnlyHeight(
    BuildContext context, {
    String? title,
    bool hasLeading = true,
    int actionCount = 0,
    bool centerTitle = false,
    double? titleBlockHeight,
  }) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final EdgeInsets padding = catalogChromePadding(
      tokens,
      includeBottomInset: false,
    );
    final bool enforceMinTouchTarget =
        hasLeading || actionCount > 0 || centerTitle;
    final double raw =
        padding.top +
        padding.bottom +
        catalogTitleRowHeight(
          context,
          title: title,
          hasLeading: hasLeading,
          actionCount: actionCount,
          centerTitle: centerTitle,
          titleBlockHeight: titleBlockHeight,
          enforceMinTouchTarget: enforceMinTouchTarget,
        );
    return _catalogChromeHeight(context, raw);
  }

  /// Title + one catalog search field (Bookmarks, History, Playlists).
  static double catalogTitleAndSearchHeight(
    BuildContext context, {
    String? title,
    bool hasLeading = true,
    int actionCount = 0,
    bool centerTitle = false,
    double? titleBlockHeight,
  }) {
    final double searchHeight = Theme.of(
      context,
    ).componentTokens.searchField.height;
    return catalogTitleAndContentHeight(
      context,
      contentHeight: searchHeight,
      title: title,
      hasLeading: hasLeading,
      actionCount: actionCount,
      centerTitle: centerTitle,
      titleBlockHeight: titleBlockHeight,
    );
  }

  /// Title + arbitrary bottom block (filter row, segments, etc.).
  static double catalogTitleAndContentHeight(
    BuildContext context, {
    required double contentHeight,
    String? title,
    bool hasLeading = true,
    int actionCount = 0,
    bool centerTitle = false,
    double? titleBlockHeight,
  }) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final EdgeInsets padding = catalogChromePadding(tokens);
    final double raw =
        padding.vertical +
        catalogTitleRowHeight(
          context,
          title: title,
          hasLeading: hasLeading,
          actionCount: actionCount,
          centerTitle: centerTitle,
          titleBlockHeight: titleBlockHeight,
        ) +
        tokens.spaceSmall +
        contentHeight;
    return _catalogChromeHeight(context, raw);
  }

  /// Title + search + min-height filter row in catalog headers.
  static double catalogTitleSearchAndFilterRowHeight(
    BuildContext context, {
    String? title,
    bool hasLeading = true,
    int actionCount = 0,
  }) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final double searchHeight = Theme.of(
      context,
    ).componentTokens.searchField.height;
    final double contentHeight =
        searchHeight + tokens.spaceSmall + kMeMuslimMinInteractiveDimension;
    return catalogTitleAndContentHeight(
      context,
      contentHeight: contentHeight,
      title: title,
      hasLeading: hasLeading,
      actionCount: actionCount,
    );
  }

  /// Search (+ optional trailing control) without a title row.
  static double catalogSearchRowHeight(
    BuildContext context, {
    double trailingMinHeight = kMeMuslimMinInteractiveDimension,
  }) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final double searchHeight = Theme.of(
      context,
    ).componentTokens.searchField.height;
    final double rowHeight = math.max(searchHeight, trailingMinHeight);
    final EdgeInsets padding = catalogChromePadding(tokens);
    final double raw = padding.vertical + rowHeight;
    return _catalogChromeHeight(context, raw);
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
    MeMuslimDesignTokens tokens, {
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
    MeMuslimDesignTokens tokens,
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
    MeMuslimDesignTokens tokens,
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
    final tokens = theme.tokens;
    return BorderRadius.circular(
      tokens.resolveRadius(
        family: TilawaRadiusFamily.pill,
        height: tokens.minInteractiveDimension,
      ),
    );
  }

  /// 48×48 leading icon with toolbar fill and ink splash clipped to radius.
  static Widget framedToolbarIcon({
    required BuildContext context,
    required Widget icon,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    final Widget body = TilawaIconButton(
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
    );

    return body;
  }

  /// [framedToolbarIcon] plus start-edge inset, centered in the toolbar slot.
  static Widget edgePaddedLeadingIcon({
    required BuildContext context,
    required Widget icon,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
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

  /// Back control for [TilawaCatalogAppBar] title rows (no extra start inset).
  static Widget catalogBackButton({
    required BuildContext context,
    VoidCallback? onPressed,
    Color? iconColor,
  }) {
    final ThemeData theme = Theme.of(context);
    final Color color = iconColor ?? theme.colorScheme.onSurfaceVariant;

    return framedToolbarIcon(
      context: context,
      icon: IconTheme(
        data: IconThemeData(color: color),
        child: const BackButtonIcon(),
      ),
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }

  /// Leading widget for catalog title rows (drawer menu or back on push).
  ///
  /// Prefer [onBackPressed] when the screen uses GoRouter (`context.pop()`).
  static Widget? resolveCatalogRowLeading(
    BuildContext context, {
    Widget? leading,
    required bool automaticallyImplyLeading,
    VoidCallback? onBackPressed,
  }) {
    if (leading != null) {
      return leading;
    }
    if (!automaticallyImplyLeading) {
      return null;
    }

    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final ({
      Widget? leading,
      bool automaticallyImplyLeading,
      double? leadingWidth,
    })
    toolbarLeading = resolveLeading(
      context: context,
      leading: null,
      automaticallyImplyLeading: true,
      tokens: tokens,
    );

    if (toolbarLeading.leading == null) {
      return null;
    }

    final ScaffoldState? scaffold = Scaffold.maybeOf(context);
    if (scaffold?.hasDrawer ?? false) {
      return toolbarLeading.leading;
    }

    return catalogBackButton(
      context: context,
      onPressed: onBackPressed,
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
    required MeMuslimDesignTokens tokens,
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
            TilawaIcons.menu,
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
