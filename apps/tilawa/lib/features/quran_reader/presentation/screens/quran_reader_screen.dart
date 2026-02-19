import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart';

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
  final bool _firstLoad = true;
  final bool _showControls = true;

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
    return const Scaffold(body: PageviewQuran());
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
}
