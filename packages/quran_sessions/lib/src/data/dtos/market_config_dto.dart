class CityConfigDto {
  const CityConfigDto({
    required this.cityId,
    required this.cityName,
    required this.countryCode,
    required this.timezone,
    required this.currencyCode,
    required this.isEnabled,
    this.cityNameEn,
    this.sortOrder = 0,
    this.minSessionPrice,
    this.maxSessionPrice,
  });

  final String cityId;
  final String cityName;
  final String? cityNameEn;
  final String countryCode;
  final String timezone;
  final String currencyCode;
  final bool isEnabled;
  final int sortOrder;
  final double? minSessionPrice;
  final double? maxSessionPrice;
}

class MarketConfigDto {
  const MarketConfigDto({
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.defaultCityId,
    required this.cities,
    required this.isEnabled,
    required this.minSessionPrice,
    required this.maxSessionPrice,
    required this.platformCommissionPercent,
    this.countryNameEn,
    this.timezone,
    this.phoneCode,
    this.flagEmoji,
    this.sortOrder = 0,
    this.minimumStudentAgeYears,
    this.minimumTeacherAgeYears,
    this.manualPaymentEnabled = false,
    this.supportWhatsappNumber,
    this.instapayHandle,
    this.instapayPaymentLink,
    this.recipientMaskedName,
    this.vodafoneCashNumber,
  });

  final String countryCode;
  final String countryName;
  final String? countryNameEn;
  final String currencyCode;
  final String? timezone;
  final String? phoneCode;
  final String? flagEmoji;
  final String defaultCityId;
  final List<CityConfigDto> cities;
  final bool isEnabled;
  final int sortOrder;
  final double minSessionPrice;
  final double maxSessionPrice;
  final double platformCommissionPercent;
  final int? minimumStudentAgeYears;
  final int? minimumTeacherAgeYears;

  // Manual / off-app payment block (per-market Firestore doc fields).
  final bool manualPaymentEnabled;
  final String? supportWhatsappNumber;
  final String? instapayHandle;
  final String? instapayPaymentLink;
  final String? recipientMaskedName;
  final String? vodafoneCashNumber;
}
