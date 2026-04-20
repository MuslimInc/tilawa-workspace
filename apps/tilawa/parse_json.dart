import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.dateAndTime,
  ),
);

void main() async {
  try {
    final file = File('../../packages/quran/assets/quran_fonts/qpc-v4.json');
    if (!await file.exists()) {
      logger.e('Source file not found: ${file.path}');
      return;
    }
    final jsonString = await file.readAsString();
    logger.d('Read file, length: ${jsonString.length}');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    logger.d('Decoded json, keys: ${data.keys.length}');

    // Map of surah:ayah -> list of words
    final Map<String, List<Map<String, dynamic>>> verses = {};

    for (final key in data.keys) {
      final entry = data[key];
      final surah = entry['surah'];
      final ayah = entry['ayah'];

      final verseKey = '$surah:$ayah';
      if (!verses.containsKey(verseKey)) {
        verses[verseKey] = [];
      }
      verses[verseKey]!.add(entry);
    }

    logger.d('Total verses: ${verses.length}');
    const firstKey = '1:1';
    final firstVerse = verses[firstKey]!;
    firstVerse.sort(
      (a, b) => int.parse(
        a['word'].toString(),
      ).compareTo(int.parse(b['word'].toString())),
    );
    logger.d('Surah 1 Ayah 1: ${firstVerse.map((e) => e['text']).join('')}');

    // Create new dart code
    final StringBuffer sb = StringBuffer();
    sb.writeln('/// Auto-generated from qpc-v4.json');
    sb.writeln('const Map<String, String> qcfV4Data = {');

    for (int s = 1; s <= 114; s++) {
      for (int a = 1; a <= 286; a++) {
        final k = '$s:$a';
        if (verses.containsKey(k)) {
          final lst = verses[k]!;
          lst.sort(
            (a, b) => int.parse(
              a['word'].toString(),
            ).compareTo(int.parse(b['word'].toString())),
          );
          final text = lst.map((e) => e['text']).join('');
          sb.writeln("  '$k': '$text',");
        }
      }
    }
    sb.writeln('};');

    final outputFile = File(
      '../../packages/quran/lib/src/data/qcf_v4_data.dart',
    );
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(sb.toString());
    logger.d('Wrote ${outputFile.path}');
  } catch (e, st) {
    logger.e('Error generating data', error: e, stackTrace: st);
  }
}
