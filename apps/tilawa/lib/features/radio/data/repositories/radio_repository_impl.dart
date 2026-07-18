import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/radio_station.dart';
import '../../domain/repositories/radio_repository.dart';
import '../datasources/radio_local_datasource.dart';
import '../datasources/radio_remote_datasource.dart';
import '../models/radio_station_mapper.dart';

@LazySingleton(as: RadioRepository)
class RadioRepositoryImpl implements RadioRepository {
  RadioRepositoryImpl(
    this._remote,
    this._local,
    this._connectivity,
    this._analytics,
  );

  final RadioRemoteDataSource _remote;
  final RadioLocalDataSource _local;
  final Connectivity _connectivity;
  final AnalyticsService _analytics;

  List<RadioStation> _catalog = const <RadioStation>[];

  @override
  ResultFuture<List<RadioStation>> getStations({
    required String language,
  }) async {
    try {
      final List<RadioStation> cached = await _local.getCachedStations();
      if (cached.isNotEmpty) {
        _catalog = cached;
        unawaited(_refreshInBackground(language));
        return Right(cached);
      }
      return refreshStations(language: language);
    } on Object catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<RadioStation>> refreshStations({
    required String language,
    DateTime? after,
  }) async {
    try {
      final List<RadioStation> stations = await _fetchAndCache(
        language: language,
        after: after,
      );
      _catalog = stations;
      return Right(stations);
    } on DioException catch (e) {
      final List<RadioStation> cached = await _local.getCachedStations();
      if (cached.isNotEmpty) {
        _catalog = cached;
        return Right(cached);
      }
      return Left(_mapDio(e));
    } on Object catch (e) {
      final List<RadioStation> cached = await _local.getCachedStations();
      if (cached.isNotEmpty) {
        _catalog = cached;
        return Right(cached);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<RadioStation>> searchStations(String query) async {
    try {
      final List<RadioStation> source = _catalog.isNotEmpty
          ? _catalog
          : await _local.getCachedStations();
      final String q = query.trim().toLowerCase();
      if (q.isEmpty) return Right(source);
      return Right(
        source
            .where((s) => s.name.toLowerCase().contains(q))
            .toList(growable: false),
      );
    } on Object catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<RadioStation>> getFavorites() async {
    try {
      final Set<String> ids = (await _local.getFavoriteIds()).toSet();
      final List<RadioStation> source = _catalog.isNotEmpty
          ? _catalog
          : await _local.getCachedStations();
      return Right(
        source
            .where((s) => ids.contains(s.id))
            .map((s) => s.copyWith(isFavorite: true))
            .toList(growable: false),
      );
    } on Object catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<RadioStation> toggleFavorite(String stationId) async {
    try {
      final List<String> ids = List<String>.from(await _local.getFavoriteIds());
      final bool wasFavorite = ids.contains(stationId);
      if (wasFavorite) {
        ids.remove(stationId);
      } else {
        ids.add(stationId);
      }
      await _local.saveFavoriteIds(ids);

      RadioStation? station = _findInCatalog(stationId);
      if (station == null) {
        final List<RadioStation> cached = await _local.getCachedStations();
        for (final RadioStation s in cached) {
          if (s.id == stationId) {
            station = s;
            break;
          }
        }
      }
      if (station == null) {
        return Left(CacheFailure('Station not found: $stationId'));
      }
      final RadioStation updated = station.copyWith(isFavorite: !wasFavorite);
      _catalog = _catalog
          .map((s) => s.id == stationId ? updated : s)
          .toList(growable: false);

      await _analytics.logEvent(
        AnalyticsEvents.radioFavorite,
        parameters: <String, Object>{
          AnalyticsParams.radioStationId: stationId,
          AnalyticsParams.isFavorite: updated.isFavorite ? 1 : 0,
        },
      );
      return Right(updated);
    } on Object catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<RadioStation>> getRecentStations() async {
    try {
      final Set<String> favoriteIds = (await _local.getFavoriteIds()).toSet();
      final List<RadioStation> recent = await _local.getRecentStations();
      return Right(
        recent
            .map(
              (s) => s.copyWith(isFavorite: favoriteIds.contains(s.id)),
            )
            .toList(growable: false),
      );
    } on Object catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> addRecentStation(RadioStation station) async {
    try {
      final List<RadioStation> existing = await _local.getRecentStations();
      final List<RadioStation> next = <RadioStation>[
        station.copyWith(isFavorite: station.isFavorite),
        ...existing.where((s) => s.id != station.id),
      ].take(RadioLocalDataSourceImpl.maxRecentStations).toList();
      await _local.saveRecentStations(next);
      return const Right(null);
    } on Object catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<void> _refreshInBackground(String language) async {
    try {
      final List<ConnectivityResult> results = await _connectivity
          .checkConnectivity();
      if (results.contains(ConnectivityResult.none) && results.length == 1) {
        return;
      }
      await _fetchAndCache(language: language);
    } on Object {
      // Keep cache on background refresh failure.
    }
  }

  Future<List<RadioStation>> _fetchAndCache({
    required String language,
    DateTime? after,
  }) async {
    final dtos = await _remote.fetchStations(
      language: language,
      after: after,
    );
    final Set<String> favoriteIds = (await _local.getFavoriteIds()).toSet();
    final List<RadioStation> stations = dtos
        .map(
          (dto) => RadioStationMapper.toEntity(
            dto,
            isFavorite: favoriteIds.contains(dto.id.toString()),
          ),
        )
        .toList(growable: false);
    await _local.saveCachedStations(stations);
    _catalog = stations;
    return stations;
  }

  RadioStation? _findInCatalog(String stationId) {
    for (final RadioStation station in _catalog) {
      if (station.id == stationId) return station;
    }
    return null;
  }

  Failure _mapDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkFailure('timeout');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure('offline');
    }
    return ServerFailure(e.message);
  }
}
