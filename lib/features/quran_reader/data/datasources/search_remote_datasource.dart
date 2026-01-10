import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

class RemoteSearchResult {
  RemoteSearchResult({required this.verseKey, this.text, this.translation});
  final String verseKey;
  final String? text;
  final String? translation;
}

@injectable
class SearchRemoteDataSource {
  SearchRemoteDataSource(this._dio);

  final Dio _dio;
  static const String _baseUrl = 'https://api.quran.foundation/api/v4/search';

  Future<List<RemoteSearchResult>> search(String query) async {
    try {
      final Response<dynamic> response = await _dio.get(
        _baseUrl,
        queryParameters: {'q': query, 'size': 20},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['results'] ?? [];
        return results
            .map((e) {
              final item = e as Map<String, dynamic>;
              final String verseKey = item['verse_key']?.toString() ?? '';
              final List<dynamic> translations =
                  item['translations'] as List<dynamic>? ?? [];
              String? translationSnippet;

              if (translations.isNotEmpty) {
                final firstTranslation =
                    translations.first as Map<String, dynamic>;
                translationSnippet = firstTranslation['text']?.toString();
                // The API provides HTML tags like <em> for highlights.
                // We can keep them for now and clean them up in the UI or here.
              }

              return RemoteSearchResult(
                verseKey: verseKey,
                translation: translationSnippet,
              );
            })
            .where((element) => element.verseKey.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
