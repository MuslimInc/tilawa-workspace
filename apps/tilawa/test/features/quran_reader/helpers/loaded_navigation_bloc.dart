import 'package:quran_image/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_state.dart';

/// [NavigationBloc] seeded with a fixed loaded state for reader tests.
class LoadedNavigationBloc extends NavigationBloc {
  LoadedNavigationBloc({
    required NavigationLoaded initialState,
    required super.pageRepository,
    required super.visibilityRepository,
    required super.saveLastVisitedPageUseCase,
    required super.getLastVisitedPageUseCase,
  }) {
    emit(initialState);
  }
}
