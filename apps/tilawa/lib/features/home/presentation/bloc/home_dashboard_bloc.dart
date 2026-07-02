import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/network/network_error_message.dart';

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
  Completer<void>? _refreshCompleter;

  /// Awaits the in-flight dashboard refresh started by pull-to-refresh.
  Future<void> refreshAndWait({String? localeIdentifier}) {
    _localeIdentifier = localeIdentifier ?? _localeIdentifier;
    final Completer<void>? pending = _refreshCompleter;
    if (pending != null) {
      add(HomeDashboardRefreshRequested(localeIdentifier: _localeIdentifier));
      return pending.future;
    }

    final Completer<void> completer = Completer<void>();
    _refreshCompleter = completer;
    add(HomeDashboardRefreshRequested(localeIdentifier: _localeIdentifier));
    return completer.future;
  }

  Future<void> _onStarted(
    HomeDashboardStarted event,
    Emitter<HomeDashboardState> emit,
  ) async {
    _localeIdentifier = event.localeIdentifier ?? _localeIdentifier;

    final HomeDashboard? cached = _getDashboard.readCachedDashboard();
    if (cached != null) {
      emit(HomeDashboardLoaded(cached));
      await _refreshSilently(emit, cachedDashboard: cached);
      return;
    }

    await _loadInitial(emit);
  }

  Future<void> _onRefreshRequested(
    HomeDashboardRefreshRequested event,
    Emitter<HomeDashboardState> emit,
  ) async {
    _localeIdentifier = event.localeIdentifier ?? _localeIdentifier;
    final HomeDashboardState current = state;

    try {
      if (current is HomeDashboardLoaded) {
        emit(
          current.copyWith(
            isRefreshing: true,
            clearRefreshErrorMessage: true,
          ),
        );
        final HomeDashboard dashboard = await _getDashboard(
          localeIdentifier: _localeIdentifier,
        );
        emit(HomeDashboardLoaded(dashboard));
        return;
      }

      await _loadInitial(emit);
    } catch (error) {
      if (current is HomeDashboardLoaded) {
        emit(
          current.copyWith(
            isRefreshing: false,
            refreshErrorMessage: error.toString(),
          ),
        );
        return;
      }
      emit(_mapFailure(error));
    } finally {
      _completeRefreshWaiter();
    }
  }

  Future<void> _onLocaleChanged(
    HomeDashboardLocaleChanged event,
    Emitter<HomeDashboardState> emit,
  ) async {
    if (_localeIdentifier == event.localeIdentifier) {
      return;
    }
    _localeIdentifier = event.localeIdentifier;

    final HomeDashboardState current = state;
    if (current is HomeDashboardLoaded) {
      add(
        HomeDashboardRefreshRequested(localeIdentifier: event.localeIdentifier),
      );
      return;
    }

    await _loadInitial(emit);
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

  Future<void> _loadInitial(Emitter<HomeDashboardState> emit) async {
    emit(const HomeDashboardLoading());
    try {
      final HomeDashboard dashboard = await _getDashboard(
        localeIdentifier: _localeIdentifier,
      );
      emit(HomeDashboardLoaded(dashboard));
    } catch (error) {
      emit(_mapFailure(error));
    }
  }

  Future<void> _refreshSilently(
    Emitter<HomeDashboardState> emit, {
    required HomeDashboard cachedDashboard,
  }) async {
    try {
      final HomeDashboard dashboard = await _getDashboard(
        localeIdentifier: _localeIdentifier,
      );
      emit(HomeDashboardLoaded(dashboard));
    } catch (_) {
      emit(HomeDashboardLoaded(cachedDashboard));
    }
  }

  HomeDashboardFailure _mapFailure(Object error) {
    final String message = error.toString();
    final HomeDashboardFailureKind kind =
        isNetworkConnectivityErrorMessage(message)
        ? HomeDashboardFailureKind.offline
        : HomeDashboardFailureKind.generic;
    return HomeDashboardFailure(message, kind: kind);
  }

  void _completeRefreshWaiter() {
    final Completer<void>? completer = _refreshCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.complete();
    _refreshCompleter = null;
  }

  @override
  Future<void> close() {
    _completeRefreshWaiter();
    return super.close();
  }
}
