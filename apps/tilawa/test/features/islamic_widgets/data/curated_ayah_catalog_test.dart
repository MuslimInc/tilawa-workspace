import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Curated Ayah Catalog', () {
    test('JSON fixture exists and is valid', () {
      final file = File('assets/data/widget_daily_ayahs.json');
      expect(file.existsSync(), isTrue);

      final String jsonStr = file.readAsStringSync();
      final List<dynamic> data = jsonDecode(jsonStr) as List<dynamic>;

      expect(data.isNotEmpty, isTrue);

      for (final dynamic item in data) {
        final map = item as Map<String, dynamic>;
        expect(map['id'], isA<int>());
        expect(map['surahNumber'], isA<int>());
        expect(map['ayahNumber'], isA<int>());
        expect(map['text'], isA<String>());
        expect(map['text'].toString().isNotEmpty, isTrue);
      }
    });
  });
}
