import 'package:flutter/material.dart';
import 'package:quran/quran.dart';

import 'quran_reader_screen.dart';

/// Screen that ensures QCF4 fonts are downloaded and loaded into the Flutter engine
/// before displaying the actual [QuranReaderScreen].
class QuranFontLoaderScreen extends StatefulWidget {
  const QuranFontLoaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
  });

  /// The surah number to open initially after loading fonts.
  final int surahNumber;

  /// Optional initial ayah to scroll to after loading fonts.
  final int? initialAyah;

  @override
  State<QuranFontLoaderScreen> createState() => _QuranFontLoaderScreenState();
}

class _QuranFontLoaderScreenState extends State<QuranFontLoaderScreen> {
  final QuranFontService _fontService = QuranFontService();
  bool _isLoading = true;
  double _progress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initFonts();
  }

  Future<void> _initFonts() async {
    try {
      final isDownloaded = await _fontService.areFontsDownloaded();
      if (!isDownloaded) {
        // Download and extract zip
        await _fontService.downloadFonts(
          onProgress: (progress) {
            setState(() {
              _progress = progress;
            });
          },
        );
      }

      // We always need to load them to engine per app session
      setState(() {
        // Keep at 1.0 or reset text to "Registering fonts..."
        _progress = 1.0;
      });
      await _fontService.loadFontsToEngine();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 64,
                  color: Color(0xFFA68B67),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Preparing High-Quality Quran Fonts...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This is a one-time download (~50MB) for the best reading experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFA68B67),
                  ),
                ),
                const SizedBox(height: 16),
                Text('${(_progress * 100).toInt()}%'),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load fonts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _isLoading = true;
                      _progress = 0.0;
                    });
                    _initFonts();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA68B67),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return QuranReaderScreen(
      surahNumber: widget.surahNumber,
      initialAyah: widget.initialAyah,
    );
  }
}
