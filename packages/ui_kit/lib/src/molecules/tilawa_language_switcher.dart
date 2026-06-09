import 'package:flutter/material.dart';

import '../atoms/tilawa_loading_indicator.dart';
import '../foundation/component_tokens.dart';
import '../foundation/design_tokens.dart';

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
  });

  final String currentLanguage;
  final ValueChanged<String> onLanguageChanged;
  final List<String> languages;
  final String Function(String) getLanguageName;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.componentTokens.segmentedControl;

    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: tokens.containerPadding,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(tokens.containerRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        spacing: tokens.itemSpacing,
        children: languages.map((lang) {
          final isSelected = currentLanguage == lang;
          final String label = getLanguageName(lang);
          return Material(
            color: isSelected ? colorScheme.onPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(tokens.itemRadius),
            child: InkWell(
              onTap: enabled && !isLoading
                  ? () => onLanguageChanged(lang)
                  : null,
              borderRadius: BorderRadius.circular(tokens.itemRadius),
              child: Semantics(
                // fix: Accessibility — segment role (inside InkWell avoids merge bugs)
                selected: isSelected,
                button: true,
                enabled: enabled && !isLoading,
                label: label,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: tokens.minItemWidth),
                  child: Padding(
                    padding: tokens.itemPadding,
                    child: Center(
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
                              style: theme.textTheme.labelLarge?.copyWith(
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
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
