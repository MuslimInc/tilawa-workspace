import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'gallery/gallery_settings.dart';
import 'gallery/screens/gallery_detail_screen.dart';
import 'gallery/screens/gallery_home_screen.dart';

void main() {
  runApp(const UiKitGalleryApp());
}

/// Standalone gallery for browsing Tilawa UI Kit components.
class UiKitGalleryApp extends StatefulWidget {
  const UiKitGalleryApp({super.key});

  @override
  State<UiKitGalleryApp> createState() => _UiKitGalleryAppState();
}

class _UiKitGalleryAppState extends State<UiKitGalleryApp> {
  final GallerySettings _settings = GallerySettings();

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final theme = _settings.isDark
            ? AppTheme.getDarkTheme(
                primaryColor: AppColors.primaryCyan,
                isDefaultPreset: true,
                useGoogleFontsOverride: false,
              )
            : AppTheme.getLightTheme(
                primaryColor: AppColors.primaryCyan,
                useGoogleFontsOverride: false,
              );

        return GallerySettingsScope(
          notifier: _settings,
          child: MaterialApp(
            title: 'Tilawa UI Kit Gallery',
            theme: theme,
            builder: (context, child) {
              return Directionality(
                textDirection:
                    _settings.isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const GalleryHomeScreen(),
          ),
        );
      },
    );
  }
}
