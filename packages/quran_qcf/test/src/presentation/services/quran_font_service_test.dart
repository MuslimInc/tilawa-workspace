import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quran_qcf/quran_qcf.dart';

class MockQuranMushafService extends Mock implements QuranMushafService {}

class MockIdleScheduler extends Mock implements IdleScheduler {}

class MockIdleTask extends Mock implements IdleTask {}

class ImmediateIdleTask implements IdleTask {
  ImmediateIdleTask(this._completer);

  final Completer<void> _completer;
  bool _cancelled = false;

  @override
  bool get isCancelled => _cancelled;

  @override
  bool get isCompleted => _completer.isCompleted;

  @override
  Future<void> get future => _completer.future;

  @override
  void cancel() {
    if (_cancelled || _completer.isCompleted) return;
    _cancelled = true;
    _completer.complete();
  }
}

class ImmediateIdleScheduler implements IdleScheduler {
  final List<ImmediateIdleTask> _tasks = <ImmediateIdleTask>[];
  int scheduledCount = 0;

  @override
  void cancelAll() {
    for (final ImmediateIdleTask task in _tasks) {
      task.cancel();
    }
  }

  @override
  IdleTask runWhenIdle(Future<void> Function() task) {
    scheduledCount += 1;
    final completer = Completer<void>();
    final idleTask = ImmediateIdleTask(completer);
    _tasks.add(idleTask);

    unawaited(
      Future<void>(() async {
        if (idleTask.isCancelled) {
          if (!completer.isCompleted) completer.complete();
          return;
        }

        try {
          await task();
        } finally {
          if (!completer.isCompleted) completer.complete();
        }
      }),
    );

    return idleTask;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranFontService', () {
    late QuranFontService service;
    late MockQuranMushafService mushafService;
    late MockIdleScheduler idleScheduler;
    late Directory tempRoot;

    Directory ensureFontDir() {
      final fontDir = Directory('${tempRoot.path}/qcf4_fonts');
      fontDir.createSync(recursive: true);
      return fontDir;
    }

    void writeFontFile(String name, {List<int> bytes = const [1, 2, 3]}) {
      final Directory fontDir = ensureFontDir();
      File('${fontDir.path}/$name').writeAsBytesSync(bytes);
    }

    void seedPageFontFiles(Iterable<int> pages) {
      for (final page in pages) {
        writeFontFile('QCF4_${page.toString().padLeft(3, '0')}.woff');
      }
    }

    QuranFontService createService({
      IdleScheduler? scheduler,
      Future<void> Function(String family, Uint8List bytes)? fontRegistrar,
      String Function()? fontZipUrlProvider,
    }) {
      return QuranFontService(
        mushafService: mushafService,
        idleScheduler: scheduler ?? idleScheduler,
        documentsDirectoryProvider: () async => tempRoot,
        fontZipUrlProvider: fontZipUrlProvider,
        fontRegistrar: fontRegistrar ?? (_, _) async {},
      );
    }

    PreparedQuranPage buildPreparedPage() {
      final painter = TextPainter(
        text: const TextSpan(text: 'abc'),
        textDirection: TextDirection.rtl,
      )..layout();

      return PreparedQuranPage(
        metrics: const QuranLayoutMetrics(
          fontSize: 40,
          fontHeight: 40,
          isScrollable: false,
        ),
        blocks: <PreparedPageBlock>[
          PreparedTextBlock(
            painter: painter,
            metadata: const <QuranWordMetadata>[
              QuranWordMetadata(
                surah: 1,
                verse: 1,
                startOffset: 0,
                endOffset: 3,
              ),
            ],
          ),
        ],
      );
    }

    void disposePreparedPage(PreparedQuranPage page) {
      for (final PreparedPageBlock block in page.blocks) {
        if (block is PreparedTextBlock) {
          block.painter.dispose();
        }
      }
    }

    setUp(() async {
      mushafService = MockQuranMushafService();
      idleScheduler = MockIdleScheduler();

      when(() => mushafService.isLoaded).thenReturn(true);
      when(() => mushafService.ensureLoaded()).thenAnswer((_) async {});

      tempRoot = await Directory.systemTemp.createTemp(
        'quran_font_service_test',
      );

      service = QuranFontService(
        mushafService: mushafService,
        idleScheduler: idleScheduler,
        documentsDirectoryProvider: () async => tempRoot,
        fontRegistrar: (_, _) async {},
      );
    });

    tearDown(() async {
      service.dispose();
      idleScheduler.cancelAll();
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    });

    testWidgets('reports loaded state and debug reset helpers', (
      WidgetTester tester,
    ) async {
      expect(service.loadedCount, 0);
      expect(service.isFontLoaded(1), isFalse);

      service.debugMarkFontLoaded(1);
      expect(service.loadedCount, 1);
      expect(service.isFontLoaded(1), isTrue);

      service.debugResetForTests();
      expect(service.loadedCount, 0);
      expect(service.isFontLoaded(1), isFalse);
    });

    testWidgets('loads a single font from an existing local directory', (
      WidgetTester tester,
    ) async {
      final fontDir = Directory('${tempRoot.path}/qcf4_fonts');
      fontDir.createSync(recursive: true);

      final source = File(
        '/Users/mohammadkamel/flutter_projects/tilawa_workspace/packages/quran_qcf/assets/quran_fonts/QCF4_QBSML-Regular.woff',
      );
      final target = File('${fontDir.path}/QCF4_001.woff');
      target.writeAsBytesSync(source.readAsBytesSync());

      await tester.runAsync(() async {
        unawaited(service.ensureSingleFontLoaded(1));
        // Wait for the real font-load microtasks to complete.
        // (Awaiting ensureSingleFontLoaded directly deadlocks the fakeAsync
        // bridge loop; fire-and-forget + delay matches the pattern used by
        // the other runAsync tests in this file.)
        await Future.delayed(const Duration(milliseconds: 100));
      });

      expect(service.isFontLoaded(1), isTrue);
      expect(service.loadedCount, 1);
    });

    testWidgets('notifies listeners when font registry changes', (
      WidgetTester tester,
    ) async {
      var notifyCount = 0;
      service.addListener(() => notifyCount++);

      final fontDir = Directory('${tempRoot.path}/qcf4_fonts');
      fontDir.createSync(recursive: true);
      final source = File(
        '/Users/mohammadkamel/flutter_projects/tilawa_workspace/packages/quran_qcf/assets/quran_fonts/QCF4_QBSML-Regular.woff',
      );
      final target = File('${fontDir.path}/QCF4_001.woff');
      target.writeAsBytesSync(source.readAsBytesSync());

      await tester.runAsync(() async {
        unawaited(service.ensureSingleFontLoaded(1));
        // Wait for the REAL timer to fire because it was started inside runAsync
        await Future.delayed(const Duration(milliseconds: 100));
      });

      expect(notifyCount, 1);
    });

    testWidgets('notifies when Quran data becomes available', (
      WidgetTester tester,
    ) async {
      var isLoaded = false;
      var notifyCount = 0;

      service.addListener(() => notifyCount += 1);

      when(() => mushafService.isLoaded).thenAnswer((_) => isLoaded);
      when(() => mushafService.ensureLoaded()).thenAnswer((_) async {
        isLoaded = true;
      });

      await service.ensureQuranDataLoaded();
      await tester.pump(const Duration(milliseconds: 60));

      expect(service.isQuranDataLoaded, isTrue);
      expect(notifyCount, 1);
    });

    testWidgets('does not notify when Quran data was already loaded', (
      WidgetTester tester,
    ) async {
      var notifyCount = 0;
      service.addListener(() => notifyCount += 1);

      when(() => mushafService.isLoaded).thenReturn(true);
      when(() => mushafService.ensureLoaded()).thenAnswer((_) async {});

      await service.ensureQuranDataLoaded();
      await tester.pump(const Duration(milliseconds: 60));

      expect(service.isQuranDataLoaded, isTrue);
      expect(notifyCount, 0);
    });

    testWidgets(
      'reports fonts as downloaded only when the full bundle exists',
      (WidgetTester tester) async {
        writeFontFile('QCF4_001.woff');

        expect(await service.areFontsDownloaded(), isFalse);

        for (var page = 2; page <= QuranConstants.totalPagesCount; page++) {
          writeFontFile('QCF4_${page.toString().padLeft(3, '0')}.woff');
        }

        expect(await service.areFontsDownloaded(), isTrue);
        await tester.pump();
      },
    );

    test('warmPreparedPage schedules idle warm only once per family', () async {
      final immediateScheduler = ImmediateIdleScheduler();
      final PreparedQuranPage preparedPage = buildPreparedPage();
      service.dispose();
      service = createService(scheduler: immediateScheduler);

      try {
        service.warmPreparedPage(7, preparedPage);
        await Future.delayed(const Duration(milliseconds: 40));
        service.warmPreparedPage(7, preparedPage);
        await Future.delayed(const Duration(milliseconds: 40));

        expect(immediateScheduler.scheduledCount, 1);
      } finally {
        disposePreparedPage(preparedPage);
      }
    });

    test(
      'warmInitialPage schedules raw-data warm only once per family',
      () async {
        final immediateScheduler = ImmediateIdleScheduler();
        service.dispose();
        service = createService(scheduler: immediateScheduler);
        when(() => mushafService.getPageData(1)).thenReturn(
          const <List<WordData>>[
            <WordData>[
              WordData(
                text: 'abc',
                surah: 1,
                ayah: 1,
                wordIndex: 1,
                page: 1,
                line: 1,
              ),
            ],
          ],
        );

        service.warmInitialPage(1);
        await Future.delayed(const Duration(milliseconds: 40));
        service.warmInitialPage(1);
        await Future.delayed(const Duration(milliseconds: 40));

        expect(immediateScheduler.scheduledCount, 1);
      },
    );

    group('Advanced Font Indexing', () {
      testWidgets('resolves page family correctly from various file patterns', (
        WidgetTester tester,
      ) async {
        final fontDir = Directory('${tempRoot.path}/qcf4_fonts');
        fontDir.createSync(recursive: true);

        final dummyBytes = Uint8List.fromList([1, 2, 3]);

        File('${fontDir.path}/QCF4_163.woff').writeAsBytesSync(dummyBytes);
        File(
          '${fontDir.path}/QCF4001_X-Regular.woff',
        ).writeAsBytesSync(dummyBytes);
        File('${fontDir.path}/042.woff').writeAsBytesSync(dummyBytes);

        await tester.runAsync(() async {
          unawaited(service.ensureSingleFontLoaded(163));
          unawaited(service.ensureSingleFontLoaded(1));
          unawaited(service.ensureSingleFontLoaded(42));
          await Future.delayed(const Duration(milliseconds: 100));
        });

        expect(service.isFontLoaded(163), isTrue);
        expect(service.isFontLoaded(1), isTrue);
        expect(service.isFontLoaded(42), isTrue);
      });
    });
  });
}
