import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/features/quran_reader/presentation/theme/quran_reader_theme.dart';
import 'package:tilawa_core/logger.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class QuranRenderDemoScreen extends StatefulWidget {
  const QuranRenderDemoScreen({super.key, this.pageNumber = 5});

  final int pageNumber;

  @override
  State<QuranRenderDemoScreen> createState() => _QuranRenderDemoScreenState();
}

class _QuranRenderDemoScreenState extends State<QuranRenderDemoScreen> {
  late PageController _pageController;
  final Stopwatch _overallWatch = Stopwatch();
  final List<String> _logs = [];
  bool _isLoading = true;
  bool _isWarming = false;
  final int _activePageIndex = 0;
  static const int _startPage = 5;
  static const int _endPage = 20;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _runRenderTest(_startPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().split(' ').last;
    final logMessage = '[$timestamp] $message';
    _logs.add(logMessage);
    // Use print logs as requested
    // Use print logs as requested
    logger.i(message);
    if (mounted) setState(() {});
  }

  Future<void> _runRenderTest(int pageNumber) async {
    _overallWatch.reset();
    _overallWatch.start();
    _addLog('--- Testing Page $pageNumber ---');

    setState(() => _isLoading = true);

    try {
      // 1. Data Loading implicitly checked by initial page
      await quranQcfLocator<MushafService>().ensureLoaded();

      // 2. Font Registration
      final fontWatch = Stopwatch()..start();
      await quranQcfLocator<QuranFontService>().ensureSingleFontLoaded(
        pageNumber,
      );
      fontWatch.stop();
      _addLog(
        '🔤 Page $pageNumber Font Registered: ${fontWatch.elapsedMilliseconds}ms',
      );

      // 3. Trigger build
      final buildWatch = Stopwatch()..start();
      setState(() {
        _isLoading = false;
        _isWarming = false;
      });

      // Measure frame timing
      SchedulerBinding.instance.addPostFrameCallback((_) {
        // Only log if it's still the same page
        if (!mounted) return;
        buildWatch.stop();
        _addLog(
          '🎨 Page $pageNumber Build + First Frame: ${buildWatch.elapsedMilliseconds}ms',
        );

        SchedulerBinding.instance.endOfFrame.then((_) {
          if (!mounted) return;
          _overallWatch.stop();
          _addLog(
            '✨ Page $pageNumber Total: ${_overallWatch.elapsedMilliseconds}ms',
          );
        });
      });
    } catch (e, s) {
      _addLog('❌ Error: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readerTheme = QuranReaderTheme.of(context);
    final tokens = Theme.of(context).tokens;

    return Scaffold(
      backgroundColor: readerTheme.pageBackground,
      appBar: const TilawaAppBar(
        title: 'PageView Render Benchmark (5-20)',
        showBottomHairline: false,
      ),
      body: Column(
        children: [
          // Render Area
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _endPage - _startPage + 1,
                onPageChanged: (index) {
                  final pageNum = _startPage + index;
                  _addLog('➡️ Navigated to Index $index (Page $pageNum)');
                  _runRenderTest(pageNum);
                },
                itemBuilder: (context, index) {
                  final pageNum = _startPage + index;
                  return _isLoading && index == _activePageIndex
                      ? const TilawaLoadingIndicator()
                      : PageContent(
                          pageNumber: pageNum,
                          isWarming: _isWarming,
                          textColor: readerTheme.textColor,
                          pageBackgroundColor: readerTheme.pageBackground,
                          mushafService: quranQcfLocator<MushafService>(),
                          pageSnapshotService:
                              quranQcfLocator<PageSnapshotService>(),
                        );
                },
              ),
            ),
          ),

          // Log Area
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.black.withValues(alpha: 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Logs',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            _logs[_logs.length - 1 - index],
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
