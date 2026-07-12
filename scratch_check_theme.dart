import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/molecules/tilawa_app_bar_config.dart';

void main() {
  final theme = AppTheme.getLightTheme(primaryColor: Colors.blue);
  final appBarThemeStyle = theme.appBarTheme.titleTextStyle;
  final tilawaStyle = TilawaAppBarChrome.titleTextStyle(theme);
  
  print('AppBarTheme style:');
  print('  fontFamily: ${appBarThemeStyle?.fontFamily}');
  print('  fontSize: ${appBarThemeStyle?.fontSize}');
  print('  fontWeight: ${appBarThemeStyle?.fontWeight}');
  print('  color: ${appBarThemeStyle?.color}');
  
  print('TilawaAppBar style:');
  print('  fontFamily: ${tilawaStyle?.fontFamily}');
  print('  fontSize: ${tilawaStyle?.fontSize}');
  print('  fontWeight: ${tilawaStyle?.fontWeight}');
  print('  color: ${tilawaStyle?.color}');
}
