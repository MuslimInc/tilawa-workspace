import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/get_last_read_position_use_case.dart';
import 'package:tilawa/features/quran_reader/presentation/cubit/quran_settings_cubit.dart';
import 'package:tilawa/features/quran_reader/presentation/cubit/quran_surah_cubit.dart';
import 'package:tilawa/features/quran_reader/presentation/screens/quran_image_reader_screen.dart';
import 'package:tilawa/features/quran_reader/presentation/screens/quran_surah_screen.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_reader_view_toggle.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Hosts the Mushaf image reader (default) and the Behance ayah-list reader.
///
/// The active view is persisted in [ReaderSettingsEntity.viewMode] so users
/// can switch without stacking routes.
///
/// On web, image Mushaf cache uses `dart:io` / path_provider and is unavailable;
/// the host stays on ayah-list until a web-capable image cache exists.

/// Merges a persisted last-read position onto the host's active coordinates.
@visibleForTesting
({int surah, int? ayah, int? page}) applyLastReadPosition({
  required int currentSurah,
  required int? currentAyah,
  required int? currentPage,
  required ({int? surahNumber, int? ayahNumber, int? page}) position,
}) {
  return (
    surah: position.surahNumber ?? currentSurah,
    ayah: position.ayahNumber ?? currentAyah,
    page: position.page ?? currentPage,
  );
}

class QuranReaderHostScreen extends StatefulWidget {
  const QuranReaderHostScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
    this.initialPage,
    this.firstPage,
    this.lastPage,
    this.showSaveProgressAction = false,
    this.openPracticeOnLaunch = false,
  });

  /// Surah number to open (`1`–`114`), or `0` to resume last-read in Mushaf.
  final int surahNumber;

  final int? initialAyah;
  final int? initialPage;

  /// Optional Mushaf page window (inclusive). Used by Khatma reader.
  final int? firstPage;
  final int? lastPage;
  final bool showSaveProgressAction;
  final bool openPracticeOnLaunch;

  @override
  State<QuranReaderHostScreen> createState() => _QuranReaderHostScreenState();
}

class _QuranReaderHostScreenState extends State<QuranReaderHostScreen> {
  late final QuranSettingsCubit _settingsCubit;
  late int _activeSurah;
  int? _activeAyah;
  int? _activePage;
  bool _ayahListVisited = false;
  bool _isLoadingLastRead = false;

  @override
  void initState() {
    super.initState();
    _settingsCubit = getIt<QuranSettingsCubit>();
    unawaited(_settingsCubit.load());
    _isLoadingLastRead = widget.surahNumber == 0;
    _activeSurah = widget.surahNumber > 0 ? widget.surahNumber : 1;
    _activeAyah = widget.initialAyah;
    _activePage = widget.initialPage;
    if (kIsWeb) {
      // Image Mushaf prepare fails on web (MissingPluginException / dart:io).
      _ayahListVisited = true;
      unawaited(_settingsCubit.setViewMode(QuranReaderViewMode.ayahList));
    }
    if (widget.surahNumber == 0) {
      unawaited(_loadLastReadSurah());
    }
  }

  Future<void> _loadLastReadSurah() async {
    final result = await getIt<GetLastReadPositionUseCase>()();
    result.fold(
      (_) {
        if (mounted) {
          setState(() {
            _isLoadingLastRead = false;
          });
        }
      },
      (position) {
        if (!mounted) {
          return;
        }
        setState(() {
          final resolved = applyLastReadPosition(
            currentSurah: _activeSurah,
            currentAyah: _activeAyah,
            currentPage: _activePage,
            position: position,
          );
          _activeSurah = resolved.surah;
          _activeAyah = resolved.ayah;
          _activePage = resolved.page;
          _isLoadingLastRead = false;
        });
      },
    );
  }

  Future<void> _switchToMushaf() {
    if (kIsWeb) {
      return Future<void>.value();
    }
    return _settingsCubit.setViewMode(QuranReaderViewMode.mushaf);
  }

  Future<void> _switchToAyahList() {
    setState(() => _ayahListVisited = true);
    return _settingsCubit.setViewMode(QuranReaderViewMode.ayahList);
  }

  void _onActiveSurahChanged(int surah) {
    if (_activeSurah == surah) {
      return;
    }
    setState(() => _activeSurah = surah);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLastRead) {
      return const Scaffold(
        body: Center(
          child: TilawaLoadingIndicator(),
        ),
      );
    }
    return BlocProvider<QuranSettingsCubit>.value(
      value: _settingsCubit,
      child: BlocBuilder<QuranSettingsCubit, ReaderSettingsEntity>(
        buildWhen: (previous, current) => previous.viewMode != current.viewMode,
        builder: (context, settings) {
          final bool showAyahList =
              kIsWeb || settings.viewMode == QuranReaderViewMode.ayahList;
          return IndexedStack(
            index: showAyahList ? 1 : 0,
            sizing: StackFit.expand,
            children: [
              _buildMushafLayer(settings),
              if (_ayahListVisited || showAyahList)
                _buildAyahListLayer()
              else
                const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMushafLayer(ReaderSettingsEntity settings) {
    // The view switch now lives in the reader's bottom navigation panel
    // (thumb-reachable) instead of the hard-to-reach top corner.
    final bool isKhatmaSession = widget.showSaveProgressAction;
    return QuranImageReaderScreen(
      surahNumber: _activeSurah,
      initialAyah: _activeAyah,
      initialPage: _activePage,
      firstPage: widget.firstPage,
      lastPage: widget.lastPage,
      openPracticeOnLaunch: widget.openPracticeOnLaunch,
      onActiveSurahChanged: _onActiveSurahChanged,
      // Khatma is page-windowed — Surah index is for full Mushaf browse only.
      showSurahIndex: !isKhatmaSession,
      // Save Progress lives in the nav overlay (not a FAB over ayahs).
      // Ayah-list toggle stays off for bounded Khatma sessions.
      viewSwitchAction: isKhatmaSession
          ? TilawaButton(
              text: context.l10n.khatmaSaveProgressAction,
              isFullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            )
          : QuranReaderViewToggle(
              currentMode: settings.viewMode,
              onPressed: _switchToAyahList,
            ),
    );
  }

  Widget _buildAyahListLayer() {
    return BlocProvider(
      key: ValueKey<int>(_activeSurah),
      create: (_) => getIt<QuranSurahCubit>()..load(_activeSurah),
      child: QuranSurahScreen(
        surahNumber: _activeSurah,
        initialAyah: _activeAyah,
        onSwitchToMushaf: _switchToMushaf,
      ),
    );
  }
}
