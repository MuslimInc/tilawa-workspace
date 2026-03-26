import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Represents the start and end time of an ayah in an audio file.
class AyahTiming {
  AyahTiming({
    required this.surahNumber,
    required this.ayahNumber,
    required this.startTimeMs,
    required this.endTimeMs,
  });

  final int surahNumber;
  final int ayahNumber;
  final int startTimeMs;
  final int endTimeMs;

  double get startSeconds => startTimeMs / 1000.0;
  double get endSeconds => endTimeMs / 1000.0;
}

/// Fetches and caches ayah-level timing data from Quran.com.
@lazySingleton
class AyahTimingService {
  AyahTimingService(this._dio);

  final Dio _dio;
  static const _apiBase = 'https://api.quran.com/api/v4';

  /// Fetches timings for all ayahs in a surah for a specific recitation.
  ///
  /// [recitationId] is the Quran.com recitation ID.
  Future<List<AyahTiming>> getSurahTimings({
    required int recitationId,
    required int surahNumber,
  }) async {
    final cacheDir = await getTemporaryDirectory();
    final cacheFile = File(
      p.join(cacheDir.path, 'timings_${recitationId}_$surahNumber.json'),
    );

    if (cacheFile.existsSync()) {
      final jsonStr = await cacheFile.readAsString();
      return _parseTimings(json.decode(jsonStr), surahNumber);
    }

    final response = await _dio.get(
      '$_apiBase/recitations/$recitationId/by_surah/$surahNumber',
      queryParameters: {'per_page': 1000},
    );

    final data = response.data;
    await cacheFile.writeAsString(json.encode(data));

    return _parseTimings(data, surahNumber);
  }

  List<AyahTiming> _parseTimings(dynamic data, int surahNumber) {
    if (data is! Map<String, dynamic>) return [];
    
    final audioFiles = data['audio_files'] as List<dynamic>?;
    if (audioFiles == null) return [];

    return audioFiles.map((fileMap) {
      final file = fileMap as Map<String, dynamic>;
      final verseKey = file['verse_key'] as String;
      final ayahNumber = int.parse(verseKey.split(':')[1]);
      
      // Quran.com API returns segments: [[word_index, start_ms, end_ms, ...]]
      final segments = file['segments'] as List<dynamic>?;
      
      int start = 0;
      int end = 0;
      
      if (segments != null && segments.isNotEmpty) {
        start = segments.first[1] as int;
        end = segments.last[2] as int;
      }

      return AyahTiming(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        startTimeMs: start,
        endTimeMs: end,
      );
    }).toList();
  }
}
