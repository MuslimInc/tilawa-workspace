part of 'onboarding_cubit.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object> get props => [];
}

final class OnboardingInitial extends OnboardingState {}

final class OnboardingPageChanged extends OnboardingState {
  const OnboardingPageChanged(this.pageIndex);
  final int pageIndex;

  @override
  List<Object> get props => [pageIndex];
}

final class OnboardingCompleted extends OnboardingState {}
