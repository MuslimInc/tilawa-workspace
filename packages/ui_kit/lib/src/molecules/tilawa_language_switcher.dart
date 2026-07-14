import 'package:flutter/material.dart';

import '../atoms/tilawa_loading_indicator.dart';
import '../foundation/app_theme.dart';
import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';
import '../foundation/tilawa_interactive_surface.dart';
import '../foundation/tilawa_text_roles.dart';

/// Switches [languages] with the same chrome as [TilawaSegmentedControl].
class TilawaLanguageSwitcher extends StatelessWidget {
  const TilawaLanguageSwitcher({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
    required this.languages,
    required this.getLanguageName,
    this.enabled = true,
    this.isLoading = false,
    this.compact = false,
  });

  final String currentLanguage;
  final ValueChanged<String> onLanguageChanged;
  final List<String> languages;
  final String Function(String) getLanguageName;
  final bool enabled;
  final bool isLoading;

  /// Tighter padding and [TilawaTextRole.labelMedium] for chrome slots
  /// (login app bar, settings header).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designTokens = theme.tokens;
    final tokens = theme.componentTokens.segmentedControl;

    final ColorScheme colorScheme = theme.colorScheme;
    final TextDirection direction = Directionality.of(context);
    final EdgeInsetsGeometry itemPadding = compact
        ? EdgeInsets.symmetric(
            horizontal: designTokens.spaceSmall,
            vertical: designTokens.spaceExtraSmall,
          )
        : tokens.itemPadding.resolve(direction);
    final EdgeInsetsGeometry containerPadding = compact
        ? EdgeInsets.all(designTokens.spaceExtraSmall)
        : tokens.containerPadding.resolve(direction);
    final TextStyle labelStyle = compact
        ? tilawaResolveTextRole(
            theme.textTheme,
            TilawaTextRole.labelMedium,
          )
        : theme.textTheme.labelLarge ?? const TextStyle();
    final double labelHeight =
        (labelStyle.fontSize ?? 14) * (labelStyle.height ?? 1.2);
    final double itemHeight =
        itemPadding.resolve(direction).vertical + labelHeight;
    final radii = designTokens.resolveSegmentedControlRadii(
      itemHeight: itemHeight,
      containerPadding: containerPadding.resolve(direction).top,
      trackFamily: TilawaRadiusFamily.pill,
    );
    final containerBorderRadius = BorderRadius.circular(radii.containerRadius);
    final itemBorderRadius = BorderRadius.circular(radii.itemRadius);

    return Container(
      padding: containerPadding,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: containerBorderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        spacing: tokens.itemSpacing,
        children: languages.map((lang) {
          final isSelected = currentLanguage == lang;
          final String label = getLanguageName(lang);
          return TilawaInteractiveSurface(
            onTap: enabled && !isLoading ? () => onLanguageChanged(lang) : null,
            enabled: enabled && !isLoading,
            // fix: Accessibility — segment role.
            selected: isSelected,
            semanticLabel: label,
            borderRadius: itemBorderRadius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.onPrimary : Colors.transparent,
                borderRadius: itemBorderRadius,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: compact ? 0 : tokens.minItemWidth,
                ),
                child: Padding(
                  padding: itemPadding,
                  child: isLoading && isSelected
                      ? SizedBox.square(
                          dimension: theme.tokens.iconSizeSmall,
                          child: TilawaLoadingIndicator(
                            centered: false,
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      : Text(
                          label,
                          textAlign: TextAlign.center,
                          style: labelStyle.copyWith(
                            fontFamily: AppTheme.fontFamilyForLanguageCode(
                              lang,
                            ),
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onPrimary,
                            fontWeight: isSelected
                                ? tokens.selectedFontWeight
                                : tokens.unselectedFontWeight,
                          ),
                        ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
