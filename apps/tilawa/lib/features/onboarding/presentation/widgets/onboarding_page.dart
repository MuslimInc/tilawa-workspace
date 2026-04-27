import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'onboarding_content.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.content});
  final OnboardingContent content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceExtraLarge),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                content.imagePath,
                width: tokens.iconSizeExtraLarge * 4 + tokens.spaceSmall,
                fit: BoxFit.fill,
              ),
              SizedBox(height: tokens.spaceExtraLarge + tokens.spaceLarge),
              Text(
                content.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: tokens.spaceLarge),
              Text(
                content.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
