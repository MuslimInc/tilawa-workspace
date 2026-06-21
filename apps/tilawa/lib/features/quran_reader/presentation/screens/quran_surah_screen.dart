import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/quran_reader/presentation/cubit/quran_settings_cubit.dart';
import 'package:tilawa/features/quran_reader/presentation/cubit/quran_surah_cubit.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/ayah_list_view.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/quran_reader_view_toggle.dart';
import 'package:tilawa/features/quran_reader/presentation/widgets/reader_settings_sheet.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';
import '../../domain/usecases/play_ayah_audio_use_case.dart';
import '../../domain/usecases/save_last_read_position_use_case.dart';

/// Behance-style surah reading screen with gold header and ayah list.
class QuranSurahScreen extends StatefulWidget {
  const QuranSurahScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
    this.onSwitchToMushaf,
  });

  final int surahNumber;
  final int? initialAyah;

  /// When set by [QuranReaderHostScreen], switches view mode instead of pushing
  /// a new Mushaf route.
  final VoidCallback? onSwitchToMushaf;

  @override
  State<QuranSurahScreen> createState() => _QuranSurahScreenState();
}

class _QuranSurahScreenState extends State<QuranSurahScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<QuranSurahCubit>().load(widget.surahNumber);
    _saveLastRead();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveLastRead() async {
    await getIt<SaveLastReadPositionUseCase>()(
      surahNumber: widget.surahNumber,
      ayahNumber: widget.initialAyah,
    );
  }

  void _scrollToInitialAyah(SurahContentEntity surah) {
    final int? ayahNumber = widget.initialAyah;
    if (ayahNumber == null || !_scrollController.hasClients) {
      return;
    }

    final int index = surah.ayahs.indexWhere(
      (ayah) => ayah.numberInSurah == ayahNumber,
    );
    if (index <= 0) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        index * 220.0,
        duration: Theme.of(context).tokens.durationMedium,
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _switchToMushaf() {
    final VoidCallback? onSwitch = widget.onSwitchToMushaf;
    if (onSwitch != null) {
      onSwitch();
      return;
    }
  }

  Future<void> _shareAyah(AyahEntity ayah) async {
    final StringBuffer buffer = StringBuffer()
      ..writeln(ayah.text)
      ..writeln()
      ..write('${ayah.surahNumber}:${ayah.numberInSurah}');
    if (ayah.translation != null) {
      buffer
        ..writeln()
        ..writeln(ayah.translation);
    }
    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  void _bookmarkAyah(AyahEntity ayah) {
    TilawaFeedback.showToast(
      context,
      message: context.l10n.addBookmark,
      variant: TilawaFeedbackVariant.info,
    );
  }

  Future<void> _playAyah(AyahEntity ayah) async {
    final result = await getIt<PlayAyahAudioUseCase>()(
      ayah: ayah,
      currentAudio: context.read<AudioPlayerBloc>().state.currentAudio,
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) => TilawaFeedback.showToast(
        context,
        message: failure.message ?? context.l10n.error,
        variant: TilawaFeedbackVariant.error,
      ),
      (_) {},
    );
  }

  void _openReaderSettings() {
    unawaited(
      showReaderSettingsSheet(
        context: context,
        settingsCubit: getIt<QuranSettingsCubit>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: TilawaCatalogAppBar(
        preferredHeight: TilawaAppBarConfig.catalogTitleOnlyHeight(context),
        centerTitle: true,
        automaticallyImplyLeading: true,
        titleWidget: Text(
          context.l10n.quranHubTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          TilawaIconActionButton(
            icon: Icons.tune_rounded,
            tooltip: context.l10n.readerSettings,
            onTap: _openReaderSettings,
          ),
          QuranReaderViewToggle(
            currentMode: QuranReaderViewMode.ayahList,
            onPressed: _switchToMushaf,
          ),
        ],
      ),
      body: BlocBuilder<QuranSettingsCubit, ReaderSettingsEntity>(
        builder: (context, settings) {
          return BlocConsumer<QuranSurahCubit, QuranSurahState>(
            listener: (context, state) {
              if (state is QuranSurahLoaded) {
                _scrollToInitialAyah(state.surah);
              }
            },
            builder: (context, state) {
              return switch (state) {
                QuranSurahInitial() || QuranSurahLoading() => Center(
                  child: TilawaLoadingIndicator(color: colorScheme.primary),
                ),
                QuranSurahError(:final message) => TilawaErrorState(
                  icon: Icons.error_outline_rounded,
                  title: context.l10n.error,
                  subtitle: message,
                  retryLabel: context.l10n.tryAgain,
                  onRetry: () => context.read<QuranSurahCubit>().load(
                    widget.surahNumber,
                  ),
                ),
                QuranSurahLoaded(:final surah) => AyahListView(
                  surah: surah,
                  settings: settings,
                  scrollController: _scrollController,
                  onAyahPlay: _playAyah,
                  onAyahBookmark: _bookmarkAyah,
                  onAyahShare: _shareAyah,
                ),
              };
            },
          );
        },
      ),
    );
  }
}
