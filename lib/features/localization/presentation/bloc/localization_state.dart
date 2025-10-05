import 'package:equatable/equatable.dart';

abstract class LocalizationState extends Equatable {
  const LocalizationState();

  @override
  List<Object?> get props => [];
}

class LocalizationInitial extends LocalizationState {
  const LocalizationInitial();
}

class LocalizationLoading extends LocalizationState {
  const LocalizationLoading();
}

class LocalizationLoaded extends LocalizationState {
  const LocalizationLoaded({
    required this.currentLanguage,
    required this.supportedLanguages,
  });

  final String currentLanguage;
  final List<String> supportedLanguages;

  LocalizationLoaded copyWith({
    String? currentLanguage,
    List<String>? supportedLanguages,
  }) {
    return LocalizationLoaded(
      currentLanguage: currentLanguage ?? this.currentLanguage,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
    );
  }

  @override
  List<Object?> get props => [currentLanguage, supportedLanguages];
}

class LocalizationError extends LocalizationState {
  const LocalizationError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
