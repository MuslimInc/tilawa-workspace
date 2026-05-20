import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

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

    return Container(
      padding: tokens.containerPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: tokens.containerOpacity,
        ),
        borderRadius: BorderRadius.circular(tokens.containerRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: languages.map((lang) {
          final isSelected = currentLanguage == lang;
          final String label = getLanguageName(lang);
          return Material(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
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
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary,
                              ),
                            )
                          : Text(
                              label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                // fix: Visual hierarchy — use theme role, not raw TextStyle
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
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
