import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:dartz_plus/dartz_plus.dart';

import 'package:tilawa/features/radio/domain/entities/radio_station.dart';
import 'package:tilawa/features/radio/domain/repositories/radio_repository.dart';
import 'package:tilawa/features/radio/domain/usecases/get_radio_stations_use_case.dart';
import 'package:tilawa/features/radio/domain/usecases/search_radio_stations_use_case.dart';
import 'package:tilawa/features/radio/domain/usecases/toggle_radio_favorite_use_case.dart';
import 'package:tilawa_core/utils/typedefs.dart';

void main() {
  late _FakeRepo repo;

  setUp(() {
    repo = _FakeRepo();
  });

  test('GetRadioStationsUseCase delegates to repository', () async {
    repo.stations = const [
      RadioStation(id: '1', name: 'A', streamUrl: 'https://a'),
    ];
    final useCase = GetRadioStationsUseCase(repo);
    final result = await useCase(const GetRadioStationsParams(language: 'eng'));
    check(result.getOrElse(() => const []).single.name).equals('A');
    check(repo.lastLanguage).equals('eng');
  });

  test('SearchRadioStationsUseCase delegates query', () async {
    final useCase = SearchRadioStationsUseCase(repo);
    await useCase(const SearchRadioStationsParams('mish'));
    check(repo.lastQuery).equals('mish');
  });

  test('ToggleRadioFavoriteUseCase delegates id', () async {
    final useCase = ToggleRadioFavoriteUseCase(repo);
    final result = await useCase(const ToggleRadioFavoriteParams('9'));
    check(result.getOrElse(() => throw StateError('')).id).equals('9');
    check(repo.lastToggledId).equals('9');
  });
}

class _FakeRepo implements RadioRepository {
  List<RadioStation> stations = const [];
  String? lastLanguage;
  String? lastQuery;
  String? lastToggledId;

  @override
  ResultFuture<List<RadioStation>> getStations({
    required String language,
  }) async {
    lastLanguage = language;
    return Right(stations);
  }

  @override
  ResultFuture<List<RadioStation>> refreshStations({
    required String language,
    DateTime? after,
  }) async => Right(stations);

  @override
  ResultFuture<List<RadioStation>> searchStations(String query) async {
    lastQuery = query;
    return const Right([]);
  }

  @override
  ResultFuture<List<RadioStation>> getFavorites() async => const Right([]);

  @override
  ResultFuture<RadioStation> toggleFavorite(String stationId) async {
    lastToggledId = stationId;
    return Right(
      RadioStation(
        id: stationId,
        name: 'X',
        streamUrl: 'https://x',
        isFavorite: true,
      ),
    );
  }

  @override
  ResultFuture<List<RadioStation>> getRecentStations() async => const Right([]);

  @override
  ResultFuture<void> addRecentStation(RadioStation station) async =>
      const Right(null);
}
