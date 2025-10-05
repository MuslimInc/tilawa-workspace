import 'package:dio/dio.dart';
import 'package:muzakri/features/reciters/data/models/reciter_model.dart';

abstract class RecitersRemoteDataSource {
  Future<List<ReciterModel>> getReciters();
}

class RecitersRemoteDataSourceImpl implements RecitersRemoteDataSource {
  const RecitersRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<ReciterModel>> getReciters() async {
    try {
      final response = await _dio.get('/reciters');
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
