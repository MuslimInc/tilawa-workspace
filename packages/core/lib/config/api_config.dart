class ApiConfig {
  ApiConfig._();

  // Centralized base URL for MP3Quran API
  static const String baseUrl = 'https://www.mp3quran.net/api/v3';

  // Endpoints
  static const String recitersPath = '/reciters';

  // Helpers
  static String reciters({String? language}) {
    if (language == null || language.isEmpty) {
      return '$baseUrl$recitersPath';
    }
    return '$baseUrl$recitersPath?language=$language';
  }
}
