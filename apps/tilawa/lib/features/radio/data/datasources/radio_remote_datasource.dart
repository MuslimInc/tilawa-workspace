import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/config/api_config.dart';

import '../models/radio_station_dto.dart';

abstract class RadioRemoteDataSource {
  Future<List<RadioStationDto>> fetchStations({
    required String language,
    DateTime? after,
  });
}

@LazySingleton(as: RadioRemoteDataSource)
class RadioRemoteDataSourceImpl implements RadioRemoteDataSource {
  const RadioRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<RadioStationDto>> fetchStations({
    required String language,
    DateTime? after,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{
      'language': language,
    };
    if (after != null) {
      // Reserved for future incremental sync (API recent_date filter).
      query['last_update'] = after.toIso8601String();
    }
    final Response<dynamic> response = await _dio.get(
      ApiConfig.radiosPath,
      queryParameters: query,
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['radios'] as List<dynamic>? ?? const <dynamic>[];
    return list
        .map((e) => RadioStationDto.fromJson(e as Map<String, dynamic>))
        .where((dto) => dto.url.isNotEmpty && dto.name.isNotEmpty)
        .toList();
  }
}
