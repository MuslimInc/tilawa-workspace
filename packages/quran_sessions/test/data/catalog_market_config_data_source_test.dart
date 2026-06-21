import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/data/datasources/catalog_market_config_remote_data_source.dart';
import 'package:quran_sessions/src/data/exceptions/remote_exception.dart';
import 'package:quran_sessions/src/data/seed/default_market_catalog.dart';

void main() {
  const dataSource = CatalogMarketConfigRemoteDataSource();

  group('CatalogMarketConfigRemoteDataSource', () {
    test('getSupportedCountries returns enabled countries sorted', () async {
      final countries = await dataSource.getSupportedCountries();

      check(countries.map((c) => c.countryCode).toList()).deepEquals(
        ['EG', 'SA', 'AE'],
      );
      check(countries.every((c) => c.isEnabled)).isTrue();
    });

    test('getCitiesByCountryCode returns Egypt cities', () async {
      final cities = await dataSource.getCitiesByCountryCode('EG');

      check(cities.length).equals(10);
      check(cities.first.cityId).equals('cairo');
      check(cities.every((c) => c.countryCode == 'EG')).isTrue();
    });

    test('getCitiesByCountryCode throws for unknown country', () {
      expect(
        () => dataSource.getCitiesByCountryCode('XX'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('getMarketConfig uses O(1) country lookup by code', () async {
      final config = await dataSource.getMarketConfig('EG');

      check(config.countryCode).equals('EG');
      check(config.cities).isNotEmpty();
    });

    test('getCityConfig returns cairo for EG', () async {
      final city = await dataSource.getCityConfig('EG', 'cairo');

      check(city.cityId).equals('cairo');
      check(city.cityName).equals('القاهرة');
    });

    test('getCityConfig throws for missing city', () {
      expect(
        () => dataSource.getCityConfig('EG', 'unknown'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('catalog matches DefaultMarketCatalog enabled lists', () async {
      final countries = await dataSource.getSupportedCountries();
      check(
        countries.length,
      ).equals(DefaultMarketCatalog.enabledCountries.length);

      for (final country in DefaultMarketCatalog.enabledCountries) {
        final cities = await dataSource.getCitiesByCountryCode(
          country.countryCode,
        );
        check(cities.length).equals(
          DefaultMarketCatalog.enabledCitiesFor(country.countryCode).length,
        );
      }
    });
  });
}
