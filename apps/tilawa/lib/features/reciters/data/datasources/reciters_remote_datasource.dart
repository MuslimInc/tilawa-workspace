import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/config/api_config.dart';
import '../models/reciter_model.dart';

abstract class RecitersRemoteDataSource {
  Future<List<ReciterModel>> getReciters({String? language});
}

@LazySingleton(as: RecitersRemoteDataSource)
class RecitersRemoteDataSourceImpl implements RecitersRemoteDataSource {
  const RecitersRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<ReciterModel>> getReciters({String? language}) async {
    try {
      final Response<dynamic> response = await _dio.get(
        ApiConfig.recitersPath,
        queryParameters: language == null || language.isEmpty
            ? null
            : {'language': language},
      );
      final data = response.data as Map<String, dynamic>;
      final reciters = data['reciters'] as List;

      return reciters
          .map((json) => ReciterModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reciters: $e');
    }
  }
}
