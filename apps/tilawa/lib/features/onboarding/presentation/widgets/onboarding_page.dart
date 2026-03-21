import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'onboarding_content.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.content});
  final OnboardingContent content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(content.imagePath, width: 200, fit: BoxFit.fill),
              Gap(40),
              Text(
                content.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Gap(16),
              Text(
                content.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
