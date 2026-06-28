import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Primary-tinted top fading into a neutral Home dashboard canvas.
class HomeScreenBackground extends StatelessWidget {
  const HomeScreenBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TilawaHomeScreenTokens screenTokens =
        theme.componentTokens.homeScreen;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: screenTokens.backgroundGradientFor(theme.colorScheme),
      ),
    );
  }
}
