import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/get_splash_next_route_use_case.dart';

part 'splash_state.dart';

@injectable
class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this._getSplashNextRoute) : super(const SplashInitial());

  final GetSplashNextRouteUseCase _getSplashNextRoute;

  Future<void> init() async {
    // Artificial delay to display branding
    await Future.delayed(const Duration(seconds: 2));

    final SplashDestination destination = await _getSplashNextRoute();

    switch (destination) {
      case SplashDestination.home:
        emit(const SplashNavigateToHome());
      case SplashDestination.login:
        emit(const SplashNavigateToLogin());
      case SplashDestination.onboarding:
        emit(const SplashNavigateToOnboarding());
    }
  }
}
