import 'package:flutter/material.dart';

import '../gallery_entry.dart';
import '../gallery_settings.dart';

/// Full-screen preview for a single gallery entry.
class GalleryDetailScreen extends StatelessWidget {
  const GalleryDetailScreen({super.key, required this.entry});

  final GalleryEntry entry;

  @override
  Widget build(BuildContext context) {
    final settings = GallerySettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.name),
        actions: [
          IconButton(
            tooltip: 'Toggle RTL',
            onPressed: settings.toggleDirection,
            icon: Icon(settings.isRtl ? Icons.format_textdirection_r_to_l : Icons.format_textdirection_l_to_r),
          ),
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: settings.toggleTheme,
            icon: Icon(settings.isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: entry.builder(context),
    );
  }
}

/// Exposes [GallerySettings] to the widget tree.
class GallerySettingsScope extends InheritedNotifier<GallerySettings> {
  const GallerySettingsScope({
    super.key,
    required GallerySettings super.notifier,
    required super.child,
  });

  static GallerySettings of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<GallerySettingsScope>();
    assert(scope != null, 'GallerySettingsScope not found');
    return scope!.notifier!;
  }
}
