import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

/// Firestore document for `quran_session_market_configs/{countryCode}`.
class FirestoreMarketConfigDto {
  const FirestoreMarketConfigDto({
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.defaultCityId,
    required this.isEnabled,
    required this.minSessionPrice,
    required this.maxSessionPrice,
    required this.platformCommissionPercent,
    this.minimumStudentAgeYears,
    this.minimumTeacherAgeYears,
    this.cities = const [],
  });

  final String countryCode;
  final String countryName;
  final String currencyCode;
  final String defaultCityId;
  final bool isEnabled;
  final double minSessionPrice;
  final double maxSessionPrice;
  final double platformCommissionPercent;
  final int? minimumStudentAgeYears;
  final int? minimumTeacherAgeYears;
  final List<CityConfigDto> cities;

  factory FirestoreMarketConfigDto.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    List<CityConfigDto> cities,
  ) {
    final data = doc.data() ?? const {};
    return FirestoreMarketConfigDto(
      countryCode: data['countryCode'] as String? ?? doc.id,
      countryName: data['countryName'] as String? ?? doc.id,
      currencyCode: data['currencyCode'] as String? ?? 'USD',
      defaultCityId: data['defaultCityId'] as String? ?? cities.first.cityId,
      isEnabled: data['isEnabled'] as bool? ?? true,
      minSessionPrice: (data['minSessionPrice'] as num?)?.toDouble() ?? 0,
      maxSessionPrice: (data['maxSessionPrice'] as num?)?.toDouble() ?? 0,
      platformCommissionPercent:
          (data['platformCommissionPercent'] as num?)?.toDouble() ?? 0,
      minimumStudentAgeYears: data['minimumStudentAgeYears'] as int?,
      minimumTeacherAgeYears: data['minimumTeacherAgeYears'] as int?,
      cities: cities,
    );
  }

  MarketConfigDto toTransportDto() => MarketConfigDto(
    countryCode: countryCode,
    countryName: countryName,
    currencyCode: currencyCode,
    defaultCityId: defaultCityId.isNotEmpty
        ? defaultCityId
        : (cities.isNotEmpty ? cities.first.cityId : ''),
    cities: cities,
    isEnabled: isEnabled,
    minSessionPrice: minSessionPrice,
    maxSessionPrice: maxSessionPrice,
    platformCommissionPercent: platformCommissionPercent,
    minimumStudentAgeYears: minimumStudentAgeYears,
    minimumTeacherAgeYears: minimumTeacherAgeYears,
  );
}

class FirestoreMarketConfigDataSource implements MarketConfigRemoteDataSource {
  FirestoreMarketConfigDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _markets =>
      _firestore.collection(
        FirestoreQuranSessionsPaths.marketConfigs,
      );

  Future<List<CityConfigDto>> _loadCities(String countryCode) async {
    final snapshot = await _markets
        .doc(countryCode)
        .collection(FirestoreQuranSessionsPaths.cities)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return CityConfigDto(
        cityId: data['cityId'] as String? ?? doc.id,
        cityName: data['cityName'] as String? ?? doc.id,
        countryCode: countryCode,
        timezone: data['timezone'] as String? ?? 'UTC',
        currencyCode: data['currencyCode'] as String? ?? 'USD',
        isEnabled: data['isEnabled'] as bool? ?? true,
        minSessionPrice: (data['minSessionPrice'] as num?)?.toDouble(),
        maxSessionPrice: (data['maxSessionPrice'] as num?)?.toDouble(),
      );
    }).toList();
  }

  @override
  Future<MarketConfigDto> getMarketConfig(String countryCode) async {
    try {
      final doc = await _markets.doc(countryCode).get();
      if (!doc.exists) {
        throw NotFoundException('MarketConfig($countryCode)');
      }
      final cities = await _loadCities(countryCode);
      return FirestoreMarketConfigDto.fromDoc(doc, cities).toTransportDto();
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<List<MarketConfigDto>> getSupportedMarkets() async {
    try {
      final snapshot = await _markets.get();
      final markets = <MarketConfigDto>[];
      for (final doc in snapshot.docs) {
        final cities = await _loadCities(doc.id);
        markets.add(
          FirestoreMarketConfigDto.fromDoc(doc, cities).toTransportDto(),
        );
      }
      return markets;
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }

  @override
  Future<CityConfigDto> getCityConfig(
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
      final data = doc.data() ?? const {};
      return CityConfigDto(
        cityId: data['cityId'] as String? ?? doc.id,
        cityName: data['cityName'] as String? ?? doc.id,
        countryCode: countryCode,
        timezone: data['timezone'] as String? ?? 'UTC',
        currencyCode: data['currencyCode'] as String? ?? 'USD',
        isEnabled: data['isEnabled'] as bool? ?? true,
        minSessionPrice: (data['minSessionPrice'] as num?)?.toDouble(),
        maxSessionPrice: (data['maxSessionPrice'] as num?)?.toDouble(),
      );
    } on FirebaseException catch (e) {
      throw mapFirebaseException(e);
    }
  }
}
