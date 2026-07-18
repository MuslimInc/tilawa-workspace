import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:test/test.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import 'package:tilawa/features/radio/domain/entities/radio_station.dart';
import 'package:tilawa/features/radio/domain/repositories/radio_repository.dart';
import 'package:tilawa/features/radio/domain/usecases/add_recent_radio_station_use_case.dart';
import 'package:tilawa/features/radio/domain/usecases/get_radio_favorites_use_case.dart';
import 'package:tilawa/features/radio/domain/usecases/get_radio_stations_use_case.dart';
import 'package:tilawa/features/radio/domain/usecases/get_recent_radio_stations_use_case.dart';
import 'package:tilawa/features/radio/domain/usecases/refresh_radio_stations_use_case.dart';
import 'package:tilawa/features/radio/domain/usecases/search_radio_stations_use_case.dart';
import 'package:tilawa/features/radio/domain/usecases/toggle_radio_favorite_use_case.dart';
import 'package:tilawa/features/radio/presentation/cubit/radio_cubit.dart';
import 'package:tilawa/features/radio/presentation/cubit/radio_state.dart';
import '../../../support/recording_analytics_service.dart';

void main() {
  late _FakeRepo repo;
  late RecordingAnalyticsService analytics;
  late RadioCubit cubit;

  setUp(() {
    repo = _FakeRepo();
    analytics = RecordingAnalyticsService();
    cubit = RadioCubit(
      GetRadioStationsUseCase(repo),
      RefreshRadioStationsUseCase(repo),
      SearchRadioStationsUseCase(repo),
      GetRadioFavoritesUseCase(repo),
      ToggleRadioFavoriteUseCase(repo),
      GetRecentRadioStationsUseCase(repo),
      AddRecentRadioStationUseCase(repo),
      analytics,
      _FakeConnectivity(),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  blocTest<RadioCubit, RadioState>(
    'load emits loaded with featured Main Radio when present',
    build: () {
      repo.stations = const [
        RadioStation(id: '1', name: 'A', streamUrl: 'https://a'),
        RadioStation(id: '108', name: 'Main', streamUrl: 'https://main'),
      ];
      return cubit;
    },
    act: (c) => c.load(language: 'eng'),
    expect: () => [
      isA<RadioState>().having((s) => s.status, 'status', RadioStatus.loading),
      isA<RadioState>()
          .having((s) => s.status, 'status', RadioStatus.loaded)
          .having((s) => s.featured?.id, 'featured', '108')
          .having((s) => s.stations.length, 'count', 2),
    ],
  );

  blocTest<RadioCubit, RadioState>(
    'load emits empty when API returns no stations',
    build: () {
      repo.stations = const [];
      return cubit;
    },
    act: (c) => c.load(language: 'eng'),
    expect: () => [
      isA<RadioState>().having((s) => s.status, 'status', RadioStatus.loading),
      isA<RadioState>().having((s) => s.status, 'status', RadioStatus.empty),
    ],
  );

  test('playStation maps to radio AudioEntity and logs events', () async {
    repo.stations = const [
      RadioStation(id: '5', name: 'Mishary', streamUrl: 'https://m'),
    ];
    await cubit.load(language: 'eng');
    final audio = await cubit.playStation(repo.stations.first);
    check(audio.id).equals('radio:5');
    check(audio.url).equals('https://m');
    check(audio.extras?['source']).equals('radio');
    check(
      analytics.events.any((e) => e == AnalyticsEvents.radioPlay),
    ).equals(true);
    check(
      analytics.events.any((e) => e == AnalyticsEvents.radioStationOpened),
    ).equals(true);
  });

  test('search updates filteredStations', () async {
    repo.stations = const [
      RadioStation(id: '1', name: 'Alpha', streamUrl: 'https://a'),
      RadioStation(id: '2', name: 'Beta', streamUrl: 'https://b'),
    ];
    await cubit.load(language: 'eng');
    cubit.search('bet');
    await Future<void>.delayed(const Duration(milliseconds: 250));
    check(cubit.state.filteredStations.single.name).equals('Beta');
  });
}

class _FakeRepo implements RadioRepository {
  List<RadioStation> stations = const [];
  final List<RadioStation> recent = <RadioStation>[];
  final Set<String> favoriteIds = <String>{};

  @override
  ResultFuture<List<RadioStation>> getStations({
    required String language,
  }) async => Right(stations);

  @override
  ResultFuture<List<RadioStation>> refreshStations({
    required String language,
    DateTime? after,
  }) async => Right(stations);

  @override
  ResultFuture<List<RadioStation>> searchStations(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return Right(stations);
    return Right(
      stations.where((s) => s.name.toLowerCase().contains(q)).toList(),
    );
  }

  @override
  ResultFuture<List<RadioStation>> getFavorites() async => Right(
    stations
        .where((s) => favoriteIds.contains(s.id))
        .map((s) => s.copyWith(isFavorite: true))
        .toList(),
  );

  @override
  ResultFuture<RadioStation> toggleFavorite(String stationId) async {
    if (favoriteIds.contains(stationId)) {
      favoriteIds.remove(stationId);
    } else {
      favoriteIds.add(stationId);
    }
    final station = stations.firstWhere((s) => s.id == stationId);
    return Right(station.copyWith(isFavorite: favoriteIds.contains(stationId)));
  }

  @override
  ResultFuture<List<RadioStation>> getRecentStations() async => Right(recent);

  @override
  ResultFuture<void> addRecentStation(RadioStation station) async {
    recent.removeWhere((s) => s.id == station.id);
    recent.insert(0, station);
    return const Right(null);
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
