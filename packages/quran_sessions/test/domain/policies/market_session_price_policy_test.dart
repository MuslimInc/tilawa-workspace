import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';

void main() {
  group('MarketSessionPricePolicy', () {
    test('returns free preview when market min price is zero', () {
      const market = MarketConfig(
        countryCode: 'EG',
        countryName: 'Egypt',
        currencyCode: 'EGP',
        defaultCityId: 'cairo',
        isEnabled: true,
        cities: [],
        minSessionPrice: 0,
        maxSessionPrice: 0,
        platformCommissionPercent: 0,
      );

      final preview = MarketSessionPricePolicy.resolvePreview(
        market: market,
        cityId: 'cairo',
      );

      check(preview.pricingType).equals(SessionPricingType.free);
      check(preview.price).isNull();
    });

    test('returns fixed price from market config only', () {
      const market = MarketConfig(
        countryCode: 'EG',
        countryName: 'Egypt',
        currencyCode: 'EGP',
        defaultCityId: 'cairo',
        isEnabled: true,
        cities: [],
        minSessionPrice: 150,
        maxSessionPrice: 150,
        platformCommissionPercent: 10,
      );

      final preview = MarketSessionPricePolicy.resolvePreview(
        market: market,
        cityId: 'cairo',
      );

      check(preview.pricingType).equals(SessionPricingType.fixedPerSession);
      check(preview.price!.amount).equals(150);
      check(preview.price!.currencyCode).equals('EGP');
    });
  });
}
