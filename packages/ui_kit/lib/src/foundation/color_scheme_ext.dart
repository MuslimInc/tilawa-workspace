import 'package:flutter/material.dart';

extension ColorSchemeExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Color get primaryColor => colorScheme.primary;
  Color get secondaryColor => colorScheme.secondary;
}
