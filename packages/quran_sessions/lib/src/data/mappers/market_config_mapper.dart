import '../../domain/entities/manual_payment_market_config.dart';
import '../../domain/entities/market_config.dart';
import '../dtos/market_country_dto.dart';
import '../dtos/market_config_dto.dart';

extension MarketConfigDtoMapper on MarketConfigDto {
  MarketConfig toDomain() => MarketConfig(
    countryCode: countryCode,
    countryName: countryName,
    currencyCode: currencyCode,
    defaultCityId: defaultCityId,
    cities: cities.map((c) => c.toDomain()).toList(),
    isEnabled: isEnabled,
    minSessionPrice: minSessionPrice,
    maxSessionPrice: maxSessionPrice,
    platformCommissionPercent: platformCommissionPercent,
    manualPayment: _manualPaymentToDomain(),
  );

  /// Builds the manual-payment value object from the market doc fields.
  /// Returns null when the market has no manual-payment block configured.
  ManualPaymentMarketConfig? _manualPaymentToDomain() {
    final whatsapp = supportWhatsappNumber?.trim();
    if (!manualPaymentEnabled || whatsapp == null || whatsapp.isEmpty) {
      return null;
    }
    return ManualPaymentMarketConfig(
      currencyCode: currencyCode,
      supportWhatsappNumber: whatsapp,
      instapayHandle: instapayHandle?.trim(),
      instapayPaymentLink: instapayPaymentLink?.trim(),
      recipientMaskedName: recipientMaskedName?.trim(),
      vodafoneCashNumber: vodafoneCashNumber?.trim(),
    );
  }
}

extension CityConfigDtoMapper on CityConfigDto {
  CityConfig toDomain() => CityConfig(
    cityId: cityId,
    cityName: cityName,
    countryCode: countryCode,
    timezone: timezone,
    currencyCode: currencyCode,
    isEnabled: isEnabled,
    minSessionPrice: minSessionPrice,
    maxSessionPrice: maxSessionPrice,
  );

  MarketCityDto toMarketCityDto() => MarketCityDto(
    cityId: cityId,
    cityName: cityName,
    cityNameEn: cityNameEn,
    countryCode: countryCode,
    timezone: timezone,
    currencyCode: currencyCode,
    isEnabled: isEnabled,
    sortOrder: sortOrder,
    minSessionPrice: minSessionPrice,
  );
}
