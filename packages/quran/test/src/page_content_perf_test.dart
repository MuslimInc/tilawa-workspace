import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart';
import 'package:quran/src/page_content.dart';

/// Loads QPC v4 JSON files from disk and returns the processed data
/// in the same format as [_PageContentState._decodeAndProcess].
Map<String, dynamic> _loadQpcFromDisk() {
  final String qpcRaw = File(
    'assets/quran_fonts/qpc-v4.json',
  ).readAsStringSync();
  final String pageIndexRaw = File(
    'assets/quran_fonts/quran_page_index.json',
  ).readAsStringSync();

  final qpc = json.decode(qpcRaw) as Map<String, dynamic>;
  final pageIndexJson = json.decode(pageIndexRaw) as Map<String, dynamic>;

  final processedIndex = <int, List<List<Map<String, dynamic>>>>{};
  for (final MapEntry<String, dynamic> pageEntry in pageIndexJson.entries) {
    final int pageNum = int.parse(pageEntry.key);
    final lineMap = pageEntry.value as Map<String, dynamic>;
    final List<List<Map<String, dynamic>>> lines = List.generate(
      15,
      (_) => <Map<String, dynamic>>[],
    );
    for (final MapEntry<String, dynamic> lineEntry in lineMap.entries) {
      final int lineIndex = (int.parse(lineEntry.key) - 1).clamp(0, 14);
      final List<String> wordKeys = (lineEntry.value as List<dynamic>)
          .cast<String>();
      for (final key in wordKeys) {
        final wordData = qpc[key] as Map<String, dynamic>?;
        if (wordData != null) {
          lines[lineIndex].add(wordData);
        }
      }
    }
    processedIndex[pageNum] = lines;
  }

  return {'qpc': qpc, 'index': processedIndex};
}

/// Performance tests for the Quran page rendering pipeline.
///
/// Run with: flutter test test/src/page_content_perf_test.dart --reporter expanded
void main() {
  /// Pre-load data for widget tests so they don't need rootBundle + compute().
  late Map<String, dynamic> qpcData;
  late Map<int, List<List<Map<String, dynamic>>>> processedIndex;

  setUpAll(() {
    final Map<String, dynamic> data = _loadQpcFromDisk();
    qpcData = data['qpc'] as Map<String, dynamic>;
    processedIndex =
        data['index'] as Map<int, List<List<Map<String, dynamic>>>>;
  });

  /// Seeds the PageContent static cache before widget tests.
  void seedCache() {
    preloadPageContentCache(qpcData, processedIndex);
  }

  tearDown(() {
    clearPageContentCache();
  });

  // ---------------------------------------------------------------------------
  // 1. Page data service lookups (called on every page build)
  // ---------------------------------------------------------------------------
  group('Page data service lookups', () {
    test('getPageData is fast for all 604 pages', () {
      final sw = Stopwatch()..start();
      for (var page = 1; page <= 604; page++) {
        getPageData(page);
      }
      sw.stop();
      debugPrint(
        '  getPageData × 604 pages: ${sw.elapsedMicroseconds}µs '
        '(${(sw.elapsedMicroseconds / 604).toStringAsFixed(1)}µs/page)',
      );
      expect(sw.elapsedMilliseconds, lessThan(50));
    });

    test('getJuzNumber is fast across representative pages', () {
      final sw = Stopwatch()..start();
      for (var page = 1; page <= 604; page++) {
        final List<Map<String, int>> data = getPageData(page);
        final int surah = data.first['surah']!;
        final int start = data.first['start']!;
        getJuzNumber(surah, start);
      }
      sw.stop();
      debugPrint(
        '  getJuzNumber × 604 pages: ${sw.elapsedMicroseconds}µs '
        '(${(sw.elapsedMicroseconds / 604).toStringAsFixed(1)}µs/page)',
      );
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('getPageNumber lookup (first call builds cache, subsequent O(1))', () {
      // First call builds the lookup cache
      final swCold = Stopwatch()..start();
      getPageNumber(1, 1);
      swCold.stop();
      debugPrint(
        '  getPageNumber cold (cache build): ${swCold.elapsedMicroseconds}µs',
      );

      // Subsequent calls should be O(1)
      final swHot = Stopwatch()..start();
      for (var page = 1; page <= 604; page++) {
        final List<Map<String, int>> data = getPageData(page);
        final int surah = data.first['surah']!;
        final int start = data.first['start']!;
        getPageNumber(surah, start);
      }
      swHot.stop();
      debugPrint(
        '  getPageNumber × 604 (cached): ${swHot.elapsedMicroseconds}µs '
        '(${(swHot.elapsedMicroseconds / 604).toStringAsFixed(1)}µs/page)',
      );
      expect(swHot.elapsedMilliseconds, lessThan(20));
    });
  });

  // ---------------------------------------------------------------------------
  // 2. VerseServiceImpl.getVerseQCF string operations
  // ---------------------------------------------------------------------------
  group('VerseServiceImpl performance', () {
    test('getVerseQCF with addSpace=true is fast for long verses', () {
      const service = VerseServiceImpl();
      // Al-Baqarah 2:282 is the longest verse in the Quran
      final sw = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        service.getVerseQCF(2, 282);
      }
      sw.stop();
      debugPrint(
        '  getVerseQCF(2,282) × 100: ${sw.elapsedMicroseconds}µs '
        '(${(sw.elapsedMicroseconds / 100).toStringAsFixed(1)}µs/call)',
      );
      expect(sw.elapsedMilliseconds, lessThan(50));
    });

    test('getVerseQCF without space is cheaper than with space', () {
      const service = VerseServiceImpl();
      final swWithSpace = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        service.getVerseQCF(1, 1);
      }
      swWithSpace.stop();

      final swNoSpace = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        service.getVerseQCF(1, 1, addSpace: false);
      }
      swNoSpace.stop();

      debugPrint(
        '  getVerseQCF(1,1) × 1000 with space: ${swWithSpace.elapsedMicroseconds}µs',
      );
      debugPrint(
        '  getVerseQCF(1,1) × 1000 no space:   ${swNoSpace.elapsedMicroseconds}µs',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 3. JSON decode + page index processing (cold start cost)
  // ---------------------------------------------------------------------------
  group('QPC v4 data loading', () {
    test('JSON decode and page index build time', () async {
      final String qpcJson = await rootBundle.loadString(
        'packages/quran/assets/quran_fonts/qpc-v4.json',
      );
      final String pageIndexJson = await rootBundle.loadString(
        'packages/quran/assets/quran_fonts/quran_page_index.json',
      );

      final sw = Stopwatch()..start();
      final qpc = json.decode(qpcJson) as Map<String, dynamic>;
      final int swDecode1 = sw.elapsedMicroseconds;

      final pageIndexRaw = json.decode(pageIndexJson) as Map<String, dynamic>;
      final int swDecode2 = sw.elapsedMicroseconds;

      // Process page index (mirrors PageContent._decodeAndProcess)
      final processedIndex = <int, List<List<Map<String, dynamic>>>>{};
      for (final MapEntry<String, dynamic> pageEntry in pageIndexRaw.entries) {
        final int pageNum = int.parse(pageEntry.key);
        final lineMap = pageEntry.value as Map<String, dynamic>;
        final List<List<Map<String, dynamic>>> lines = List.generate(
          15,
          (_) => <Map<String, dynamic>>[],
        );
        for (final MapEntry<String, dynamic> lineEntry in lineMap.entries) {
          final int lineIndex = (int.parse(lineEntry.key) - 1).clamp(0, 14);
          final List<String> wordKeys = (lineEntry.value as List<dynamic>)
              .cast<String>();
          for (final key in wordKeys) {
            final wordData = qpc[key] as Map<String, dynamic>?;
            if (wordData != null) {
              lines[lineIndex].add(wordData);
            }
          }
        }
        processedIndex[pageNum] = lines;
      }
      sw.stop();

      debugPrint('  qpc-v4.json decode: $swDecode1µs');
      debugPrint('  quran_page_index.json decode: ${swDecode2 - swDecode1}µs');
      debugPrint(
        '  Page index processing: ${sw.elapsedMicroseconds - swDecode2}µs',
      );
      debugPrint(
        '  TOTAL (runs on main thread via compute): '
        '${sw.elapsedMicroseconds}µs '
        '(${sw.elapsedMilliseconds}ms)',
      );
      debugPrint('  Processed pages: ${processedIndex.length}');

      expect(processedIndex.length, 604);
    });

    test('word count per page varies but stays reasonable', () async {
      final String qpcJson = await rootBundle.loadString(
        'packages/quran/assets/quran_fonts/qpc-v4.json',
      );
      final String pageIndexJson = await rootBundle.loadString(
        'packages/quran/assets/quran_fonts/quran_page_index.json',
      );
      json.decode(qpcJson); // warm up
      final pageIndexRaw = json.decode(pageIndexJson) as Map<String, dynamic>;

      var maxWords = 0;
      var maxWordsPage = 0;
      var totalWords = 0;

      for (final MapEntry<String, dynamic> pageEntry in pageIndexRaw.entries) {
        final int pageNum = int.parse(pageEntry.key);
        final lineMap = pageEntry.value as Map<String, dynamic>;
        var pageWordCount = 0;
        for (final MapEntry<String, dynamic> lineEntry in lineMap.entries) {
          final List<String> wordKeys = (lineEntry.value as List<dynamic>)
              .cast<String>();
          pageWordCount += wordKeys.length;
        }
        totalWords += pageWordCount;
        if (pageWordCount > maxWords) {
          maxWords = pageWordCount;
          maxWordsPage = pageNum;
        }
      }

      debugPrint(
        '  Max words on a single page: $maxWords (page $maxWordsPage)',
      );
      debugPrint(
        '  Average words per page: ${(totalWords / 604).toStringAsFixed(1)}',
      );
      debugPrint(
        '  → Each word = 1 TextSpan + 1 TextStyle allocation per build',
      );

      // Each word becomes a TextSpan — too many = expensive layout
      expect(
        maxWords,
        lessThan(300),
        reason: 'No page should have > 300 words (TextSpan objects)',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 4. PageContent widget build performance
  // ---------------------------------------------------------------------------
  group('PageContent widget build', () {
    testWidgets('cold build completes and renders content', (
      WidgetTester tester,
    ) async {
      seedCache();
      final sw = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageContent(
              pageNumber: 3,
              textColor: Colors.black,
              onLongPressCancel: (_, _) {},
              onLongPressDown: (_, _, _) {},
            ),
          ),
        ),
      );
      // Data is pre-seeded, so one pump resolves the sync check in initState
      await tester.pump();
      sw.stop();

      debugPrint('  PageContent(3) build: ${sw.elapsedMilliseconds}ms');

      // Verify it rendered actual content
      expect(find.byType(RichText), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('warm build is fast (data already in static cache)', (
      WidgetTester tester,
    ) async {
      seedCache();
      // First page load
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageContent(
              pageNumber: 3,
              textColor: Colors.black,
              onLongPressCancel: (_, _) {},
              onLongPressDown: (_, _, _) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Now measure building a different page (data already in static cache)
      final sw = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageContent(
              pageNumber: 50,
              textColor: Colors.black,
              onLongPressCancel: (_, _) {},
              onLongPressDown: (_, _, _) {},
            ),
          ),
        ),
      );
      await tester.pump();
      sw.stop();

      debugPrint('  PageContent(50) warm build: ${sw.elapsedMilliseconds}ms');
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('page with surah header renders Image widget', (
      WidgetTester tester,
    ) async {
      seedCache();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageContent(
              pageNumber: 1,
              textColor: Colors.black,
              onLongPressCancel: (_, _) {},
              onLongPressDown: (_, _, _) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('rapid page switching does not crash', (
      WidgetTester tester,
    ) async {
      seedCache();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageContent(
              pageNumber: 1,
              textColor: Colors.black,
              onLongPressCancel: (_, _) {},
              onLongPressDown: (_, _, _) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Simulate rapid page changes (like fast swiping)
      final sw = Stopwatch()..start();
      for (var page = 2; page <= 10; page++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PageContent(
                pageNumber: page,
                textColor: Colors.black,
                onLongPressCancel: (_, _) {},
                onLongPressDown: (_, _, _) {},
              ),
            ),
          ),
        );
        await tester.pump();
      }
      sw.stop();

      debugPrint(
        '  9 rapid page switches: ${sw.elapsedMilliseconds}ms '
        '(${(sw.elapsedMilliseconds / 9).toStringAsFixed(1)}ms/page)',
      );
      expect(find.byType(RichText), findsWidgets);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. Widget tree complexity per page
  // ---------------------------------------------------------------------------
  group('Widget tree complexity', () {
    testWidgets('measures widget counts per page', (WidgetTester tester) async {
      seedCache();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageContent(
              pageNumber: 50,
              textColor: Colors.black,
              onLongPressCancel: (_, _) {},
              onLongPressDown: (_, _, _) {},
            ),
          ),
        ),
      );
      await tester.pump();

      final int richTextCount = tester.widgetList(find.byType(RichText)).length;
      final int fittedBoxCount = tester
          .widgetList(find.byType(FittedBox))
          .length;
      final int repaintBoundaryCount = tester
          .widgetList(find.byType(RepaintBoundary))
          .length;

      debugPrint('  Page 50 widget counts:');
      debugPrint('    RichText:        $richTextCount');
      debugPrint('    FittedBox:       $fittedBoxCount');
      debugPrint('    RepaintBoundary: $repaintBoundaryCount');

      expect(
        richTextCount,
        lessThan(25),
        reason: 'Too many RichText widgets cause layout jank',
      );
      expect(
        fittedBoxCount,
        lessThanOrEqualTo(15),
        reason: 'Should have at most 15 FittedBox widgets (one per line)',
      );
    });

    testWidgets('measures TextSpan count per page', (
      WidgetTester tester,
    ) async {
      seedCache();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageContent(
              pageNumber: 50,
              textColor: Colors.black,
              onLongPressCancel: (_, _) {},
              onLongPressDown: (_, _, _) {},
            ),
          ),
        ),
      );
      await tester.pump();

      var totalSpans = 0;
      final Iterable<RichText> richTexts = tester.widgetList<RichText>(
        find.byType(RichText),
      );
      for (final rt in richTexts) {
        void countSpans(InlineSpan span) {
          totalSpans++;
          if (span is TextSpan && span.children != null) {
            for (final InlineSpan child in span.children!) {
              countSpans(child);
            }
          }
        }

        countSpans(rt.text);
      }

      debugPrint('  Page 50 total InlineSpan objects: $totalSpans');
      debugPrint(
        '  → Each span requires TextStyle + paint allocation during layout',
      );

      expect(
        totalSpans,
        lessThan(300),
        reason: 'Too many TextSpan objects cause expensive text layout',
      );
    });

    testWidgets(
      'each line creates a new TextStyle per word (allocation check)',
      (WidgetTester tester) async {
        seedCache();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PageContent(
                pageNumber: 100,
                textColor: Colors.black,
                onLongPressCancel: (_, _) {},
                onLongPressDown: (_, _, _) {},
              ),
            ),
          ),
        );
        await tester.pump();

        // Count unique TextStyle instances across all spans
        final styles = <TextStyle>{};
        final Iterable<RichText> richTexts = tester.widgetList<RichText>(
          find.byType(RichText),
        );
        for (final rt in richTexts) {
          void collectStyles(InlineSpan span) {
            if (span is TextSpan) {
              if (span.style != null) styles.add(span.style!);
              if (span.children != null) {
                for (final InlineSpan child in span.children!) {
                  collectStyles(child);
                }
              }
            }
          }

          collectStyles(rt.text);
        }

        debugPrint('  Page 100 unique TextStyle instances: ${styles.length}');
        debugPrint(
          '  → If close to total span count, styles are not being reused',
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // 6. QuranPageView (full PageView) build test
  // ---------------------------------------------------------------------------
  group('QuranPageView integration', () {
    testWidgets('builds and renders first page', (WidgetTester tester) async {
      seedCache();
      final sw = Stopwatch()..start();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: QuranPageView())),
      );
      await tester.pump();
      sw.stop();

      debugPrint('  QuranPageView initial build: ${sw.elapsedMilliseconds}ms');
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('page swipe does not rebuild QuranPageView', (
      WidgetTester tester,
    ) async {
      seedCache();
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                buildCount++;
                return const QuranPageView();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      final initialBuildCount = buildCount;

      // Simulate swipe (RTL direction, so positive offset = next page)
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      debugPrint(
        '  Build count: initial=$initialBuildCount, after swipe=$buildCount',
      );
      expect(
        buildCount,
        initialBuildCount,
        reason: 'QuranPageView should not rebuild on page swipe',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 7. LayoutBuilder rebuild behavior
  // ---------------------------------------------------------------------------
  group('LayoutBuilder rebuild behavior', () {
    testWidgets('does not rebuild when constraints unchanged', (
      WidgetTester tester,
    ) async {
      var layoutBuilderCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                layoutBuilderCallCount++;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final initialCount = layoutBuilderCallCount;
      await tester.pump();

      debugPrint(
        '  LayoutBuilder calls: initial=$initialCount, '
        'after pump=$layoutBuilderCallCount',
      );
      expect(layoutBuilderCallCount, initialCount);
    });
  });
}
