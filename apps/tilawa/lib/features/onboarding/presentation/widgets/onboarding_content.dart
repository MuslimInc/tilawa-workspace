import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class OnboardingContent extends Equatable {
  const OnboardingContent({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  final String imagePath;
  final String title;
  final String description;

  @override
  List<Object?> get props => [imagePath, title, description];
}
