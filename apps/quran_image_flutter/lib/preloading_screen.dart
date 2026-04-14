import 'package:flutter/material.dart';
import 'package:quran_image_flutter/core/design_tokens/colors.dart';
import 'package:quran_image_flutter/data/repositories/asset_verse_marker_repository.dart';

import 'core/di/dependency_injection.dart';
import 'domain/entities/app_message.dart';
import 'domain/entities/page_state.dart';
import 'domain/entities/quran_image_cache_status.dart';
import 'domain/usecases/prepare_quran_image_cache.dart';
import 'l10n/app_localizations.dart';
import 'presentation/mappers/app_message_mapper.dart';

/// Loading screen shown while the Quran image cache is being prepared
/// and (in debug mode) verse marker files are being preloaded.
class PreloadingScreen extends StatefulWidget {
  final VoidCallback onPreloadComplete;

  const PreloadingScreen({super.key, required this.onPreloadComplete});

  @override
  State<PreloadingScreen> createState() => _PreloadingScreenState();
}

class _PreloadingScreenState extends State<PreloadingScreen> {
  QuranImageCacheStatus _cacheStatus = const QuranImageCacheStatus.checking();
  AppMessage? _errorAppMessage;
  bool _isPreparing = false;

  @override
  void initState() {
    super.initState();
    _waitForPreload();
  }

  Future<void> _waitForPreload() async {
    if (_isPreparing) return;

    setState(() {
      _errorAppMessage = null;
      _isPreparing = true;
    });

    final markerRepository = sl<AssetVerseMarkerRepository>();
    final markerInitFuture = markerRepository.isInitialized
        ? Future<void>.value()
        : markerRepository.init();

    final cacheStatus = await sl<PrepareQuranImageCacheUseCase>()(
      onProgress: (status) {
        if (!mounted) return;
        setState(() => _cacheStatus = status);
      },
    );

    try {
      await markerInitFuture;
    } catch (error) {
      debugPrint('PreloadingScreen marker init error: $error');
      if (mounted) {
        setState(() {
          _errorAppMessage = const CachePreparationFailedMessage();
          _isPreparing = false;
        });
      }
      return;
    }

    if (!cacheStatus.isReady) {
      if (mounted) {
        setState(() {
          _cacheStatus = cacheStatus;
          _errorAppMessage =
              cacheStatus.errorMessage?.toAppMessage() ??
              const CachePreparationFailedMessage();
          _isPreparing = false;
        });
      }
      return;
    }

    final repo = sl<AssetVerseMarkerRepository>();

    // In debug mode, wait for the background preload to finish by polling
    // the repository's preloadProgress at a low frequency.
    if (repo.isDebugMode && repo.isPreloading) {
      await _awaitPreloading(repo);
    }

    if (mounted) {
      setState(() {
        _isPreparing = false;
      });
      widget.onPreloadComplete();
    }
  }

  /// Waits for [repo.isPreloading] to become false by checking every 100 ms
  /// and driving a setState so the progress bar updates.
  Future<void> _awaitPreloading(AssetVerseMarkerRepository repo) async {
    while (repo.isPreloading) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() {});
    }
    if (mounted) {
      setState(() {
        _isPreparing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = sl<AssetVerseMarkerRepository>();
    final markerProgress = repo.preloadProgress;
    final progress = _cacheStatus.isReady
        ? markerProgress
        : _cacheStatus.progress;
    final errorAppMessage = _errorAppMessage;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              const AppTitleMessage().localize(l10n),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 40),
            if (errorAppMessage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  errorAppMessage.localize(l10n),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8A2D2D),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _waitForPreload,
                child: Text(const RetryMessage().localize(l10n)),
              ),
            ] else if (!_cacheStatus.isReady) ...[
              Text(
                _cacheStatus.phase.toAppMessage().localize(l10n),
                style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 20),
              _ProgressBar(progress: progress),
            ] else ...[
              if (repo.isDebugMode) ...[
                Text(
                  const PreparingQuranMessage().localize(l10n),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 20),
                _ProgressBar(
                  progress: progress,
                  subtitle: PageIndicatorMessage(
                    current: (progress * PageState.quranPageCount)
                        .toStringAsFixed(0),
                    total: PageState.quranPageCount.toString(),
                  ).localize(l10n),
                ),
              ] else ...[
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared progress bar widget
// ---------------------------------------------------------------------------

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, this.subtitle});

  final double progress;

  /// Optional line of text shown below the percentage label.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toStringAsFixed(0);
    return Column(
      children: [
        Container(
          width: 200,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$percentage%',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4CAF50),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ],
      ],
    );
  }
}
