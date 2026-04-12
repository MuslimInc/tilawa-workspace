import 'package:flutter/material.dart';

import 'core/di/dependency_injection.dart';
import 'domain/entities/page_state.dart';
import 'domain/repositories/verse_marker_repository.dart';

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
  @override
  void initState() {
    super.initState();
    _waitForPreload();
  }

  Future<void> _waitForPreload() async {
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
    widget.onPreloadComplete();
  }

  @override
  Widget build(BuildContext context) {
    final repo = sl<VerseMarkerRepository>();
    final progress = repo.preloadProgress;
    final percentage = (progress * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF4E4),
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
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
