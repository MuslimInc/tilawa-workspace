class ApiConfig {
  ApiConfig._();

  // Centralized base URL for MP3Quran API
  static const String baseUrl = 'https://www.mp3quran.net/api/v3';

  // Endpoints
  static const String recitersPath = '/reciters';
  static const String videosPath = '/videos';
  static const String videoTypesPath = '/video_types';
  static const String radiosPath = '/radios';

  // Helpers
  static String reciters({String? language}) {
    if (language == null || language.isEmpty) {
      return '$baseUrl$recitersPath';
    }
    return '$baseUrl$recitersPath?language=$language';
  }

  static String videos({String? language}) {
    if (language == null || language.isEmpty) {
      return '$baseUrl$videosPath';
    }
    return '$baseUrl$videosPath?language=$language';
  }

  static String videoTypes({String? language}) {
    if (language == null || language.isEmpty) {
      return '$baseUrl$videoTypesPath';
    }
    return '$baseUrl$videoTypesPath?language=$language';
  }

  static String radios({String? language}) {
    if (language == null || language.isEmpty) {
      return '$baseUrl$radiosPath';
    }
    return '$baseUrl$radiosPath?language=$language';
  }
}
