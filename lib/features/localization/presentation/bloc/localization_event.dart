import 'package:equatable/equatable.dart';

abstract class LocalizationEvent extends Equatable {
  const LocalizationEvent();

  @override
  List<Object?> get props => [];
}

class LoadLocalization extends LocalizationEvent {
  const LoadLocalization();
}

class ChangeLanguage extends LocalizationEvent {
  const ChangeLanguage(this.languageCode);

  final String languageCode;

  @override
  List<Object?> get props => [languageCode];
}
