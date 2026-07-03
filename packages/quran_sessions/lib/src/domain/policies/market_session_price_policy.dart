import '../entities/market_config.dart';
import '../entities/session_price.dart';
import '../entities/session_pricing_type.dart';

/// Resolves session price preview from admin market config only (Q-FE-01/02).
abstract final class MarketSessionPricePolicy {
  /// Preview price for booking UI — never from teacher listing or client defaults.
  static ({SessionPricingType pricingType, SessionPrice? price})
  resolvePreview({
    required MarketConfig market,
    required String cityId,
  }) {
    final city = market.cityById(cityId);
    final amount = city?.minSessionPrice ?? market.minSessionPrice;
    if (amount <= 0) {
      return (pricingType: SessionPricingType.free, price: null);
    }
    return (
      pricingType: SessionPricingType.fixedPerSession,
      price: SessionPrice(
        amount: amount,
        currencyCode: market.currencyCode,
        countryCode: market.countryCode,
        cityId: cityId,
      ),
    );
  }
}
