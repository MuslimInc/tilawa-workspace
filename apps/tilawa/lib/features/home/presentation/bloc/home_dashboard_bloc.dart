import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/network/network_error_message.dart';

import '../../../prayer_times/application/prayer_location_update_notifier.dart';
import '../../../prayer_times/domain/usecases/notify_prayer_location_updated_use_case.dart';
import '../../domain/entities/home_dashboard.dart';
import '../../domain/usecases/get_home_dashboard_use_case.dart';
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
  ///
  /// When a refresh is already pending, returns its future without queueing
  /// a duplicate refresh event.
  ///
  /// Deliberate await-handle for [RefreshIndicator]: silent refreshes emit no
  /// distinct state, so completion cannot be observed via the state stream.
  // ignore: avoid_public_bloc_methods
  Future<void> refreshAndWait({String? localeIdentifier}) {
    _localeIdentifier = localeIdentifier ?? _localeIdentifier;
    final Completer<void>? pending = _refreshCompleter;
    if (pending != null) {
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
            clearRefreshError: true,
          ),
        );
        final HomeDashboard dashboard = await _getDashboard(
          localeIdentifier: _localeIdentifier,
        );
        emit(HomeDashboardLoaded(dashboard));
        return;
      }

      await _loadInitial(emit);
    } catch (error, stackTrace) {
      if (current is HomeDashboardLoaded) {
        emit(
          current.copyWith(
            isRefreshing: false,
            refreshError: _classifyError(error, stackTrace),
          ),
        );
        return;
      }
      emit(HomeDashboardFailure(_classifyError(error, stackTrace)));
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
    } catch (error, stackTrace) {
      emit(HomeDashboardFailure(_classifyError(error, stackTrace)));
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
    } catch (error, stackTrace) {
      logger.d(
        'Silent home dashboard refresh failed; keeping cached snapshot',
        error: error,
        stackTrace: stackTrace,
      );
      emit(HomeDashboardLoaded(cachedDashboard));
    }
  }

  /// Classifies a dashboard load error and keeps the raw details in logs
  /// only; user-facing state carries just the [HomeDashboardFailureKind].
  HomeDashboardFailureKind _classifyError(Object error, StackTrace stackTrace) {
    final HomeDashboardFailureKind kind;
    if (error is TimeoutException) {
      kind = HomeDashboardFailureKind.timeout;
    } else if (isNetworkConnectivityErrorMessage(error.toString())) {
      kind = HomeDashboardFailureKind.offline;
    } else {
      kind = HomeDashboardFailureKind.unknown;
    }
    logger.w(
      'Home dashboard load failed (${kind.name})',
      error: error,
      stackTrace: stackTrace,
    );
    return kind;
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
