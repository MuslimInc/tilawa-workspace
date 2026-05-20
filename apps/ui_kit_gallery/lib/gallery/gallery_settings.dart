import 'package:flutter/material.dart';

/// Runtime toggles for theme and layout direction in the gallery.
class GallerySettings extends ChangeNotifier {
  GallerySettings({this.isDark = false, this.isRtl = false});

  bool isDark;
  bool isRtl;

  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }

  void toggleDirection() {
    isRtl = !isRtl;
    notifyListeners();
  }
}
