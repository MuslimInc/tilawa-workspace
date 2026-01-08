import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/entities/audio.dart';
import '../../../../core/extensions.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../audio_player/presentation/bloc/audio_player_bloc.dart';
import '../../domain/entities/entities.dart';
import '../bloc/quran_reader_bloc.dart';
import '../widgets/quran_page_widget.dart';
import '../widgets/widgets.dart';

/// Screen for reading Quran text.
///
/// NOTE: This screen expects a [QuranReaderBloc] to be provided in the widget tree.
/// The bloc is provided by [QuranReaderRoute] in the router configuration.
class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
  });

  final int surahNumber;
  final int? initialAyah;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late PageController _pageController;
  bool _firstLoad = true;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadSettings();
  }

  void _loadSettings() {
    context.read<QuranReaderBloc>().add(const QuranReaderEvent.loadSettings());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<QuranReaderBloc, QuranReaderState>(
        listener: (context, state) {
          // Handle initial navigation to surah's start page
          if (state.currentSurah != null && _firstLoad) {
            final int startPage = state.currentSurah!.startPage ?? 1;
            // Post frame to ensure controller is attached
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(startPage - 1);
                // Trigger load for the start page
                context.read<QuranReaderBloc>().add(
                  QuranReaderEvent.loadPage(startPage),
                );
              }
            });
            _firstLoad = false;
          }
        },
        builder: (context, state) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            child: Stack(
              children: [
                // Main content
                _buildContent(context, state),

                // Top bar
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: _showControls ? 0 : -100,
                  left: 0,
                  right: 0,
                  child: QuranReaderAppBar(
                    title:
                        state.currentPage?.ayahs.firstOrNull?.surahName ??
                        state.currentSurah?.name ??
                        '',
                    subtitle:
                        state
                            .currentPage
                            ?.ayahs
                            .firstOrNull
                            ?.surahNameEnglish ??
                        state.currentSurah?.nameEnglish ??
                        '',
                    onBack: () => Navigator.of(context).pop(),
                    onSearch: () => _showSearchDialog(context),
                    onSettings: () => _showSettingsSheet(context, state),
                  ),
                ),

                // Bottom controls
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  bottom: _showControls ? 0 : -100,
                  left: 0,
                  right: 0,
                  child: QuranReaderBottomBar(
                    surahNumber: widget.surahNumber,
                    settings: state.settings,
                    onFontSizeChanged: (size) {
                      context.read<QuranReaderBloc>().add(
                        QuranReaderEvent.updateFontSize(size),
                      );
                    },
                    onPreviousSurah: widget.surahNumber > 1
                        ? () => _navigateToSurah(widget.surahNumber - 1)
                        : null,
                    onNextSurah: widget.surahNumber < 114
                        ? () => _navigateToSurah(widget.surahNumber + 1)
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, QuranReaderState state) {
    // If we have no pages and are loading, show global loader
    if (state.status == QuranReaderStatus.loading && state.pages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == QuranReaderStatus.error && state.pages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(state.errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<QuranReaderBloc>().add(
                  QuranReaderEvent.loadSurah(widget.surahNumber),
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // PageView
    return PageView.builder(
      controller: _pageController,
      itemCount: 604, // Standard Madani Mushaf pages
      onPageChanged: (index) {
        final int pageNum = index + 1;
        // Pre-load next page logic could go here
        context.read<QuranReaderBloc>().add(QuranReaderEvent.loadPage(pageNum));
      },
      itemBuilder: (context, index) {
        final int pageNum = index + 1;
        final QuranPageEntity? pageEntity = state.pages[pageNum];

        if (pageEntity != null) {
          return QuranPageWidget(page: pageEntity);
        } else {
          // Trigger load if not loading and not loaded
          // Using post-frame callback to avoid state change during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<QuranReaderBloc>().add(
              QuranReaderEvent.loadPage(pageNum),
            );
          });
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  void _navigateToSurah(int surahNumber) {
    context.read<QuranReaderBloc>().add(
      QuranReaderEvent.loadSurah(surahNumber),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final QuranReaderBloc bloc = context.read<QuranReaderBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) =>
          BlocProvider.value(value: bloc, child: const AyahSearchDialog()),
    );
  }

  void _showSettingsSheet(BuildContext context, QuranReaderState state) {
    final QuranReaderBloc bloc = context.read<QuranReaderBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => ReaderSettingsSheet(
        settings: state.settings,
        onSettingsChanged: (settings) {
          bloc.add(QuranReaderEvent.updateSettings(settings));
        },
      ),
    );
  }

  void _showAyahOptionsSheet(BuildContext context, AyahEntity ayah) {
    final QuranReaderState state = context.read<QuranReaderBloc>().state;
    final String surahName =
        state.currentSurah?.nameEnglish ?? 'Surah ${ayah.surahNumber}';

    showModalBottomSheet(
      context: context,
      builder: (modalContext) => AyahOptionsSheet(
        ayah: ayah,
        onCopy: () {
          _copyAyahToClipboard(ayah, surahName);
          Navigator.pop(modalContext);
        },
        onShare: () {
          _shareAyah(ayah, surahName);
          Navigator.pop(modalContext);
        },
        onBookmark: () {
          // TODO: Add bookmark functionality
          ToastUtils.showToast(msg: context.l10n.comingSoon);
          Navigator.pop(modalContext);
        },
        onPlay: () {
          _playAyahAudio(ayah, surahName);
          Navigator.pop(modalContext);
        },
      ),
    );
  }

  void _copyAyahToClipboard(AyahEntity ayah, String surahName) {
    final text =
        '${ayah.text}\n\n- $surahName, ${context.l10n.ayah} ${ayah.numberInSurah}';
    Clipboard.setData(ClipboardData(text: text));
    ToastUtils.showSuccessToast(context.l10n.copiedToClipboard);
  }

  void _shareAyah(AyahEntity ayah, String surahName) {
    final text =
        '${ayah.text}\n\n- $surahName, ${context.l10n.ayah} ${ayah.numberInSurah}';
    Clipboard.setData(ClipboardData(text: text));
    ToastUtils.showSuccessToast('Copied to clipboard for sharing');
  }

  void _playAyahAudio(AyahEntity ayah, String surahName) {
    final audioUrl =
        'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${ayah.number}.mp3';

    final audioEntity = AudioEntity(
      id: 'ayah_${ayah.surahNumber}_${ayah.numberInSurah}',
      title: '$surahName - ${context.l10n.ayah} ${ayah.numberInSurah}',
      url: audioUrl,
      duration: const Duration(seconds: 30),
      artist: 'Mishary Rashid Alafasy',
      album: surahName,
    );

    try {
      final AudioPlayerBloc audioBloc = getIt<AudioPlayerBloc>();
      audioBloc.add(AudioPlayerEvent.playFromQueue([audioEntity], 0));
      ToastUtils.showToast(
        msg: 'Playing: ${context.l10n.ayah} ${ayah.numberInSurah}',
      );
    } catch (e) {
      ToastUtils.showErrorToast(context.l10n.errorPlayingAudio);
    }
  }
}
