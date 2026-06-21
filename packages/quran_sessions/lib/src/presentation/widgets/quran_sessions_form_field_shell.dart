import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// A single, design-system-compliant shell for every form field on the Quran
/// Sessions screens.
///
/// All visual values (border radius, padding, border colours, focus colour,
/// text style, min hit-target height) come from [TilawaDesignTokens] and the
/// ambient [ThemeData] — nothing is hardcoded. This guarantees the date-of-birth
/// field, the country/city selectors, and the teacher-application selectors all
/// render with the exact same shape, matching [TilawaTextField].
///
/// Two ways to use it:
/// - As a **widget** wrapping a custom child (a tappable value display such as
///   the DOB field, or a `DropdownButton`).
/// - Via [decoration], to feed the identical [InputDecoration] to widgets that
///   own their own [InputDecorator] ([TextFormField], [DropdownButtonFormField]).
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

  /// The field content — e.g. a value/hint [Text] for a tappable display field,
  /// or a `DropdownButtonHideUnderline`-wrapped `DropdownButton`.
  final Widget child;

  /// Leading icon (rendered on the right in RTL automatically).
  final IconData? prefixIcon;

  final String? hintText;
  final String? errorText;

  /// When non-null the whole field is tappable (used by the date picker field).
  final VoidCallback? onTap;

  final String? semanticLabel;

  /// Whether the field currently shows the hint rather than a value — drives the
  /// hint styling for tappable display fields.
  final bool isEmpty;

  /// The canonical field decoration. Shared by [TextFormField] /
  /// [DropdownButtonFormField] so every field matches without duplicating
  /// token lookups.
  static InputDecoration decoration(
    BuildContext context, {
    IconData? prefixIcon,
    String? hintText,
    String? errorText,
    bool alignLabelWithHint = false,
  }) {
    final tokens = Theme.of(context).tokens;
    return InputDecoration(
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      hintText: hintText,
      errorText: errorText,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(family: TilawaRadiusFamily.chrome),
        ),
      ),
      contentPadding: EdgeInsets.all(tokens.spaceMedium),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final radius = tokens.resolveRadius(family: TilawaRadiusFamily.chrome);

    final field = ConstrainedBox(
      // Keep the hit target at least 48 dp regardless of content.
      constraints: BoxConstraints(minHeight: tokens.minInteractiveDimension),
      child: InputDecorator(
        decoration: decoration(
          context,
          prefixIcon: prefixIcon,
          hintText: onTap == null ? hintText : null,
          errorText: errorText,
        ),
        isEmpty: isEmpty,
        child: child,
      ),
    );

    if (onTap == null) {
      return semanticLabel == null
          ? field
          : Semantics(label: semanticLabel, child: field);
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: field,
      ),
    );
  }
}
