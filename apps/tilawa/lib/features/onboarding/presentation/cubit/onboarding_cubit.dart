import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/complete_onboarding.dart';

part 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._completeOnboarding) : super(OnboardingInitial());
  final CompleteOnboarding _completeOnboarding;

  void pageChanged(int index) {
    emit(OnboardingPageChanged(index));
  }

  Future<void> completeOnboarding() async {
    await _completeOnboarding();
    emit(OnboardingCompleted());
  }
}
