import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// A custom back button that uses GoRouter's `context.pop()` instead of
/// Flutter's default `Navigator.maybePop()`.
///
/// Includes the same framed chrome as [TilawaAppBar] leading controls.
class TilawaBackButton extends StatelessWidget {
  const TilawaBackButton({
    super.key,
    this.color,
    this.onPressed,
    this.compact = false,
  });

  final Color? color;
  final VoidCallback? onPressed;

  /// When true, omits toolbar start inset (for [TilawaCatalogAppBar] rows).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color iconColor = color ?? theme.colorScheme.onSurfaceVariant;
    void pop() {
      if (onPressed != null) {
        onPressed!();
      } else if (context.canPop()) {
        context.pop();
      }
    }

    if (compact) {
      return TilawaAppBarChrome.framedToolbarIcon(
        context: context,
        icon: IconTheme(
          data: IconThemeData(color: iconColor),
          child: const BackButtonIcon(),
        ),
        onPressed: pop,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      );
    }

    return TilawaAppBarChrome.edgePaddedLeadingIcon(
      context: context,
      icon: IconTheme(
        data: IconThemeData(color: iconColor),
        child: const BackButtonIcon(),
      ),
      onPressed: pop,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
}
