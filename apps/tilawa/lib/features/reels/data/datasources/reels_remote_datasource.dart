import 'package:dio/dio.dart';
import 'package:tilawa_core/config/api_config.dart';

import '../models/reel_video_dto.dart';

abstract class ReelsRemoteDataSource {
  Future<List<ReelSheikhDto>> fetchVideos({required String language});
  Future<List<ReelVideoTypeDto>> fetchVideoTypes({required String language});
}

class ReelsRemoteDataSourceImpl implements ReelsRemoteDataSource {
  const ReelsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<ReelSheikhDto>> fetchVideos({required String language}) async {
    final Response<dynamic> response = await _dio.get(
      ApiConfig.videosPath,
      queryParameters: {'language': language},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['videos'] as List<dynamic>;
    return list
        .map((e) => ReelSheikhDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ReelVideoTypeDto>> fetchVideoTypes({
    required String language,
  }) async {
    final Response<dynamic> response = await _dio.get(
      ApiConfig.videoTypesPath,
      queryParameters: {'language': language},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['video_types'] as List<dynamic>;
    return list
        .map((e) => ReelVideoTypeDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
