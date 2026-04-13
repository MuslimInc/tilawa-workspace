import 'package:flutter/material.dart';
import 'package:quran_image_flutter/core/design_tokens/colors.dart';

import 'core/di/dependency_injection.dart';
import 'domain/entities/page_state.dart';
import 'domain/entities/quran_image_cache_status.dart';
import 'domain/repositories/verse_marker_repository.dart';
import 'domain/usecases/prepare_quran_image_cache.dart';

/// Loading screen shown while preloading debug marker files.
///
/// This ensures users wait until all pages are ready before reading.
class PreloadingScreen extends StatefulWidget {
  final VoidCallback onPreloadComplete;

  const PreloadingScreen({super.key, required this.onPreloadComplete});

  @override
  State<PreloadingScreen> createState() => _PreloadingScreenState();
}

class _PreloadingScreenState extends State<PreloadingScreen> {
  QuranImageCacheStatus _cacheStatus = const QuranImageCacheStatus.checking();
  String? _errorMessage;
  bool _isPreparing = false;

  @override
  void initState() {
    super.initState();
    _waitForPreload();
  }

  Future<void> _waitForPreload() async {
    if (_isPreparing) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _isPreparing = true;
    });

    final cacheStatus = await sl<PrepareQuranImageCacheUseCase>()(
      onProgress: (status) {
        if (!mounted) {
          return;
        }
        setState(() {
          _cacheStatus = status;
        });
      },
    );

    if (!cacheStatus.isReady) {
      if (mounted) {
        setState(() {
          _cacheStatus = cacheStatus;
          _errorMessage = cacheStatus.errorMessage ?? cacheStatus.message;
          _isPreparing = false;
        });
      }
      return;
    }

    final repo = sl<VerseMarkerRepository>();

    // Wait for preloading to complete
    if (repo.isDebugMode && repo.isPreloading) {
      // Poll until preloading is complete
      while (repo.isPreloading) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {});
        }
      }
    }

    // Notify parent that preloading is complete
    if (mounted) {
      widget.onPreloadComplete();
    }
  }

  String _getFriendlyErrorMessage(String rawMessage) {
    if (rawMessage.contains('SocketException') ||
        rawMessage.contains('Failed host lookup') ||
        rawMessage.contains('No address associated with hostname') ||
        rawMessage.contains('Connection refused')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (rawMessage.contains('OS Error') || rawMessage.contains('Exception:')) {
      return 'An unexpected error occurred. Please try again.';
    }
    return rawMessage;
  }

  @override
  Widget build(BuildContext context) {
    final repo = sl<VerseMarkerRepository>();
    final markerProgress = repo.preloadProgress;
    final progress = _cacheStatus.isReady
        ? markerProgress
        : _cacheStatus.progress;
    final percentage = (progress * 100).toStringAsFixed(0);
    final errorMessage = _errorMessage;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Quran Image',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 40),
            if (errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  _getFriendlyErrorMessage(errorMessage),
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
                child: const Text('Retry'),
              ),
            ] else if (!_cacheStatus.isReady) ...[
              Text(
                _cacheStatus.message,
                style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 20),
              // Progress bar
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
            ] else ...[
              if (repo.isDebugMode) ...[
                const Text(
                  'Loading marker coordinates...',
                  style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 20),
                // Progress bar
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
                const SizedBox(height: 8),
                Text(
                  'Page '
                  '${(progress * PageState.quranPageCount).toStringAsFixed(0)}'
                  ' of ${PageState.quranPageCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
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
