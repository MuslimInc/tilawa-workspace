import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// A custom back button that uses GoRouter's `context.pop()` instead of
/// Flutter's default `Navigator.maybePop()`.
///
/// Includes the same framed chrome as [TilawaAppBar] leading controls.
class TilawaBackButton extends StatelessWidget {
  const TilawaBackButton({super.key, this.color, this.onPressed});

  final Color? color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color iconColor = color ?? theme.colorScheme.onSurfaceVariant;

    return TilawaAppBarChrome.edgePaddedLeadingIcon(
      context: context,
      icon: IconTheme(
        data: IconThemeData(color: iconColor),
        child: const BackButtonIcon(),
      ),
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else if (context.canPop()) {
          context.pop();
        }
      },
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
}
