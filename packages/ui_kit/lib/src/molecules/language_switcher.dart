import 'package:flutter/material.dart';
import '../foundation/design_tokens.dart';

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
    final tokens = theme.tokens;
    
    return Container(
      padding: EdgeInsets.all(tokens.spaceExtraSmall),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: tokens.opacityMedium,
        ),
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: languages.map((lang) {
          final isSelected = currentLanguage == lang;
          return GestureDetector(
            onTap: () => onLanguageChanged(lang),
            child: AnimatedContainer(
              duration: tokens.durationFast,
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceLarge,
                vertical: tokens.spaceSmall,
              ),
              decoration: BoxDecoration(
                color: isSelected ? theme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(tokens.radiusSmall),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.primaryColor.withValues(
                            alpha: tokens.opacityMedium,
                          ),
                          blurRadius: tokens.radiusSmall / 2,
                          offset: tokens.shadowOffsetSmall,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                getLanguageName(lang),
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
