import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

Map<String, dynamic> _countryDoc(MarketCountry country, MarketConfig config) =>
    {
      'countryCode': country.countryCode,
      'countryName': country.countryName,
      'countryNameAr': country.countryName,
      'countryNameEn': country.countryNameEn,
      'currencyCode': country.currencyCode,
      'timezone': country.timezone,
      'phoneCode': country.phoneCode,
      'flagEmoji': country.flagEmoji,
      'minimumStudentAgeYears': 3,
      'minimumTeacherAgeYears': 18,
      'isEnabled': country.isEnabled,
      'sortOrder': country.sortOrder,
      'defaultCityId': config.defaultCityId,
      'minSessionPrice': config.minSessionPrice,
      'maxSessionPrice': config.maxSessionPrice,
      'platformCommissionPercent': config.platformCommissionPercent,
      'updatedAt': FieldValue.serverTimestamp(),
    };

Map<String, dynamic> _cityDoc(MarketCity city) => {
  'cityId': city.cityId,
  'cityName': city.cityName,
  'cityNameAr': city.cityName,
  'cityNameEn': city.cityNameEn,
  'timezone': city.timezone,
  'currencyCode': city.currencyCode,
  'isEnabled': city.isEnabled,
  'sortOrder': city.sortOrder,
  'updatedAt': FieldValue.serverTimestamp(),
};

MarketCountryDto _countryFromDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data() ?? const {};
  return MarketCountryDto(
    countryCode: data['countryCode'] as String? ?? doc.id,
    countryName:
        data['countryNameAr'] as String? ??
        data['countryName'] as String? ??
        doc.id,
    countryNameEn: data['countryNameEn'] as String?,
    currencyCode: data['currencyCode'] as String? ?? 'USD',
    timezone: data['timezone'] as String? ?? 'UTC',
    phoneCode: data['phoneCode'] as String?,
    flagEmoji: data['flagEmoji'] as String?,
    isEnabled: data['isEnabled'] as bool? ?? false,
    sortOrder: data['sortOrder'] as int? ?? 0,
  );
}

MarketCityDto _cityFromDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
  String countryCode,
) {
  final data = doc.data() ?? const {};
  return MarketCityDto(
    cityId: data['cityId'] as String? ?? doc.id,
    cityName:
        data['cityNameAr'] as String? ?? data['cityName'] as String? ?? doc.id,
    cityNameEn: data['cityNameEn'] as String?,
    countryCode: countryCode,
    timezone: data['timezone'] as String? ?? 'UTC',
    currencyCode: data['currencyCode'] as String? ?? 'USD',
    isEnabled: data['isEnabled'] as bool? ?? false,
    sortOrder: data['sortOrder'] as int? ?? 0,
  );
}

class FirestoreMarketConfigDataSource implements MarketConfigRemoteDataSource {
  FirestoreMarketConfigDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _markets =>
      _firestore.collection(FirestoreQuranSessionsPaths.marketConfigs);

  @override
  Future<List<MarketCountryDto>> getSupportedCountries() async {
    try {
      final snapshot = await _markets
          .where('isEnabled', isEqualTo: true)
          .orderBy('sortOrder')
          .get();
      return snapshot.docs.map(_countryFromDoc).toList();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<List<MarketCityDto>> getCitiesByCountryCode(
    String countryCode,
  ) async {
    try {
      final countryDoc = await _markets.doc(countryCode).get();
      if (!countryDoc.exists) {
        throw NotFoundException('MarketCountry($countryCode)');
      }
      final snapshot = await _markets
          .doc(countryCode)
          .collection(FirestoreQuranSessionsPaths.cities)
          .where('isEnabled', isEqualTo: true)
          .orderBy('sortOrder')
          .get();
      return snapshot.docs
          .map((doc) => _cityFromDoc(doc, countryCode))
          .toList();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<MarketConfigDto> getMarketConfig(String countryCode) async {
    try {
      final doc = await _markets.doc(countryCode).get();
      if (!doc.exists) {
        throw NotFoundException('MarketConfig($countryCode)');
      }
      final cities = await getCitiesByCountryCode(countryCode);
      final data = doc.data() ?? const {};
      return MarketConfigDto(
        countryCode: data['countryCode'] as String? ?? doc.id,
        countryName:
            data['countryNameAr'] as String? ??
            data['countryName'] as String? ??
            doc.id,
        countryNameEn: data['countryNameEn'] as String?,
        currencyCode: data['currencyCode'] as String? ?? 'USD',
        timezone: data['timezone'] as String?,
        phoneCode: data['phoneCode'] as String?,
        flagEmoji: data['flagEmoji'] as String?,
        defaultCityId: data['defaultCityId'] as String? ?? cities.first.cityId,
        cities: cities
            .map(
              (c) => CityConfigDto(
                cityId: c.cityId,
                cityName: c.cityName,
                cityNameEn: c.cityNameEn,
                countryCode: c.countryCode,
                timezone: c.timezone,
                currencyCode: c.currencyCode,
                isEnabled: c.isEnabled,
                sortOrder: c.sortOrder,
              ),
            )
            .toList(),
        isEnabled: data['isEnabled'] as bool? ?? true,
        sortOrder: data['sortOrder'] as int? ?? 0,
        minSessionPrice: (data['minSessionPrice'] as num?)?.toDouble() ?? 0,
        maxSessionPrice: (data['maxSessionPrice'] as num?)?.toDouble() ?? 0,
        platformCommissionPercent:
            (data['platformCommissionPercent'] as num?)?.toDouble() ?? 0,
        minimumStudentAgeYears: data['minimumStudentAgeYears'] as int?,
        minimumTeacherAgeYears: data['minimumTeacherAgeYears'] as int?,
      );
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<List<MarketConfigDto>> getSupportedMarkets() async {
    final countries = await getSupportedCountries();
    final markets = <MarketConfigDto>[];
    for (final country in countries) {
      markets.add(await getMarketConfig(country.countryCode));
    }
    return markets;
  }

  @override
  Future<MarketCityDto> getCityConfig(
    String countryCode,
    String cityId,
  ) async {
    try {
      final doc = await _markets
          .doc(countryCode)
          .collection(FirestoreQuranSessionsPaths.cities)
          .doc(cityId)
          .get();
      if (!doc.exists) {
        throw NotFoundException('CityConfig($countryCode/$cityId)');
      }
      return _cityFromDoc(doc, countryCode);
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }
}

/// One-time uploader for curated MVP markets into Firestore.
///
/// Run from a debug/admin entry point or `dart run tool/seed_market_configs.dart`.
class FirestoreMarketConfigSeeder {
  FirestoreMarketConfigSeeder(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> seedDefaultCatalog() async {
    final batch = _firestore.batch();
    final markets = _firestore.collection(
      FirestoreQuranSessionsPaths.marketConfigs,
    );

    for (final country in DefaultMarketCatalog.enabledCountries) {
      final config = DefaultMarketCatalog.marketConfigFor(country.countryCode);
      final countryRef = markets.doc(country.countryCode);
      batch.set(
        countryRef,
        _countryDoc(country, config),
        SetOptions(merge: true),
      );

      for (final city in DefaultMarketCatalog.enabledCitiesFor(
        country.countryCode,
      )) {
        final cityRef = countryRef
            .collection(FirestoreQuranSessionsPaths.cities)
            .doc(city.cityId);
        batch.set(cityRef, _cityDoc(city), SetOptions(merge: true));
      }
    }

    await batch.commit();
  }
}
