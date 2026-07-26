import 'package:flutter/material.dart';

class SadaqahJariyahLetterAvatar extends StatelessWidget {
  const SadaqahJariyahLetterAvatar({
    required this.name,
    this.size = 48,
    super.key,
  });

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String letter = _firstGrapheme(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: theme.textTheme.titleMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _firstGrapheme(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }
}
