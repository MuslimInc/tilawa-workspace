import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/quran_reader_bloc.dart';
import '../bloc/settings/quran_settings_bloc.dart';
import '../widgets/quran_reader_content.dart';
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
    final QuranReaderBloc bloc = context.read<QuranReaderBloc>();
    // Settings are now loaded by AppProviders globally
    // bloc.add(const QuranReaderEvent.loadSettings());

    // Trigger initial Surah load
    bloc.add(QuranReaderEvent.loadSurah(widget.surahNumber));
    // Also preload pages structure
    bloc.add(const QuranReaderEvent.preloadAllPages());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<QuranReaderBloc, QuranReaderState>(
        listener: (context, state) {
          // Handle programmatic jumps (e.g., from search)
          if (state.jumpToPage != null) {
            _jumpToPageAndLoad(state.jumpToPage!);
          }

          // Handle initial navigation to surah's start page
          if (state.currentSurah != null && _firstLoad) {
            final int startPage = state.currentSurah!.startPage ?? 1;
            _jumpToPageAndLoad(startPage);
            _firstLoad = false;
          }
        },
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showControls = !_showControls;
            });
          },
          child: Stack(
            children: [
              // Main content
              BlocBuilder<QuranReaderBloc, QuranReaderState>(
                buildWhen: (previous, current) {
                  return previous.status != current.status ||
                      previous.pages != current.pages ||
                      previous.isPreloading != current.isPreloading;
                },
                builder: (context, state) {
                  // Show loading when initializing
                  // Show loading when initializing
                  if (state.isPreloading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return QuranReaderContent(
                    pages: state.pages.values.toList(),
                    pageController: _pageController,
                    onPageChanged: (index) {
                      final int page = index + 1;
                      // Just update the tracker, no need to fetch content anymore
                      context.read<QuranReaderBloc>().add(
                        QuranReaderEvent.loadPage(page),
                      );
                    },
                  );
                },
              ),

              // Top bar
              BlocBuilder<QuranSettingsBloc, QuranSettingsState>(
                buildWhen: (previous, current) =>
                    previous.settings != current.settings,
                builder: (context, settingsState) {
                  return BlocBuilder<QuranReaderBloc, QuranReaderState>(
                    buildWhen: (previous, current) =>
                        previous.currentPage != current.currentPage ||
                        previous.currentSurah != current.currentSurah,
                    builder: (context, state) {
                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        top: _showControls ? 0 : -200,
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
                          onSettings: () =>
                              _showSettingsSheet(context, settingsState),
                        ),
                      );
                    },
                  );
                },
              ),

              // Bottom controls
              BlocBuilder<QuranReaderBloc, QuranReaderState>(
                buildWhen: (previous, current) =>
                    previous.currentPage != current.currentPage,
                builder: (context, state) {
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    bottom: _showControls ? 0 : -200,
                    left: 0,
                    right: 0,
                    child: QuranReaderBottomBar(
                      currentPage: state.currentPage?.pageNumber ?? 1,
                      totalPages: 604,
                      onPageChanged: (page) {
                        _pageController.jumpToPage(page - 1);
                        context.read<QuranReaderBloc>().add(
                          QuranReaderEvent.loadPage(page),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
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

  void _showSettingsSheet(BuildContext context, QuranSettingsState state) {
    final QuranSettingsBloc settingsBloc = context.read<QuranSettingsBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => ReaderSettingsSheet(
        settings: state.settings,
        onSettingsChanged: (settings) {
          settingsBloc.add(QuranSettingsEvent.updateSettings(settings));
        },
      ),
    );
  }

  /// Robustly attempts to jump to a page and load its data.
  /// Retries until [PageController] has clients attached.
  void _jumpToPageAndLoad(int pageNumber) {
    if (!mounted) return;

    if (_pageController.hasClients) {
      _pageController.jumpToPage(pageNumber - 1);
      // Just track the page change
      final QuranReaderBloc bloc = context.read<QuranReaderBloc>();
      bloc.add(QuranReaderEvent.loadPage(pageNumber));
    } else {
      // Retry in next frame if controller not yet attached
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpToPageAndLoad(pageNumber);
      });
    }
  }
}
