import '../../domain/entities/market_city.dart';
import '../../domain/entities/market_config.dart';
import '../../domain/entities/market_country.dart';

/// Curated enabled markets for MVP — single source for fake repos and Firestore
/// seeding. Not used by presentation directly.
abstract final class DefaultMarketCatalog {
  static const List<MarketCountry> countries = [
    MarketCountry(
      countryCode: 'EG',
      countryName: 'مصر',
      countryNameEn: 'Egypt',
      currencyCode: 'EGP',
      timezone: 'Africa/Cairo',
      phoneCode: '+20',
      flagEmoji: '🇪🇬',
      isEnabled: true,
      sortOrder: 10,
    ),
    MarketCountry(
      countryCode: 'SA',
      countryName: 'السعودية',
      countryNameEn: 'Saudi Arabia',
      currencyCode: 'SAR',
      timezone: 'Asia/Riyadh',
      phoneCode: '+966',
      flagEmoji: '🇸🇦',
      // Disabled for this release — availability is config-gated to EG only.
      isEnabled: false,
      sortOrder: 20,
    ),
    MarketCountry(
      countryCode: 'AE',
      countryName: 'الإمارات',
      countryNameEn: 'United Arab Emirates',
      currencyCode: 'AED',
      timezone: 'Asia/Dubai',
      phoneCode: '+971',
      flagEmoji: '🇦🇪',
      // Disabled for this release — availability is config-gated to EG only.
      isEnabled: false,
      sortOrder: 30,
    ),
  ];

  static const List<MarketCity> cities = [
    // Egypt
    MarketCity(
      cityId: 'cairo',
      cityName: 'القاهرة',
      cityNameEn: 'Cairo',
      countryCode: 'EG',
      timezone: 'Africa/Cairo',
      currencyCode: 'EGP',
      isEnabled: true,
      sortOrder: 10,
    ),
    MarketCity(
      cityId: 'alexandria',
      cityName: 'الإسكندرية',
      cityNameEn: 'Alexandria',
      countryCode: 'EG',
      timezone: 'Africa/Cairo',
      currencyCode: 'EGP',
      isEnabled: true,
      sortOrder: 20,
    ),
    MarketCity(
      cityId: 'giza',
      cityName: 'الجيزة',
      cityNameEn: 'Giza',
      countryCode: 'EG',
      timezone: 'Africa/Cairo',
      currencyCode: 'EGP',
      isEnabled: true,
      sortOrder: 30,
    ),
    MarketCity(
      cityId: 'mansoura',
      cityName: 'المنصورة',
      cityNameEn: 'Mansoura',
      countryCode: 'EG',
      timezone: 'Africa/Cairo',
      currencyCode: 'EGP',
      isEnabled: true,
      sortOrder: 40,
    ),
    MarketCity(
      cityId: 'tanta',
      cityName: 'طنطا',
      cityNameEn: 'Tanta',
      countryCode: 'EG',
      timezone: 'Africa/Cairo',
      currencyCode: 'EGP',
      isEnabled: true,
      sortOrder: 50,
    ),
    MarketCity(
      cityId: 'minya',
      cityName: 'المنيا',
      cityNameEn: 'Minya',
      countryCode: 'EG',
      timezone: 'Africa/Cairo',
      currencyCode: 'EGP',
      isEnabled: true,
      sortOrder: 60,
    ),
    MarketCity(
      cityId: 'assiut',
      cityName: 'أسيوط',
      cityNameEn: 'Assiut',
      countryCode: 'EG',
      timezone: 'Africa/Cairo',
      currencyCode: 'EGP',
      isEnabled: true,
      sortOrder: 70,
    ),
    MarketCity(
      cityId: 'sohag',
      cityName: 'سوهاج',
      cityNameEn: 'Sohag',
      countryCode: 'EG',
      timezone: 'Africa/Cairo',
      currencyCode: 'EGP',
      isEnabled: true,
      sortOrder: 80,
    ),
    MarketCity(
      cityId: 'aswan',
      cityName: 'أسوان',
      cityNameEn: 'Aswan',
      countryCode: 'EG',
      timezone: 'Africa/Cairo',
      currencyCode: 'EGP',
      isEnabled: true,
      sortOrder: 90,
    ),
    MarketCity(
      cityId: 'luxor',
      cityName: 'الأقصر',
      cityNameEn: 'Luxor',
      countryCode: 'EG',
      timezone: 'Africa/Cairo',
      currencyCode: 'EGP',
      isEnabled: true,
      sortOrder: 100,
    ),
    // Saudi Arabia
    MarketCity(
      cityId: 'riyadh',
      cityName: 'الرياض',
      cityNameEn: 'Riyadh',
      countryCode: 'SA',
      timezone: 'Asia/Riyadh',
      currencyCode: 'SAR',
      isEnabled: true,
      sortOrder: 10,
    ),
    MarketCity(
      cityId: 'jeddah',
      cityName: 'جدة',
      cityNameEn: 'Jeddah',
      countryCode: 'SA',
      timezone: 'Asia/Riyadh',
      currencyCode: 'SAR',
      isEnabled: true,
      sortOrder: 20,
    ),
    MarketCity(
      cityId: 'makkah',
      cityName: 'مكة',
      cityNameEn: 'Makkah',
      countryCode: 'SA',
      timezone: 'Asia/Riyadh',
      currencyCode: 'SAR',
      isEnabled: true,
      sortOrder: 30,
    ),
    MarketCity(
      cityId: 'madinah',
      cityName: 'المدينة',
      cityNameEn: 'Madinah',
      countryCode: 'SA',
      timezone: 'Asia/Riyadh',
      currencyCode: 'SAR',
      isEnabled: true,
      sortOrder: 40,
    ),
    MarketCity(
      cityId: 'dammam',
      cityName: 'الدمام',
      cityNameEn: 'Dammam',
      countryCode: 'SA',
      timezone: 'Asia/Riyadh',
      currencyCode: 'SAR',
      isEnabled: true,
      sortOrder: 50,
    ),
    // UAE
    MarketCity(
      cityId: 'dubai',
      cityName: 'دبي',
      cityNameEn: 'Dubai',
      countryCode: 'AE',
      timezone: 'Asia/Dubai',
      currencyCode: 'AED',
      isEnabled: true,
      sortOrder: 10,
    ),
    MarketCity(
      cityId: 'abu_dhabi',
      cityName: 'أبوظبي',
      cityNameEn: 'Abu Dhabi',
      countryCode: 'AE',
      timezone: 'Asia/Dubai',
      currencyCode: 'AED',
      isEnabled: true,
      sortOrder: 20,
    ),
    MarketCity(
      cityId: 'sharjah',
      cityName: 'الشارقة',
      cityNameEn: 'Sharjah',
      countryCode: 'AE',
      timezone: 'Asia/Dubai',
      currencyCode: 'AED',
      isEnabled: true,
      sortOrder: 30,
    ),
    MarketCity(
      cityId: 'ajman',
      cityName: 'عجمان',
      cityNameEn: 'Ajman',
      countryCode: 'AE',
      timezone: 'Asia/Dubai',
      currencyCode: 'AED',
      isEnabled: true,
      sortOrder: 40,
    ),
  ];

  static List<MarketCity> enabledCitiesFor(String countryCode) =>
      cities.where((c) => c.countryCode == countryCode && c.isEnabled).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  static List<MarketCountry> get enabledCountries =>
      countries.where((c) => c.isEnabled).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  static MarketConfig marketConfigFor(String countryCode) {
    final country = countries.firstWhere((c) => c.countryCode == countryCode);
    final countryCities = enabledCitiesFor(countryCode);
    return MarketConfig(
      countryCode: country.countryCode,
      countryName: country.countryName,
      currencyCode: country.currencyCode,
      defaultCityId: countryCities.first.cityId,
      isEnabled: country.isEnabled,
      minSessionPrice: 100,
      maxSessionPrice: 2000,
      platformCommissionPercent: 15,
      cities: countryCities
          .map(
            (c) => CityConfig(
              cityId: c.cityId,
              cityName: c.cityName,
              countryCode: c.countryCode,
              timezone: c.timezone,
              currencyCode: c.currencyCode,
              isEnabled: c.isEnabled,
            ),
          )
          .toList(),
    );
  }

  static List<MarketConfig> get allMarketConfigs =>
      enabledCountries.map((c) => marketConfigFor(c.countryCode)).toList();
}
