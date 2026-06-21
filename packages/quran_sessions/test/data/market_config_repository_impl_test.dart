import 'package:checks/checks.dart';
import 'package:quran_sessions/src/data/datasources/market_config_remote_data_source.dart';
import 'package:quran_sessions/src/data/dtos/market_config_dto.dart';
import 'package:quran_sessions/src/data/dtos/market_country_dto.dart';
import 'package:quran_sessions/src/data/repositories/market_config_repository_impl.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:test/test.dart';

class _EmptyCountriesDataSource implements MarketConfigRemoteDataSource {
  const _EmptyCountriesDataSource();
  @override
  Future<List<MarketCountryDto>> getSupportedCountries() async => [];

  @override
  Future<List<MarketCityDto>> getCitiesByCountryCode(
    String countryCode,
  ) async => [];

  @override
  Future<MarketConfigDto> getMarketConfig(String countryCode) =>
      throw UnimplementedError();

  @override
  Future<List<MarketConfigDto>> getSupportedMarkets() =>
      throw UnimplementedError();

  @override
  Future<MarketCityDto> getCityConfig(String countryCode, String cityId) =>
      throw UnimplementedError();
}

void main() {
  group('MarketConfigRepositoryImpl', () {
    test(
      'getSupportedCountries returns MarketCatalogEmptyFailure when empty',
      () async {
        const repo = MarketConfigRepositoryImpl(_EmptyCountriesDataSource());

        final result = await repo.getSupportedCountries();

        check(result.isLeft()).isTrue();
        result.fold(
          (failure) => check(failure).isA<MarketCatalogEmptyFailure>(),
          (_) => fail('expected Left'),
        );
      },
    );

    test(
      'getCitiesByCountryCode returns MarketCatalogEmptyFailure when empty',
      () async {
        const repo = MarketConfigRepositoryImpl(_EmptyCountriesDataSource());

        final result = await repo.getCitiesByCountryCode('EG');

        check(result.isLeft()).isTrue();
        result.fold(
          (failure) => check(failure).isA<MarketCatalogEmptyFailure>(),
          (_) => fail('expected Left'),
        );
      },
    );
  });
}
