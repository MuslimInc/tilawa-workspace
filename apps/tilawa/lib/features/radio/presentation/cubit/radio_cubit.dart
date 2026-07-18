import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../../domain/radio_constants.dart';
import '../../domain/entities/radio_station.dart';
import '../../domain/radio_playback_mapper.dart';
import '../../domain/usecases/add_recent_radio_station_use_case.dart';
import '../../domain/usecases/get_radio_favorites_use_case.dart';
import '../../domain/usecases/get_radio_stations_use_case.dart';
import '../../domain/usecases/get_recent_radio_stations_use_case.dart';
import '../../domain/usecases/refresh_radio_stations_use_case.dart';
import '../../domain/usecases/search_radio_stations_use_case.dart';
import '../../domain/usecases/toggle_radio_favorite_use_case.dart';
import 'radio_state.dart';

/// Presentation state machine for Islamic Radio catalog and preferences.
@injectable
class RadioCubit extends Cubit<RadioState> {
  RadioCubit(
    this._getStations,
    this._refreshStations,
    this._searchStations,
    this._getFavorites,
    this._toggleFavorite,
    this._getRecent,
    this._addRecent,
    this._analytics,
    this._connectivity,
  ) : super(const RadioState());

  final GetRadioStationsUseCase _getStations;
  final RefreshRadioStationsUseCase _refreshStations;
  final SearchRadioStationsUseCase _searchStations;
  final GetRadioFavoritesUseCase _getFavorites;
  final ToggleRadioFavoriteUseCase _toggleFavorite;
  final GetRecentRadioStationsUseCase _getRecent;
  final AddRecentRadioStationUseCase _addRecent;
  final AnalyticsService _analytics;
  final Connectivity _connectivity;

  Timer? _searchDebounce;
  DateTime? _listenStartedAt;
  String? _listeningStationId;

  /// Loads catalog for [language] (`eng` or `ar`).
  Future<void> load({required String language}) async {
    emit(state.copyWith(status: RadioStatus.loading, clearFailure: true));
    final bool offline = await _isOffline();
    final Either<Failure, List<RadioStation>> result = await _getStations(
      GetRadioStationsParams(language: language),
    );
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: RadioStatus.error,
            failure: failure,
            isOffline: offline,
          ),
        );
      },
      (stations) async => _emitLoaded(stations, isOffline: offline),
    );
  }

  Future<void> refresh({required String language}) async {
    emit(state.copyWith(isRefreshing: true, clearFailure: true));
    final Either<Failure, List<RadioStation>> result = await _refreshStations(
      RefreshRadioStationsParams(language: language),
    );
    final bool offline = await _isOffline();
    await result.fold(
      (failure) async {
        if (state.stations.isEmpty) {
          emit(
            state.copyWith(
              status: RadioStatus.error,
              failure: failure,
              isOffline: offline,
              isRefreshing: false,
            ),
          );
        } else {
          emit(
            state.copyWith(
              failure: failure,
              isOffline: offline,
              isRefreshing: false,
            ),
          );
        }
      },
      (stations) async => _emitLoaded(
        stations,
        isOffline: offline,
        isRefreshing: false,
      ),
    );
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () async {
      final Either<Failure, List<RadioStation>> result = await _searchStations(
        SearchRadioStationsParams(query),
      );
      result.fold(
        (_) {},
        (filtered) => emit(
          state.copyWith(
            searchQuery: query,
            filteredStations: filtered,
          ),
        ),
      );
    });
  }

  Future<void> toggleFavorite(String stationId) async {
    final Either<Failure, RadioStation> result = await _toggleFavorite(
      ToggleRadioFavoriteParams(stationId),
    );
    await result.fold(
      (_) async {},
      (updated) async {
        final List<RadioStation> stations = state.stations
            .map((s) => s.id == updated.id ? updated : s)
            .toList(growable: false);
        await _emitLoaded(stations, isOffline: state.isOffline);
      },
    );
  }

  /// Records play analytics + recent, returns [AudioEntity] for shared player.
  Future<AudioEntity> playStation(RadioStation station) async {
    await _analytics.logEvent(
      AnalyticsEvents.radioStationOpened,
      parameters: <String, Object>{
        AnalyticsParams.radioStationId: station.id,
        AnalyticsParams.radioStationName: station.name,
      },
    );
    await _analytics.logEvent(
      AnalyticsEvents.radioPlay,
      parameters: <String, Object>{
        AnalyticsParams.radioStationId: station.id,
      },
    );
    await _addRecent(station);
    _listenStartedAt = DateTime.now();
    _listeningStationId = station.id;
    final List<RadioStation> recent = await _getRecent(
      const NoParams(),
    ).then((r) => r.getOrElse(() => state.recent));
    emit(state.copyWith(recent: recent));
    return RadioPlaybackMapper.toAudioEntity(station);
  }

  Future<void> trackStop() async {
    final String? stationId = _listeningStationId;
    final DateTime? started = _listenStartedAt;
    if (stationId == null || started == null) return;
    final int seconds = DateTime.now().difference(started).inSeconds;
    await _analytics.logEvent(
      AnalyticsEvents.radioStop,
      parameters: <String, Object>{
        AnalyticsParams.radioStationId: stationId,
      },
    );
    await _analytics.logEvent(
      AnalyticsEvents.radioListenDuration,
      parameters: <String, Object>{
        AnalyticsParams.radioStationId: stationId,
        AnalyticsParams.listenDurationSeconds: seconds,
      },
    );
    _listeningStationId = null;
    _listenStartedAt = null;
  }

  Future<void> trackShare(RadioStation station) async {
    await _analytics.logEvent(
      AnalyticsEvents.radioShare,
      parameters: <String, Object>{
        AnalyticsParams.radioStationId: station.id,
        AnalyticsParams.radioStationName: station.name,
      },
    );
  }

  Future<void> _emitLoaded(
    List<RadioStation> stations, {
    required bool isOffline,
    bool isRefreshing = false,
  }) async {
    final Either<Failure, List<RadioStation>> favoritesResult =
        await _getFavorites(const NoParams());
    final Either<Failure, List<RadioStation>> recentResult = await _getRecent(
      const NoParams(),
    );
    final List<RadioStation> favorites = favoritesResult.getOrElse(
      () => const <RadioStation>[],
    );
    final List<RadioStation> recent = recentResult.getOrElse(
      () => const <RadioStation>[],
    );
    final RadioStation? featured = _resolveFeatured(stations);
    final String query = state.searchQuery;
    final List<RadioStation> filtered = query.trim().isEmpty
        ? stations
        : stations
              .where(
                (s) =>
                    s.name.toLowerCase().contains(query.trim().toLowerCase()),
              )
              .toList(growable: false);

    if (stations.isEmpty) {
      emit(
        state.copyWith(
          status: RadioStatus.empty,
          stations: stations,
          filteredStations: filtered,
          favorites: favorites,
          recent: recent,
          clearFeatured: true,
          isOffline: isOffline,
          isRefreshing: isRefreshing,
          clearFailure: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: RadioStatus.loaded,
        stations: stations,
        filteredStations: filtered,
        favorites: favorites,
        recent: recent,
        featured: featured,
        isOffline: isOffline,
        isRefreshing: isRefreshing,
        clearFailure: true,
      ),
    );
  }

  RadioStation? _resolveFeatured(List<RadioStation> stations) {
    for (final RadioStation station in stations) {
      if (station.id == RadioConstants.featuredStationId) {
        return station;
      }
    }
    return stations.isEmpty ? null : stations.first;
  }

  Future<bool> _isOffline() async {
    final List<ConnectivityResult> results = await _connectivity
        .checkConnectivity();
    return results.contains(ConnectivityResult.none) && results.length == 1;
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
