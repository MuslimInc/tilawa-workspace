import 'dart:convert';
import 'dart:io';

void main() async {
  // 1. Get Surah Start Pages from quran.json
  final quranFile = File('assets/data/quran.json');
  final quranJson = jsonDecode(await quranFile.readAsString());
  final surahs = quranJson['data']['surahs'] as List;

  final surahStartPages = <int>{};
  for (final s in surahs) {
    // Determine start page of surah
    final ayahs = s['ayahs'] as List;
    if (ayahs.isNotEmpty) {
      surahStartPages.add(ayahs.first['page']);
    }
  }

  print('Found ${surahStartPages.length} Surah start pages.');

  final headerMap = <int, int>{}; // Page -> LineIndex (0-14)

  // 2. Scan assets
  final dir = Directory('assets/quranlines');
  final List<FileSystemEntity> files = await dir.list().toList();

  for (final page in surahStartPages) {
    if (page > 604) continue;

    // Get files for this page
    final List<FileSystemEntity> pageFiles = files.where((f) {
      final String name = f.uri.pathSegments.last;
      return name.startsWith('p${page}_') && name.endsWith('.png');
    }).toList();

    // Sort by line number
    pageFiles.sort((a, b) {
      final String nameA = a.uri.pathSegments.last;
      final String nameB = b.uri.pathSegments.last;
      final int lineA = int.parse(nameA.split('_')[1].split('.')[0]);
      final int lineB = int.parse(nameB.split('_')[1].split('.')[0]);
      return lineA.compareTo(lineB);
    });

    // Find Header Line
    // Hypothesis: Header is the FIRST line that is "Small but not Empty"
    // Empty/Spacer ~ 130B
    // Header ~ 3KB - 5.5KB
    // Text > 6KB

    int? bestLine;

    for (final f in pageFiles) {
      final int size = (f as File).lengthSync();
      if (size > 200 && size < 6000) {
        // Found a candidate (Header or Basmalah)
        // Since Header comes BEFORE Basmalah (and we sorted logic), the FIRST one is Header.
        final String name = f.uri.pathSegments.last;
        final int line = int.parse(name.split('_')[1].split('.')[0]);

        bestLine = line;
        break; // Found the first one
      }
    }

    if (bestLine != null) {
      headerMap[page] = bestLine - 1; // Convert to 0-indexed for Widget
    } else {
      print('Warning: No header found for Page $page');
    }
  }

  // 3. Output Dart Code
  final buffer = StringBuffer();
  buffer.writeln(
    '// Generated map of Page Number -> Line Index (0-14) for Surah Headers',
  );
  buffer.writeln('const Map<int, int> surahHeaderLineMap = {');

  final List<int> sortedKeys = headerMap.keys.toList()..sort();
  for (final k in sortedKeys) {
    buffer.writeln('  $k: ${headerMap[k]},');
  }

  buffer.writeln('};');

  await File(
    '/Users/mohammadkamel/tilawa/lib/features/quran_reader/presentation/widgets/surah_header_map.dart',
  ).writeAsString(buffer.toString());
  print(
    'Map generated at lib/features/quran_reader/presentation/widgets/surah_header_map.dart',
  );
}
