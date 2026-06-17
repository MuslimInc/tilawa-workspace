import 'package:flutter/material.dart';

/// One tappable Home shortcut — shared by list and grid layouts.
class HomeShortcutEntry {
  const HomeShortcutEntry({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.semanticLabel,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final String? semanticLabel;
}
