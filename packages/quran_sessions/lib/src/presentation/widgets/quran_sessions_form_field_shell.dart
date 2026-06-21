import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Temporary compatibility wrapper — delegates all field chrome to ui_kit SSOT.
///
/// Prefer [TilawaFieldShell] and [TilawaInputStyle] directly in new code.
/// This type will be removed once call sites migrate to kit atoms.
class QuranSessionsFormFieldShell extends StatelessWidget {
  const QuranSessionsFormFieldShell({
    super.key,
    required this.child,
    this.prefixIcon,
    this.hintText,
    this.errorText,
    this.onTap,
    this.semanticLabel,
    this.isEmpty = false,
  });

  final Widget child;
  final IconData? prefixIcon;
  final String? hintText;
  final String? errorText;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool isEmpty;

  /// Delegates to [TilawaInputStyle.decoration].
  @Deprecated('Use context.inputStyle().decoration() instead.')
  static InputDecoration decoration(
    BuildContext context, {
    IconData? prefixIcon,
    String? hintText,
    String? errorText,
    bool alignLabelWithHint = false,
  }) {
    return context.inputStyle().decoration(
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      hintText: hintText,
      errorText: errorText,
      alignLabelWithHint: alignLabelWithHint,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TilawaFieldShell.decorator(
      decoration: decoration(
        context,
        prefixIcon: prefixIcon,
        hintText: onTap == null ? hintText : null,
        errorText: errorText,
      ),
      onTap: onTap,
      isEmpty: isEmpty,
      semanticLabel: semanticLabel,
      child: child,
    );
  }
}
