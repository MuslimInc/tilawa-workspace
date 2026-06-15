import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/home_dashboard.dart';
import '../../domain/usecases/get_home_dashboard_use_case.dart';
import '../../../prayer_times/application/prayer_location_update_notifier.dart';
import '../../../prayer_times/domain/usecases/notify_prayer_location_updated_use_case.dart';
import 'home_dashboard_event.dart';
import 'home_dashboard_state.dart';

final class HomeDashboardBloc
    extends Bloc<HomeDashboardEvent, HomeDashboardState> {
  HomeDashboardBloc(
    this._getDashboard,
    this._notifyPrayerLocationUpdated,
  ) : super(const HomeDashboardInitial()) {
    on<HomeDashboardStarted>(_onStarted);
    on<HomeDashboardRefreshRequested>(_onRefreshRequested);
    on<HomeDashboardLocaleChanged>(_onLocaleChanged);
    on<HomeDashboardLocationRefreshRequested>(_onLocationRefreshRequested);
  }

  final GetHomeDashboardUseCase _getDashboard;
  final NotifyPrayerLocationUpdatedUseCase _notifyPrayerLocationUpdated;
  String? _localeIdentifier;

  Future<void> _onStarted(
    HomeDashboardStarted event,
    Emitter<HomeDashboardState> emit,
  ) async {
    _localeIdentifier = event.localeIdentifier ?? _localeIdentifier;
    await _load(emit, showLoading: true);
  }

  Future<void> _onRefreshRequested(
    HomeDashboardRefreshRequested event,
    Emitter<HomeDashboardState> emit,
  ) async {
    _localeIdentifier = event.localeIdentifier ?? _localeIdentifier;
    await _load(emit, showLoading: state is! HomeDashboardLoaded);
  }

  Future<void> _onLocaleChanged(
    HomeDashboardLocaleChanged event,
    Emitter<HomeDashboardState> emit,
  ) async {
    if (_localeIdentifier == event.localeIdentifier) {
      return;
    }
    _localeIdentifier = event.localeIdentifier;
    await _load(emit, showLoading: state is! HomeDashboardLoaded);
  }

  Future<void> _onLocationRefreshRequested(
    HomeDashboardLocationRefreshRequested event,
    Emitter<HomeDashboardState> emit,
  ) async {
    _localeIdentifier = event.localeIdentifier ?? _localeIdentifier;

    final HomeDashboardState current = state;
    if (current is HomeDashboardLoaded && current.isRefreshingLocation) {
      return;
    }
    if (current is HomeDashboardLoaded) {
      emit(current.copyWith(isRefreshingLocation: true));
    }

    try {
      final HomeDashboard dashboard = await _getDashboard.refreshLocation(
        localeIdentifier: _localeIdentifier,
      );
      _notifyPrayerLocationUpdated(
        localeIdentifier: _localeIdentifier,
        source: PrayerLocationUpdateSource.homeDashboard,
      );
      emit(HomeDashboardLoaded(dashboard));
    } catch (_) {
      if (current is HomeDashboardLoaded) {
        emit(current.copyWith(isRefreshingLocation: false));
      }
    }
  }

  Future<void> _load(
    Emitter<HomeDashboardState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      emit(const HomeDashboardLoading());
    }
    try {
      final dashboard = await _getDashboard(
        localeIdentifier: _localeIdentifier,
      );
      emit(HomeDashboardLoaded(dashboard));
    } catch (error) {
      emit(HomeDashboardFailure(error.toString()));
    }
  }
}
