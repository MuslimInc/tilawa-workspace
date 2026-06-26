import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Flat neutral canvas for the Home dashboard.
class HomeScreenBackground extends StatelessWidget {
  const HomeScreenBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final TilawaHomeScreenTokens screenTokens = Theme.of(
      context,
    ).componentTokens.homeScreen;

    return ColoredBox(color: screenTokens.backgroundGradientEnd);
  }
}
