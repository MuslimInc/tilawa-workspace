part of 'localization_bloc.dart';

abstract class LocalizationEvent extends Equatable {
  const LocalizationEvent();

  @override
  List<Object?> get props => [];
}

class ChangeLanguage extends LocalizationEvent {
  const ChangeLanguage(this.locale);
  final Locale locale;

  @override
  List<Object?> get props => [locale];
}

class LoadLanguage extends LocalizationEvent {
  const LoadLanguage();
}
