import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Canonical content-width kinds. Each maps to a `contentMaxWidth*` token on
/// [TilawaDesignTokens].
enum TilawaContentKind {
  /// Quran reader body — `contentMaxWidthReader` (720).
  reader,

  /// Settings, dialogs, auth, sheets — `contentMaxWidthForm` (560).
  form,

  /// Share composers, galleries — `contentMaxWidthMedia` (1200).
  media,

  /// Settings detail pages — `contentMaxWidthSettings` (760).
  settings,
}

/// Layout primitive that caps a subtree's horizontal extent and centers it.
///
/// Use this to prevent text and cards from stretching edge-to-edge on tablets
/// and foldables. Pass a [TilawaContentKind] to pick the token-backed max
/// width, or override with [maxWidth] for one-off cases.
///
/// This is a Foundation / Layout Primitive, not a visual component — it has
/// no background, padding, border, or other affordance. Compose it with
/// token-driven padding at the call site.
class TilawaContentBounds extends StatelessWidget {
  const TilawaContentBounds({
    super.key,
    required this.child,
    this.kind = TilawaContentKind.form,
    this.maxWidth,
    this.alignment = .topCenter,
  });

  final Widget child;

  /// Token-backed content-width kind. Ignored when [maxWidth] is non-null.
  final TilawaContentKind kind;

  /// Explicit override. When set, wins over [kind].
  final double? maxWidth;

  /// Alignment inside the available width when the child is narrower than
  /// the parent constraints. Defaults to [Alignment.topCenter] to keep
  /// content centered horizontally while respecting vertical scrolling.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final resolved = maxWidth ?? resolveMaxWidth(context, kind);
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: resolved),
        child: child,
      ),
    );
  }

  static double resolveMaxWidth(BuildContext context, TilawaContentKind kind) {
    final tokens = Theme.of(context).extension<TilawaDesignTokens>()!;
    switch (kind) {
      case TilawaContentKind.reader:
        return tokens.contentMaxWidthReader;
      case TilawaContentKind.form:
        return tokens.contentMaxWidthForm;
      case TilawaContentKind.media:
        return tokens.contentMaxWidthMedia;
      case TilawaContentKind.settings:
        return tokens.contentMaxWidthSettings;
    }
  }
}
