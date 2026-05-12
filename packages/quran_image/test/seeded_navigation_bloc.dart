import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_state.dart';

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

  void setVisibility({required bool isVisible}) {
    final current = state;
    if (current is! NavigationLoaded) return;
    emit(
      current.copyWith(
        visibility: current.visibility.copyWith(
          isVisible: isVisible,
          lastShownAt: isVisible ? DateTime.now() : null,
          clearLastShownAt: !isVisible,
        ),
      ),
    );
  }
}
