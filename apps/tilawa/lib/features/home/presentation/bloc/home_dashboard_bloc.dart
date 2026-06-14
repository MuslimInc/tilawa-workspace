import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_home_dashboard_use_case.dart';
import 'home_dashboard_event.dart';
import 'home_dashboard_state.dart';

final class HomeDashboardBloc
    extends Bloc<HomeDashboardEvent, HomeDashboardState> {
  HomeDashboardBloc(this._getDashboard) : super(const HomeDashboardInitial()) {
    on<HomeDashboardStarted>(_onStarted);
    on<HomeDashboardRefreshRequested>(_onRefreshRequested);
  }

  final GetHomeDashboardUseCase _getDashboard;

  Future<void> _onStarted(
    HomeDashboardStarted event,
    Emitter<HomeDashboardState> emit,
  ) async {
    await _load(emit, showLoading: true);
  }

  Future<void> _onRefreshRequested(
    HomeDashboardRefreshRequested event,
    Emitter<HomeDashboardState> emit,
  ) async {
    await _load(emit, showLoading: state is! HomeDashboardLoaded);
  }

  Future<void> _load(
    Emitter<HomeDashboardState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      emit(const HomeDashboardLoading());
    }
    try {
      final dashboard = await _getDashboard();
      emit(HomeDashboardLoaded(dashboard));
    } catch (error) {
      emit(HomeDashboardFailure(error.toString()));
    }
  }
}
