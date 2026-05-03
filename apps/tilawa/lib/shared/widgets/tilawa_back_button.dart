import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A custom back button that uses GoRouter's `context.pop()` instead of
/// Flutter's default `Navigator.maybePop()`.
///
/// This ensures consistent declarative routing behavior, deep-link safety,
/// and proper web URL synchronization.
class TilawaBackButton extends StatelessWidget {
  const TilawaBackButton({super.key, this.color, this.onPressed});

  final Color? color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const BackButtonIcon(),
      color: color,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else if (context.canPop()) {
          context.pop();
        }
      },
    );
  }
}
