import 'package:flutter/material.dart';

import '../foundation/tilawa_field_shell.dart';
import '../foundation/tilawa_input_style.dart';

/// A tappable read-only field with the same chrome as [TilawaTextField].
///
/// Use for date pickers, time pickers, and other selectors that show a value
/// and open a platform dialog on tap.
class TilawaReadOnlyField extends StatelessWidget {
  const TilawaReadOnlyField({
    super.key,
    required this.onTap,
    required this.child,
    this.prefixIcon,
    this.hintText,
    this.errorText,
    this.semanticLabel,
    this.isEmpty = false,
  });

  /// Opens the selector (date picker, time picker, etc.).
  final VoidCallback onTap;

  /// The displayed value or placeholder content.
  final Widget child;

  /// Leading icon (rendered on the right under RTL automatically).
  final IconData? prefixIcon;

  /// Placeholder for [InputDecorator] when [isEmpty] is true.
  final String? hintText;

  final String? errorText;
  final String? semanticLabel;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return TilawaFieldShell.decorator(
      decoration: context.inputStyle().decoration(
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        hintText: hintText,
        errorText: errorText,
      ),
      onTap: onTap,
      isEmpty: isEmpty,
      semanticLabel: semanticLabel,
      child: child,
    );
  }
}
