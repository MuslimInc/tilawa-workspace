part of 'localization_bloc.dart';

final class LocalizationState extends Equatable {
  const LocalizationState({required this.locale});
  final Locale locale;

  @override
  List<Object?> get props => [locale];
}
