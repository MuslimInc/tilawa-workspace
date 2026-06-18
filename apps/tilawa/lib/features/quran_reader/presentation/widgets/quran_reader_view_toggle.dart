import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Toggles between Mushaf pages and the Behance-style ayah list reader.
class QuranReaderViewToggle extends StatelessWidget {
  const QuranReaderViewToggle({
    super.key,
    required this.currentMode,
    required this.onPressed,
    this.onDarkBackground = false,
  });

  final QuranReaderViewMode currentMode;
  final VoidCallback onPressed;

  /// When true, uses a light icon treatment for the Mushaf overlay.
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool switchToAyahList = currentMode == QuranReaderViewMode.mushaf;
    final IconData icon = switchToAyahList
        ? Icons.view_list_rounded
        : Icons.menu_book_rounded;
    final String label = switchToAyahList
        ? context.l10n.quranSwitchToAyahList
        : context.l10n.quranSwitchToMushaf;

    if (onDarkBackground) {
      return Padding(
        padding: EdgeInsets.all(theme.tokens.spaceSmall),
        child: Material(
          color: colorScheme.scrim.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(theme.tokens.radiusLarge),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(theme.tokens.radiusLarge),
            child: Semantics(
              button: true,
              label: label,
              child: Padding(
                padding: EdgeInsets.all(theme.tokens.spaceSmall),
                child: Icon(
                  icon,
                  color: colorScheme.onPrimary,
                  size: theme.tokens.iconSizeMedium,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return TilawaIconActionButton(
      icon: icon,
      tooltip: label,
      semanticLabel: label,
      onTap: onPressed,
    );
  }
}
