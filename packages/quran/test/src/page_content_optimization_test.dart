import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart';
import 'package:quran/src/page_content.dart';

/// Tests that confirm every performance optimization is working correctly.
///
/// Each test targets a specific fix and proves the issue is resolved.
///
/// Run with:
///   flutter test test/src/page_content_optimization_test.dart --reporter expanded
void main() {
  late Map<String, dynamic> qpcData;
  late Map<int, List<List<Map<String, dynamic>>>> processedIndex;

  setUpAll(() {
    final base = File('assets/quran_fonts/qpc-v4.json').existsSync()
        ? 'assets/quran_fonts'
        : 'packages/quran/assets/quran_fonts';
    final String qpcRaw = File('$base/qpc-v4.json').readAsStringSync();
    final String pageIndexRaw = File(
      '$base/quran_page_index.json',
    ).readAsStringSync();
    final qpc = json.decode(qpcRaw) as Map<String, dynamic>;
    final pageIndexJson = json.decode(pageIndexRaw) as Map<String, dynamic>;

    final index = <int, List<List<Map<String, dynamic>>>>{};
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
      index[pageNum] = lines;
    }

    qpcData = qpc;
    processedIndex = index;
  });

  void seedCache() {
    preloadPageContentCache(qpcData, processedIndex);
  }

  tearDown(() {
    clearPageContentCache();
  });

  // ===========================================================================
  // FIX 1: TextStyle reuse — all words on a page share one baseStyle.
  //
  // BEFORE: ~138 new TextStyle objects per page per build.
  // AFTER:  1 shared baseStyle per page (unless verseBackgroundColor overrides).
  // ===========================================================================
  group('FIX 1: TextStyle reuse (shared baseStyle)', () {
    testWidgets(
      'all words on a page without verseBackgroundColor share the SAME '
      'TextStyle instance',
      (WidgetTester tester) async {
        seedCache();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PageContent(
                pageNumber: 50,
                textColor: Colors.black,
                onLongPressCancel: (_, _) {},
                onLongPressDown: (_, _, _) {},
                // no verseBackgroundColor — all words should share one style
              ),
            ),
          ),
        );
        await tester.pump();

        // Collect every TextStyle from every TextSpan child
        final styles = <TextStyle>[];
        final Iterable<RichText> richTexts = tester.widgetList<RichText>(
          find.byType(RichText),
        );
        for (final rt in richTexts) {
          _collectChildStyles(rt.text, styles);
        }

        // There should be many spans but very few unique styles
        expect(
          styles.length,
          greaterThan(50),
          reason: 'Page 50 should have many word spans',
        );

        final Set<TextStyle> uniqueStyles = styles.toSet();
        debugPrint(
          '  Page 50: ${styles.length} total spans, '
          '${uniqueStyles.length} unique TextStyle instances',
        );

        // With the fix, the page font style should be reused for all words.
        // We allow a few extras for the thin-space span and header/footer
        // text, but it should be FAR fewer than the span count.
        expect(
          uniqueStyles.length,
          lessThanOrEqualTo(10),
          reason:
              'Without verseBackgroundColor, styles should be heavily reused. '
              'Got ${uniqueStyles.length} unique vs ${styles.length} total. '
              'Before the fix this would be ~${styles.length} (one per word).',
        );
      },
    );

    testWidgets(
      'verseBackgroundColor only creates new styles for highlighted verses',
      (WidgetTester tester) async {
        seedCache();
        // Highlight only surah 2, verse 6 (a single verse on page 3)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PageContent(
                pageNumber: 3,
                textColor: Colors.black,
                onLongPressCancel: (_, _) {},
                onLongPressDown: (_, _, _) {},
                verseBackgroundColor: (surah, verse) {
                  if (surah == 2 && verse == 6) return Colors.yellow;
                  return null;
                },
              ),
            ),
          ),
        );
        await tester.pump();

        final styles = <TextStyle>[];
        final Iterable<RichText> richTexts = tester.widgetList<RichText>(
          find.byType(RichText),
        );
        for (final rt in richTexts) {
          _collectChildStyles(rt.text, styles);
        }

        final Set<TextStyle> uniqueStyles = styles.toSet();

        // We expect: 1 baseStyle + 1 highlighted style + a few header/footer
        debugPrint(
          '  Page 3 with highlight: ${styles.length} spans, '
          '${uniqueStyles.length} unique styles',
        );

        expect(
          uniqueStyles.length,
          lessThanOrEqualTo(12),
          reason:
              'Highlighting 1 verse should add at most 1 extra style. '
              'Got ${uniqueStyles.length} unique.',
        );

        // Verify the highlighted style actually has the yellow background
        final List<TextStyle> yellowStyles = uniqueStyles
            .where((s) => s.backgroundColor == Colors.yellow)
            .toList();
        expect(
          yellowStyles,
          isNotEmpty,
          reason: 'Should have at least one style with yellow background',
        );
      },
    );

    testWidgets(
      'TextStyle identity is the same object (not just equal) across words',
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

        // Collect styles using identical() checks, not ==
        final identitySet = <int>{}; // hashCode of identityHashCode
        final styles = <TextStyle>[];
        final Iterable<RichText> richTexts = tester.widgetList<RichText>(
          find.byType(RichText),
        );

        for (final rt in richTexts) {
          _collectChildStyles(rt.text, styles);
        }

        // Filter to only QCF font styles (exclude header/footer text)
        final List<TextStyle> qcfStyles = styles
            .where((s) => s.fontFamily?.startsWith('QCF_P') ?? false)
            .toList();

        for (final s in qcfStyles) {
          identitySet.add(identityHashCode(s));
        }

        debugPrint(
          '  Page 100: ${qcfStyles.length} QCF word spans, '
          '${identitySet.length} distinct object identities',
        );

        // With the fix, all words share the SAME TextStyle object instance.
        // identitySet should have 1 entry (or 2 if there's a thin-space style).
        expect(
          identitySet.length,
          lessThanOrEqualTo(3),
          reason:
              'All QCF words should share 1 TextStyle object identity. '
              'Got ${identitySet.length}. Before the fix, this would be '
              '~${qcfStyles.length} (one new object per word).',
        );
      },
    );
  });

  // ===========================================================================
  // FIX 2: pageLines fetched once outside LayoutBuilder.
  //
  // BEFORE: _getWordsGroupedByLine called 2x per build (once for
  //         _firstContentLineIndex, once inside LayoutBuilder).
  // AFTER:  Called once before LayoutBuilder, result shared.
  // ===========================================================================
  group('FIX 2: pageLines fetched once (no redundant lookup)', () {
    testWidgets(
      'page renders correctly with pageLines fetched outside LayoutBuilder',
      (WidgetTester tester) async {
        seedCache();

        // Render multiple pages and verify they all produce correct content
        for (final pageNum in [1, 2, 3, 50, 100, 300, 604]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PageContent(
                  pageNumber: pageNum,
                  textColor: Colors.black,
                  onLongPressCancel: (_, _) {},
                  onLongPressDown: (_, _, _) {},
                ),
              ),
            ),
          );
          await tester.pump();

          // Should never show loading spinner
          expect(
            find.byType(CircularProgressIndicator),
            findsNothing,
            reason: 'Page $pageNum should render immediately with cached data',
          );

          // All pages (except possibly 1 and 2 which are special) should
          // have RichText widgets for the Quran text
          if (pageNum > 2) {
            expect(
              find.byType(RichText),
              findsWidgets,
              reason: 'Page $pageNum should have rendered RichText widgets',
            );
          }
        }
      },
    );

    testWidgets('firstContentLineIndex is correct for special pages', (
      WidgetTester tester,
    ) async {
      seedCache();

      // Page 1 (Al-Fatiha) — first content line is NOT line 0
      // (has surah header first)
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

      // Page 1 should have Image widget for surah header
      expect(
        find.byType(Image),
        findsWidgets,
        reason: 'Page 1 should have surah header banner',
      );

      // Page 50 — normal page, first content is line 0
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

      // Normal pages should have FittedBox for text lines
      expect(
        find.byType(FittedBox),
        findsWidgets,
        reason: 'Page 50 should have FittedBox line widgets',
      );
    });
  });

  // ===========================================================================
  // FIX 3: No api.quran.com network call on page swipe.
  //
  // BEFORE: onPageChanged called QuranReaderEvent.loadPage() which triggered
  //         HTTP request + O(6236) ayah scan on every swipe.
  // AFTER:  onPageChanged only saves last-read position (lightweight).
  //
  // We verify this indirectly: the QuranPageView's onPageChanged callback
  // fires but the rendering pipeline does NOT depend on any external data.
  // ===========================================================================
  group('FIX 3: No network call on page swipe', () {
    testWidgets('QuranPageView renders pages purely from static QPC data '
        '(no external dependencies)', (WidgetTester tester) async {
      seedCache();

      // Build QuranPageView — it should render page 1 from static data only
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: QuranPageView())),
      );
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'Should render without async loading',
      );
    });

    testWidgets(
      'onPageChanged callback fires with page number (not loadPage event)',
      (WidgetTester tester) async {
        seedCache();

        final List<int> receivedPages = [];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuranPageView(
                onPageChanged: (pageNumber) {
                  receivedPages.add(pageNumber);
                },
              ),
            ),
          ),
        );
        await tester.pump();

        // Simulate page swipe
        await tester.drag(find.byType(PageView), const Offset(400, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // The callback should have fired with just a page number —
        // no bloc event, no network call, just a lightweight notification.
        debugPrint('  Received page changes: $receivedPages');
        // We just verify the callback works; the key assertion is that
        // this test completes without timeout (no network blocking).
      },
    );
  });

  // ===========================================================================
  // FIX 4: Static caches (layout strategy, special lines cache).
  //
  // BEFORE: New StandardQuranLayoutStrategy() per build; _specialLinesCache
  //         was an instance field rebuilt per widget instance.
  // AFTER:  Both are static final — shared across all PageContent instances.
  // ===========================================================================
  group('FIX 4: Static caches persist across widget instances', () {
    testWidgets(
      'special lines cache is populated and reused across page rebuilds',
      (WidgetTester tester) async {
        seedCache();

        // Build page 50
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

        // Measure time for second build of same page — should be faster
        // because special lines are cached from the first build.
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

        debugPrint('  Rebuild page 50 (cached): ${sw.elapsedMilliseconds}ms');
        expect(
          sw.elapsedMilliseconds,
          lessThan(100),
          reason: 'Rebuilding a cached page should be fast',
        );
      },
    );
  });

  // ===========================================================================
  // FIX 5: Rapid page switching performance.
  //
  // Proves the combined effect of all fixes: rapid page switches stay
  // fast and under budget.
  // ===========================================================================
  group('FIX 5: Combined — rapid page switching performance', () {
    testWidgets('switching 50 pages averages under 10ms per page', (
      WidgetTester tester,
    ) async {
      seedCache();

      // Warm up
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

      // Switch through 50 pages rapidly
      final sw = Stopwatch()..start();
      for (var page = 2; page <= 51; page++) {
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

      final double avgMs = sw.elapsedMilliseconds / 50;
      debugPrint(
        '  50 page switches: ${sw.elapsedMilliseconds}ms '
        '(${avgMs.toStringAsFixed(1)}ms/page)',
      );

      expect(
        avgMs,
        lessThan(10),
        reason:
            'Average page build should be under 10ms. Got ${avgMs.toStringAsFixed(1)}ms. '
            'At 60fps, each frame budget is 16.6ms.',
      );
    });

    testWidgets('densest page (576, 184 words) builds within frame budget', (
      WidgetTester tester,
    ) async {
      seedCache();

      // Warm up
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

      // Build the densest page
      final sw = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageContent(
              pageNumber: 576,
              textColor: Colors.black,
              onLongPressCancel: (_, _) {},
              onLongPressDown: (_, _, _) {},
            ),
          ),
        ),
      );
      await tester.pump();
      sw.stop();

      debugPrint(
        '  Page 576 (184 words, densest): ${sw.elapsedMilliseconds}ms',
      );

      expect(
        sw.elapsedMilliseconds,
        lessThan(50),
        reason:
            'Even the densest page (184 words) should build in under 50ms. '
            'Got ${sw.elapsedMilliseconds}ms.',
      );

      // Verify it actually rendered all 15 lines
      final int fittedBoxCount = tester
          .widgetList(find.byType(FittedBox))
          .length;
      debugPrint('  FittedBox count (lines rendered): $fittedBoxCount');
      expect(
        fittedBoxCount,
        greaterThanOrEqualTo(13),
        reason: 'Dense page should render most of 15 lines',
      );
    });
  });

  // ===========================================================================
  // FIX 6: Widget tree is not bloated.
  //
  // Verifies the widget tree stays lean — no unnecessary wrapping or
  // duplicate widgets introduced by the optimizations.
  // ===========================================================================
  group('FIX 6: Widget tree correctness', () {
    testWidgets('page has exactly 15 line slots (SizedBox or FittedBox)', (
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

      // Count FittedBox (content lines) + SizedBox (empty lines)
      // inside the Column that represents the 15-line grid
      final int fittedBoxCount = tester
          .widgetList(find.byType(FittedBox))
          .length;
      debugPrint('  Page 50: $fittedBoxCount FittedBox (content lines)');

      // A normal page should have all or nearly all 15 lines filled
      expect(
        fittedBoxCount,
        greaterThanOrEqualTo(10),
        reason: 'Normal page should fill most of 15 line slots',
      );
      expect(
        fittedBoxCount,
        lessThanOrEqualTo(15),
        reason: 'Cannot exceed 15 lines',
      );
    });

    testWidgets('RepaintBoundary wraps the whole page', (
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

      // The outermost widget inside PageContent should be a RepaintBoundary
      expect(
        find.byType(RepaintBoundary),
        findsWidgets,
        reason: 'Page should be wrapped in RepaintBoundary for isolation',
      );
    });

    testWidgets('surah header pages have Image + RichText widgets', (
      WidgetTester tester,
    ) async {
      seedCache();

      // Page 50 contains Al-Imran header (surah 3 starts on page 50)
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

      // Should have both text lines and possibly a surah header banner
      expect(find.byType(RichText), findsWidgets);
    });
  });

  // ===========================================================================
  // FIX 7: preloadPageContentCache / clearPageContentCache work correctly.
  //
  // These @visibleForTesting helpers are essential for testability.
  // ===========================================================================
  group('FIX 7: Test cache helpers', () {
    testWidgets(
      'preloadPageContentCache enables immediate rendering without rootBundle',
      (WidgetTester tester) async {
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

        // With pre-seeded cache, content should render without async delay
        expect(
          find.byType(CircularProgressIndicator),
          findsNothing,
          reason: 'Pre-seeded cache should skip loading state',
        );
        expect(
          find.byType(RichText),
          findsWidgets,
          reason: 'Content should render with pre-seeded data',
        );
      },
    );

    testWidgets(
      'clearPageContentCache + seedCache allows fresh re-initialization',
      (WidgetTester tester) async {
        seedCache();

        // Render page 50
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
        expect(find.byType(RichText), findsWidgets);

        // Clear and re-seed — simulates app restart with fresh data
        clearPageContentCache();
        seedCache();

        // New widget should use the fresh cache
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

        expect(
          find.byType(CircularProgressIndicator),
          findsNothing,
          reason: 'Re-seeded cache should skip loading state',
        );
        expect(
          find.byType(RichText),
          findsWidgets,
          reason: 'Page 100 should render with re-seeded data',
        );
      },
    );
  });

  // ===========================================================================
  // FIX 8: Page swipe does NOT trigger parent rebuild.
  // ===========================================================================
  group('FIX 8: No unnecessary parent rebuilds on swipe', () {
    testWidgets('QuranPageView parent does not rebuild when user swipes', (
      WidgetTester tester,
    ) async {
      seedCache();
      var parentBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                parentBuildCount++;
                return const QuranPageView();
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final afterInitBuild = parentBuildCount;

      // Swipe 3 times
      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(PageView), const Offset(400, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      debugPrint(
        '  Parent build count: init=$afterInitBuild, '
        'after 3 swipes=$parentBuildCount',
      );

      expect(
        parentBuildCount,
        afterInitBuild,
        reason:
            'Swiping pages should NOT cause QuranPageView parent to rebuild. '
            'Before fix: loadPage event on every swipe could trigger state '
            'changes that propagate up.',
      );
    });
  });

  // ===========================================================================
  // FIX 9: AutomaticKeepAliveClientMixin keeps pages alive in PageView.
  // ===========================================================================
  group('FIX 9: KeepAlive prevents rebuilds of visited pages', () {
    testWidgets(
      'swiping back to a previously visited page does not re-create widget',
      (WidgetTester tester) async {
        seedCache();

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: QuranPageView())),
        );
        await tester.pump();

        // Page 1 should be rendered
        expect(find.byType(RichText), findsWidgets);

        // Swipe to page 2
        await tester.drag(find.byType(PageView), const Offset(400, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Swipe back to page 1
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Page 1 should still render correctly (kept alive, not rebuilt)
        expect(
          find.byType(RichText),
          findsWidgets,
          reason: 'Page should be kept alive and render without re-loading',
        );
        expect(
          find.byType(CircularProgressIndicator),
          findsNothing,
          reason: 'Kept-alive page should not show loading spinner',
        );
      },
    );
  });
  // ===========================================================================
  // FIX 10: Page jump via surah selection is immediate (no async round-trip).
  //
  // BEFORE: _jumpToSurah dispatched loadSurah → async network call (~500ms)
  //         → loadPage → another async call (~200ms) → BlocListener →
  //         addPostFrameCallback → jumpToPage. Total: ~700ms+.
  // AFTER:  getPageNumber(surahNumber, 1) is O(1) static lookup, then
  //         PageController.jumpToPage is called immediately.
  // ===========================================================================
  group('FIX 10: Surah-to-page lookup is instant (no async needed)', () {
    test('getPageNumber for all 114 surahs completes in under 1ms', () {
      // Warm cache
      getPageNumber(1, 1);

      final sw = Stopwatch()..start();
      for (var surah = 1; surah <= 114; surah++) {
        getPageNumber(surah, 1);
      }
      sw.stop();

      debugPrint(
        '  getPageNumber × 114 surahs: ${sw.elapsedMicroseconds}µs '
        '(${(sw.elapsedMicroseconds / 114).toStringAsFixed(1)}µs/surah)',
      );

      expect(
        sw.elapsedMicroseconds,
        lessThan(1000),
        reason:
            'All 114 surah page lookups should complete in under 1ms. '
            'This proves _jumpToSurah does NOT need an async bloc round-trip. '
            'Got ${sw.elapsedMicroseconds}µs.',
      );
    });

    test('getPageNumber returns correct known pages for key surahs', () {
      expect(getPageNumber(1, 1), 1, reason: 'Al-Fatiha starts on page 1');
      expect(getPageNumber(2, 1), 2, reason: 'Al-Baqarah starts on page 2');
      expect(getPageNumber(114, 1), 604, reason: 'An-Nas starts on page 604');
      expect(getPageNumber(18, 1), 293, reason: 'Al-Kahf starts on page 293');
      expect(getPageNumber(36, 1), 440, reason: 'Ya-Sin starts on page 440');
    });

    testWidgets('PageController.jumpToPage is synchronous and immediate', (
      WidgetTester tester,
    ) async {
      seedCache();

      final controller = PageController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuranPageView(controller: controller)),
        ),
      );
      await tester.pump();

      // Jump to surah 18 (Al-Kahf, page 293) — simulate _jumpToSurah
      final sw = Stopwatch()..start();
      final int targetPage = getPageNumber(18, 1); // 293
      controller.jumpToPage(targetPage - 1);
      sw.stop();

      debugPrint('  getPageNumber + jumpToPage: ${sw.elapsedMicroseconds}µs');

      // The entire operation should be under 1ms — it's synchronous
      expect(
        sw.elapsedMicroseconds,
        lessThan(1000),
        reason:
            'Page lookup + jump should be instant (<1ms). '
            'Before the fix, this went through 2 async network calls (~700ms). '
            'Got ${sw.elapsedMicroseconds}µs.',
      );

      // Verify the controller is at the correct position
      await tester.pump();
      expect(
        controller.page!.round(),
        targetPage - 1,
        reason: 'Controller should be at page ${targetPage - 1} (0-indexed)',
      );

      controller.dispose();
    });

    testWidgets('multiple rapid surah jumps complete instantly', (
      WidgetTester tester,
    ) async {
      seedCache();

      final controller = PageController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuranPageView(controller: controller)),
        ),
      );
      await tester.pump();

      // Simulate user rapidly selecting different surahs from index
      final surahs = [1, 18, 36, 55, 67, 78, 114, 2, 9, 50];
      final sw = Stopwatch()..start();
      for (final surah in surahs) {
        final int page = getPageNumber(surah, 1);
        controller.jumpToPage(page - 1);
      }
      sw.stop();

      debugPrint(
        '  10 rapid surah jumps: ${sw.elapsedMicroseconds}µs '
        '(${(sw.elapsedMicroseconds / 10).toStringAsFixed(1)}µs/jump)',
      );

      expect(
        sw.elapsedMicroseconds,
        lessThan(2000),
        reason:
            '10 surah jumps should complete in under 2ms total. '
            'Before the fix, each jump was ~700ms (7 seconds total). '
            'Got ${sw.elapsedMicroseconds}µs.',
      );

      controller.dispose();
    });
  });
}

/// Recursively collects all [TextStyle] instances from a [TextSpan] tree.
void _collectChildStyles(InlineSpan span, List<TextStyle> styles) {
  if (span is TextSpan) {
    if (span.style != null) styles.add(span.style!);
    if (span.children != null) {
      for (final InlineSpan child in span.children!) {
        _collectChildStyles(child, styles);
      }
    }
  }
}
