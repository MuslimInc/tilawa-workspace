import 'package:flutter/material.dart';

import '../foundation/component_tokens.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
    required this.languages,
    required this.getLanguageName,
  });

  final String currentLanguage;
  final Function(String) onLanguageChanged;
  final List<String> languages;
  final String Function(String) getLanguageName;

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
        mainAxisSize: .min,
        textDirection: .ltr,
        children: languages.map((lang) {
          final isSelected = currentLanguage == lang;
          return GestureDetector(
            onTap: () => onLanguageChanged(lang),
            child: Container(
              padding: tokens.itemPadding,
              constraints: BoxConstraints(minWidth: tokens.minItemWidth),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(tokens.itemRadius),
              ),
              child: Center(
                child: Text(
                  getLanguageName(lang),
                  style: TextStyle(
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
          );
        }).toList(),
      ),
    );
  }
}
