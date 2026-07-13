import 'package:flutter/material.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';

/// A reusable action button Atom for the Quran Reader navigation.
class NavActionButton extends StatelessWidget {
  const NavActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final QuranReaderTheme readerTheme = QuranReaderTheme.of(context);
    final PageNavigationBarTheme navTheme = PageNavigationBarTheme.of(context);

    final Color readerPrimary = readerTheme.primaryColor;

    final Color effectiveBg =
        backgroundColor ??
        readerPrimary.withValues(
          alpha: isDark
              ? navTheme.actionButtonBgAlphaDark
              : navTheme.actionButtonBgAlphaLight,
        );
    final Color effectiveFg = foregroundColor ?? readerPrimary;
    final Color effectiveBorder =
        borderColor ??
        readerPrimary.withValues(
          alpha: isDark
              ? navTheme.actionButtonBorderAlphaDark
              : navTheme.actionButtonBorderAlphaLight,
        );

    final Widget button = Material(
      color: effectiveBg,
      borderRadius: BorderRadius.circular(navTheme.actionButtonRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(navTheme.actionButtonRadius),
        child: Ink(
          width: navTheme.headerActionSize,
          height: navTheme.headerActionSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(navTheme.actionButtonRadius),
            border: Border.all(color: effectiveBorder),
          ),
          child: Icon(
            icon,
            size: navTheme.actionButtonIconSize,
            color: effectiveFg,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }

    return button;
  }
}
