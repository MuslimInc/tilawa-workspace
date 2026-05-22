import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'onboarding_hero_visual.dart';

@immutable
class OnboardingContent extends Equatable {
  const OnboardingContent({
    required this.imagePath,
    required this.title,
    required this.description,
    this.heroStyle = OnboardingHeroStyle.illustration,
    this.visualHint,
  });

  final String imagePath;
  final String title;
  final String description;
  final OnboardingHeroStyle heroStyle;
  final String? visualHint;

  @override
  List<Object?> get props => [
    imagePath,
    title,
    description,
    heroStyle,
    visualHint,
  ];
}
