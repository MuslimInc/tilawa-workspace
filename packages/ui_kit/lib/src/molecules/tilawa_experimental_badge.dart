import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';
import '../foundation/tilawa_interactive_surface.dart';

/// A pill-shaped badge indicating a feature is experimental or in preview.
///
/// Place as a trailing widget on settings tiles, section headers, or feature
/// cards. Do not use inside the Quran reader or during active worship flows.
///
/// The [label] should be supplied from `context.l10n.experimentalBadgeLabel`
/// at the call site so it respects the app's active locale.
class TilawaExperimentalBadge extends StatelessWidget {
  const TilawaExperimentalBadge({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  });

  final String label;

  /// Optional leading icon rendered at [TilawaExperimentalBadgeTokens.iconSize].
  final IconData? icon;

  /// When provided the badge becomes tappable; an [InkWell] with a minimum
  /// 48 dp hit target wraps the pill.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.experimentalBadge;

    final pill = Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: tokens.padding,
        decoration: BoxDecoration(
          color: tokens.backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: tokens.borderColor,
            width: tokens.borderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: tokens.iconSize, color: tokens.foregroundColor),
              SizedBox(width: tokens.iconGap),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.foregroundColor,
                fontWeight: tokens.fontWeight,
                letterSpacing: tokens.letterSpacing,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return pill;

    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: TilawaInteractiveSurface(
          onTap: onTap,
          button: false,
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            child: Center(widthFactor: 1, child: pill),
          ),
        ),
      ),
    );
  }
}
