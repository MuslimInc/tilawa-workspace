import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/get_last_read_position_use_case.dart';
import 'package:tilawa/features/quran_reader/presentation/cubit/quran_settings_cubit.dart';
import 'package:tilawa/features/quran_reader/presentation/cubit/quran_surah_cubit.dart';
import 'package:tilawa/features/quran_reader/presentation/screens/quran_image_reader_screen.dart';
import 'package:tilawa/features/quran_reader/presentation/screens/quran_surah_screen.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_reader_view_toggle.dart';

/// Hosts the Mushaf image reader (default) and the Behance ayah-list reader.
///
/// The active view is persisted in [ReaderSettingsEntity.viewMode] so users
/// can switch without stacking routes.
class QuranReaderHostScreen extends StatefulWidget {
  const QuranReaderHostScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
    this.openPracticeOnLaunch = false,
  });

  /// Surah number to open (`1`–`114`), or `0` to resume last-read in Mushaf.
  final int surahNumber;

  final int? initialAyah;
  final bool openPracticeOnLaunch;

  @override
  State<QuranReaderHostScreen> createState() => _QuranReaderHostScreenState();
}

class _QuranReaderHostScreenState extends State<QuranReaderHostScreen> {
  late final QuranSettingsCubit _settingsCubit;
  late int _activeSurah;
  int? _activeAyah;
  bool _ayahListVisited = false;

  @override
  void initState() {
    super.initState();
    _settingsCubit = getIt<QuranSettingsCubit>();
    unawaited(_settingsCubit.load());
    _activeSurah = widget.surahNumber > 0 ? widget.surahNumber : 1;
    _activeAyah = widget.initialAyah;
    if (widget.surahNumber == 0) {
      unawaited(_loadLastReadSurah());
    }
  }

  Future<void> _loadLastReadSurah() async {
    final result = await getIt<GetLastReadPositionUseCase>()();
    result.fold((_) {}, (position) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (position.surahNumber != null) {
          _activeSurah = position.surahNumber!;
        }
        _activeAyah = position.ayahNumber ?? _activeAyah;
      });
    });
  }

  Future<void> _switchToMushaf() {
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
    return BlocProvider<QuranSettingsCubit>.value(
      value: _settingsCubit,
      child: BlocBuilder<QuranSettingsCubit, ReaderSettingsEntity>(
        buildWhen: (previous, current) => previous.viewMode != current.viewMode,
        builder: (context, settings) {
          final bool showAyahList =
              settings.viewMode == QuranReaderViewMode.ayahList;
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
    return Stack(
      fit: StackFit.expand,
      children: [
        QuranImageReaderScreen(
          surahNumber: widget.surahNumber,
          initialAyah: widget.initialAyah,
          openPracticeOnLaunch: widget.openPracticeOnLaunch,
          onActiveSurahChanged: _onActiveSurahChanged,
        ),
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: QuranReaderViewToggle(
              currentMode: settings.viewMode,
              onDarkBackground: true,
              onPressed: _switchToAyahList,
            ),
          ),
        ),
      ],
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
