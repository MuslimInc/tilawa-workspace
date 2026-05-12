import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_state.dart';

/// Sets overlay visibility on [bloc] for widget tests.
///
/// Implemented as a top-level function (not a method on a [Bloc] subclass) to
/// satisfy `avoid_public_methods_on_bloc` from package:bloc_lint. Uses
/// [NavigationBloc.emit], which is intended for tests.
void emitTestNavigationVisibility(
  NavigationBloc bloc, {
  required bool isVisible,
}) {
  final current = bloc.state;
  if (current is! NavigationLoaded) return;
  bloc.emit(
    current.copyWith(
      visibility: current.visibility.copyWith(
        isVisible: isVisible,
        lastShownAt: isVisible ? DateTime.now() : null,
        clearLastShownAt: !isVisible,
      ),
    ),
  );
}

/// [NavigationBloc] for tests, constructed with a fixed initial loaded state.
class SeededNavigationBloc extends NavigationBloc {
  SeededNavigationBloc({
    required NavigationLoaded initialState,
    required PageRepository pageRepository,
    required NavigationVisibilityRepository visibilityRepository,
    required SaveLastVisitedPageUseCase saveLastVisitedPageUseCase,
    required GetLastVisitedPageUseCase getLastVisitedPageUseCase,
  }) : super(
         pageRepository: pageRepository,
         visibilityRepository: visibilityRepository,
         saveLastVisitedPageUseCase: saveLastVisitedPageUseCase,
         getLastVisitedPageUseCase: getLastVisitedPageUseCase,
       ) {
    emit(initialState);
  }
}
