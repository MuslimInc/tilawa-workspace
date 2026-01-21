import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('should have correct base URL', () {
      expect(ApiConfig.baseUrl, 'https://www.mp3quran.net/api/v3');
    });

    test('should have correct reciters path', () {
      expect(ApiConfig.recitersPath, '/reciters');
    });

    test('reciters without language should return base URL with path', () {
      // act
      final String result = ApiConfig.reciters();

      // assert
      expect(result, 'https://www.mp3quran.net/api/v3/reciters');
    });

    test('reciters with empty language should return base URL with path', () {
      // act
      final String result = ApiConfig.reciters(language: '');

      // assert
      expect(result, 'https://www.mp3quran.net/api/v3/reciters');
    });

    test('reciters with language should include language parameter', () {
      // act
      final String result = ApiConfig.reciters(language: 'ar');

      // assert
      expect(result, 'https://www.mp3quran.net/api/v3/reciters?language=ar');
    });

    test(
      'reciters with  different language should include correct parameter',
      () {
        // act
        final String result = ApiConfig.reciters(language: 'en');

        // assert
        expect(result, 'https://www.mp3quran.net/api/v3/reciters?language=en');
      },
    );

    test('private constructor should prevent instantiation', () {
      expect(ApiConfig, isNotNull);
    });
  });
}
