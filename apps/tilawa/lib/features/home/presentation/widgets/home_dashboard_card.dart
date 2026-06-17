import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Home dashboard surface — [TilawaCard] with shadow/fill only (no hairline).
class HomeDashboardCard extends StatelessWidget {
  const HomeDashboardCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.surface = TilawaCardSurface.raised,
    this.onTap,
    this.splashColor,
    this.highlightColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? borderRadius;
  final TilawaCardSurface surface;
  final VoidCallback? onTap;
  final Color? splashColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTokens = theme.componentTokens.homeDashboardCard;
    final Color resolvedBackground =
        backgroundColor ?? cardTokens.backgroundColor;

    return TilawaCard(
      padding: padding,
      backgroundColor: resolvedBackground,
      borderRadius: borderRadius,
      borderWidth: 0,
      surface: surface,
      onTap: onTap,
      splashColor: splashColor ?? cardTokens.splashColor,
      highlightColor: highlightColor ?? cardTokens.highlightColor,
      child: child,
    );
  }
}
