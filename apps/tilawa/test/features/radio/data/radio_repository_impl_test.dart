import 'package:checks/checks.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/errors/failures.dart';
import '../../../support/recording_analytics_service.dart';

import 'package:tilawa/features/radio/data/datasources/radio_local_datasource.dart';
import 'package:tilawa/features/radio/data/datasources/radio_remote_datasource.dart';
import 'package:tilawa/features/radio/data/models/radio_station_dto.dart';
import 'package:tilawa/features/radio/data/repositories/radio_repository_impl.dart';
import 'package:tilawa/features/radio/domain/entities/radio_station.dart';

void main() {
  late _FakeRemote remote;
  late _FakeLocal local;
  late _FakeConnectivity connectivity;
  late RecordingAnalyticsService analytics;
  late RadioRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    local = _FakeLocal();
    connectivity = _FakeConnectivity();
    analytics = RecordingAnalyticsService();
    repository = RadioRepositoryImpl(
      remote,
      local,
      connectivity,
      analytics,
    );
  });

  group('RadioRepositoryImpl', () {
    test(
      'getStations returns cache first and refreshes in background',
      () async {
        local.cached = const [
          RadioStation(id: '1', name: 'Cached', streamUrl: 'https://a'),
        ];
        remote.stations = [
          const RadioStationDto(id: 1, name: 'Fresh', url: 'https://b'),
        ];

        final result = await repository.getStations(language: 'eng');
        check(result.isRight()).equals(true);
        final stations = result.getOrElse(() => const []);
        check(stations).length.equals(1);
        check(stations.first.name).equals('Cached');

        await Future<void>.delayed(const Duration(milliseconds: 50));
        check(local.cached.first.name).equals('Fresh');
      },
    );

    test('refreshStations keeps cache on network failure', () async {
      local.cached = const [
        RadioStation(id: '1', name: 'Cached', streamUrl: 'https://a'),
      ];
      remote.throwDio = DioException(
        requestOptions: RequestOptions(path: '/radios'),
        type: DioExceptionType.connectionError,
      );

      final result = await repository.refreshStations(language: 'eng');
      check(result.isRight()).equals(true);
      check(result.getOrElse(() => const []).first.name).equals('Cached');
    });

    test('refreshStations returns NetworkFailure when no cache', () async {
      remote.throwDio = DioException(
        requestOptions: RequestOptions(path: '/radios'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = await repository.refreshStations(language: 'eng');
      check(result.isLeft()).equals(true);
      result.fold(
        (f) => check(f).isA<NetworkFailure>(),
        (_) => fail('expected Left'),
      );
    });

    test('searchStations filters by name locally', () async {
      local.cached = const [
        RadioStation(id: '1', name: 'Mishary', streamUrl: 'https://a'),
        RadioStation(id: '2', name: 'Sudais', streamUrl: 'https://b'),
      ];
      await repository.getStations(language: 'eng');

      final result = await repository.searchStations('sud');
      check(result.getOrElse(() => const []).single.name).equals('Sudais');
    });

    test('toggleFavorite persists and logs analytics', () async {
      remote.stations = [
        const RadioStationDto(id: 1, name: 'A', url: 'https://a'),
      ];
      final loaded = await repository.refreshStations(language: 'eng');
      check(loaded.isRight()).equals(true);

      final result = await repository.toggleFavorite('1');
      check(result.isRight()).equals(true);
      check(
        result.getOrElse(() => throw StateError('right')).isFavorite,
      ).equals(true);
      check(local.favoriteIds).deepEquals(['1']);
      check(
        analytics.events.any((e) => e == AnalyticsEvents.radioFavorite),
      ).equals(true);

      final removed = await repository.toggleFavorite('1');
      check(removed.isRight()).equals(true);
      check(
        removed.getOrElse(() => throw StateError('right')).isFavorite,
      ).equals(false);
      check(local.favoriteIds).deepEquals(<String>[]);
    });

    test('addRecentStation caps at 20 and keeps most recent first', () async {
      for (int i = 0; i < 25; i++) {
        await repository.addRecentStation(
          RadioStation(
            id: '$i',
            name: 'S$i',
            streamUrl: 'https://x/$i',
          ),
        );
      }
      final recent = await repository.getRecentStations();
      final list = recent.getOrElse(() => const []);
      check(list.length).equals(20);
      check(list.first.id).equals('24');
      check(list.last.id).equals('5');
    });
  });
}

class _FakeRemote implements RadioRemoteDataSource {
  List<RadioStationDto> stations = const [];
  DioException? throwDio;

  @override
  Future<List<RadioStationDto>> fetchStations({
    required String language,
    DateTime? after,
  }) async {
    final DioException? error = throwDio;
    if (error != null) throw error;
    return stations;
  }
}

class _FakeLocal implements RadioLocalDataSource {
  List<RadioStation> cached = const [];
  List<String> favoriteIds = <String>[];
  List<RadioStation> recent = <RadioStation>[];
  DateTime? fetchedAt;

  @override
  Future<List<RadioStation>> getCachedStations() async => cached;

  @override
  Future<void> saveCachedStations(List<RadioStation> stations) async {
    cached = stations;
    fetchedAt = DateTime.now();
  }

  @override
  Future<DateTime?> getCacheFetchedAt() async => fetchedAt;

  @override
  Future<List<String>> getFavoriteIds() async => favoriteIds;

  @override
  Future<void> saveFavoriteIds(List<String> ids) async {
    favoriteIds = List<String>.from(ids);
  }

  @override
  Future<List<RadioStation>> getRecentStations() async => recent;

  @override
  Future<void> saveRecentStations(List<RadioStation> stations) async {
    recent = List<RadioStation>.from(stations);
  }
}

class _FakeConnectivity implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [
    ConnectivityResult.wifi,
  ];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}
