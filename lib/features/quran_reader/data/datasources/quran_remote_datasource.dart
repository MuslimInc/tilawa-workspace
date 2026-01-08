import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/entities.dart';

/// Data source for fetching Quran data from remote APIs.
///
/// Handles API calls for word-by-word data and other remote resources.
/// Follows Single Responsibility Principle by only handling remote data.
abstract class QuranRemoteDataSource {
  /// Fetches word-by-word data for a specific page.
  Future<Map<String, List<QuranWord>>> getPageWords(int pageNumber);
}

@LazySingleton(as: QuranRemoteDataSource)
class QuranRemoteDataSourceImpl implements QuranRemoteDataSource {
  QuranRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const String _baseUrl = 'https://api.quran.com/api/v4';

  @override
  Future<Map<String, List<QuranWord>>> getPageWords(int pageNumber) async {
    try {
      final Response<dynamic> response = await _dio.get(
        '$_baseUrl/verses/by_page/$pageNumber',
        queryParameters: {'words': true, 'word_fields': 'text_uthmani,code_v1'},
      );

      final data = response.data;

      if (data == null || data['verses'] == null) {
        return {};
      }

      final Map<String, List<QuranWord>> result = {};
      final verses = data['verses'] as List;

      for (final verse in verses) {
        final verseKey = verse['verse_key'] as String;
        final wordsData = verse['words'] as List?;

        if (wordsData != null) {
          final List<QuranWord> words = wordsData
              .map((w) => QuranWord.fromJson(w as Map<String, dynamic>))
              .toList();
          result[verseKey] = words;
        }
      }

      return result;
    } catch (e) {
      // In production, consider logging this error
      return {};
    }
  }
}
