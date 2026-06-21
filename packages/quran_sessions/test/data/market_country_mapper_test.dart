import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/data/dtos/market_country_dto.dart';
import 'package:quran_sessions/src/data/mappers/market_country_mapper.dart';

void main() {
  group('MarketCountryDtoMapper', () {
    test('maps all fields to domain', () {
      const dto = MarketCountryDto(
        countryCode: 'EG',
        countryName: 'مصر',
        countryNameEn: 'Egypt',
        currencyCode: 'EGP',
        timezone: 'Africa/Cairo',
        phoneCode: '+20',
        flagEmoji: '🇪🇬',
        isEnabled: true,
        sortOrder: 10,
      );

      final domain = dto.toDomain();

      check(domain.countryCode).equals('EG');
      check(domain.countryName).equals('مصر');
      check(domain.countryNameEn).equals('Egypt');
      check(domain.flagEmoji).equals('🇪🇬');
      check(domain.isEnabled).isTrue();
    });
  });

  group('MarketCityDtoMapper', () {
    test('maps all fields to domain', () {
      const dto = MarketCityDto(
        cityId: 'cairo',
        cityName: 'القاهرة',
        cityNameEn: 'Cairo',
        countryCode: 'EG',
        timezone: 'Africa/Cairo',
        currencyCode: 'EGP',
        isEnabled: true,
        sortOrder: 10,
      );

      final domain = dto.toDomain();

      check(domain.cityId).equals('cairo');
      check(domain.cityName).equals('القاهرة');
      check(domain.countryCode).equals('EG');
    });
  });
}
