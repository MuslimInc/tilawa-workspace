import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';

import '../bloc/quran_font_loader_bloc.dart';
import 'quran_reader_screen.dart';

/// Screen that ensures QCF4 fonts are downloaded and loaded into the Flutter engine
/// before displaying the actual [QuranReaderScreen].
class QuranFontLoaderScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocConsumer<QuranFontLoaderBloc, QuranFontLoaderState>(
      listener: (context, state) {
        state.maybeWhen(
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          },
          orElse: () {},
        );
      },
      builder: (context, state) {
        return state.maybeWhen(
          success: () => QuranReaderScreen(
            surahNumber: surahNumber,
            initialAyah: initialAyah,
          ),
          error: (message) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.fontsFailedToLoad,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<QuranFontLoaderBloc>().add(
                          const QuranFontLoaderEvent.initialize(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA68B67),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(context.l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
          orElse: () {
            final isDownloading = state.maybeWhen(
              downloading: (_) => true,
              orElse: () => false,
            );
            final progress = state.maybeWhen(
              downloading: (p) => p,
              orElse: () => 0.0,
            );

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
                      Text(
                        isDownloading
                            ? context.l10n.preparingFonts
                            : context.l10n.loadingQuran,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isDownloading) ...[
                        Text(
                          context.l10n.fontsDownloadDescription,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 32),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFA68B67),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('${(progress * 100).toInt()}%'),
                      ] else ...[
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFA68B67),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
