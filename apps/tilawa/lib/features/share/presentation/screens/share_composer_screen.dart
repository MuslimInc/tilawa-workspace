import 'dart:io';
import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:quran/quran.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:video_player/video_player.dart';

import 'package:tilawa/core/extensions.dart';

import '../../domain/entities/share_content.dart';
import '../../domain/entities/share_limits.dart';
import '../share_progress_messages_l10n.dart';
import '../utils/share_ayah_range_utils.dart';
import '../cubit/share_cubit.dart';
import '../cubit/share_state.dart';
import '../widgets/reel_content_renderer.dart';
import '../widgets/share_poster_renderer.dart';

enum ShareComposerMode { screenshot, audio, reel }

enum ShareScreenshotLayout { readerPage, passageCard }

enum ShareDurationPreset { auto, short, medium, long }

extension on ShareDurationPreset {
  int? get maxDurationSeconds => switch (this) {
    ShareDurationPreset.auto => null,
    ShareDurationPreset.short => 30,
    ShareDurationPreset.medium => 60,
    ShareDurationPreset.long => 90,
  };
}

class ShareComposerScreen extends StatefulWidget {
  const ShareComposerScreen({
    super.key,
    required this.surahNumber,
    required this.currentPage,
    required this.initialFromAyah,
    required this.initialToAyah,
    required this.reciterName,
    required this.reciterServerUrl,
    required this.readerBoundaryKey,
    this.readerPreviewBytes,
  });

  final int surahNumber;
  final int currentPage;
  final int initialFromAyah;
  final int initialToAyah;
  final String reciterName;
  final String reciterServerUrl;
  final GlobalKey readerBoundaryKey;
  final Uint8List? readerPreviewBytes;

  static Route<void> route({
    required ShareCubit cubit,
    required int surahNumber,
    required int currentPage,
    required int initialFromAyah,
    required int initialToAyah,
    required String reciterName,
    required String reciterServerUrl,
    required GlobalKey readerBoundaryKey,
    Uint8List? readerPreviewBytes,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) =>
          BlocProvider.value(
            value: cubit,
            child: ShareComposerScreen(
              surahNumber: surahNumber,
              currentPage: currentPage,
              initialFromAyah: initialFromAyah,
              initialToAyah: initialToAyah,
              reciterName: reciterName,
              reciterServerUrl: reciterServerUrl,
              readerBoundaryKey: readerBoundaryKey,
              readerPreviewBytes: readerPreviewBytes,
            ),
          ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ShareComposerScreen> createState() => _ShareComposerScreenState();
}

class _ShareComposerScreenState extends State<ShareComposerScreen> {
  late int _fromAyah;
  late int _toAyah;
  late final int _maxAyah;
  ShareComposerMode _mode = ShareComposerMode.screenshot;
  ShareScreenshotLayout _screenshotLayout = ShareScreenshotLayout.readerPage;
  ShareDurationPreset _durationPreset = ShareDurationPreset.auto;
  final GlobalKey _posterBoundaryKey = GlobalKey();
  final GlobalKey _reelBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _maxAyah = getVerseCount(widget.surahNumber);
    final ayahRange = normalizeShareAyahRange(
      surahNumber: widget.surahNumber,
      fromAyah: widget.initialFromAyah,
      toAyah: widget.initialToAyah,
    );
    _fromAyah = ayahRange.fromAyah;
    _toAyah = ayahRange.toAyah;

    context.read<ShareCubit>().configureAudioClip(
      surahNumber: widget.surahNumber,
      fromAyah: _fromAyah,
      toAyah: _toAyah,
      reciterName: widget.reciterName,
      serverUrl: widget.reciterServerUrl,
      boundaryKey: widget.readerBoundaryKey,
    );
  }

  String get _surahName => context.l10n.localeName == 'ar'
      ? getSurahNameArabic(widget.surahNumber)
      : getSurahNameEnglish(widget.surahNumber);

  String get _arabicSurahName => getSurahNameArabic(widget.surahNumber);

  int get _verseCount => _toAyah - _fromAyah + 1;

  bool get _hasLogicalRange =>
      _fromAyah >= 1 && _toAyah >= _fromAyah && _toAyah <= _maxAyah;

  bool get _enforcesVerseLimit => _mode != ShareComposerMode.screenshot;

  bool get _isValidRange =>
      _hasLogicalRange &&
      (!_enforcesVerseLimit || _verseCount <= ShareLimits.maxVersesPerClip);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return BlocConsumer<ShareCubit, ShareState>(
      listenWhen: (previous, current) =>
          previous.status == ShareStatus.sharing &&
          current.status == ShareStatus.idle &&
          current.content == null,
      listener: (context, state) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final isBusy =
            state.status == ShareStatus.capturing ||
            state.status == ShareStatus.generating ||
            state.status == ShareStatus.sharing;
        final isReviewing =
            state.status == ShareStatus.reviewing && state.content != null;

        return Stack(
          children: [
            Positioned(
              left: -3000,
              top: -3000,
              child: RepaintBoundary(
                key: _posterBoundaryKey,
                child: SharePosterRenderer(
                  surahNumber: widget.surahNumber,
                  fromAyah: _fromAyah,
                  toAyah: _toAyah,
                  reciterName: state.reciterName ?? widget.reciterName,
                ),
              ),
            ),
            Positioned(
              left: -3000,
              top: -3000,
              child: RepaintBoundary(
                key: _reelBoundaryKey,
                child: ReelContentRenderer(
                  surahNumber: widget.surahNumber,
                  fromAyah: _fromAyah,
                  toAyah: _toAyah,
                  reciterName: state.reciterName ?? widget.reciterName,
                ),
              ),
            ),
            ImmersiveComposerScaffold(
              title: isReviewing
                  ? context.l10n.shareReadyTitle
                  : context.l10n.createShare,
              subtitle: isReviewing
                  ? context.l10n.shareReviewSubtitle
                  : context.l10n.shareComposerSubtitle,
              onClose: () => Navigator.of(context).maybePop(),
              background: _buildBackdrop(),
              backgroundGradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0C302B),
                  Color(0xFF164B42),
                  Color(0xFF1E5D52),
                ],
              ),
              preview: AnimatedSwitcher(
                duration: tokens.durationMedium,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: isReviewing
                    ? _buildReviewPreview(state.content!)
                    : _buildLivePreview(state),
              ),
              bottomPanel: AnimatedSwitcher(
                duration: tokens.durationFast,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: isReviewing
                    ? _ReviewPanel(
                        key: const ValueKey('review_panel'),
                        content: state.content!,
                        onEdit: () =>
                            context.read<ShareCubit>().discardPreparedContent(),
                        onShare: () =>
                            context.read<ShareCubit>().shareContent(),
                      )
                    : _ComposerControls(
                        key: const ValueKey('composer_controls'),
                        mode: _mode,
                        screenshotLayout: _screenshotLayout,
                        durationPreset: _durationPreset,
                        fromAyah: _fromAyah,
                        toAyah: _toAyah,
                        maxAyah: _maxAyah,
                        verseCount: _verseCount,
                        isBusy: isBusy,
                        rangeIsValid: _isValidRange,
                        showVerseLimit: _enforcesVerseLimit,
                        reciterName: state.reciterName ?? widget.reciterName,
                        arabicSurahName: _arabicSurahName,
                        currentPage: widget.currentPage,
                        errorMessage: state.status == ShareStatus.error
                            ? state.errorMessage
                            : null,
                        progressLabel: _progressLabelForState(context, state),
                        onModeChanged: (mode) {
                          setState(() => _mode = mode);
                          context.read<ShareCubit>().discardPreparedContent();
                        },
                        onLayoutChanged: (layout) {
                          setState(() => _screenshotLayout = layout);
                          context.read<ShareCubit>().discardPreparedContent();
                        },
                        onDurationChanged: (preset) {
                          setState(() => _durationPreset = preset);
                          context.read<ShareCubit>().discardPreparedContent();
                        },
                        onFromChanged: _handleFromAyahChanged,
                        onToChanged: _handleToAyahChanged,
                        onPrimaryAction: _handlePrimaryAction,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget? _buildBackdrop() {
    final bytes = widget.readerPreviewBytes;
    if (bytes == null) return null;

    return Opacity(
      opacity: 0.16,
      child: Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildLivePreview(ShareState state) {
    final reciterName = state.reciterName ?? widget.reciterName;

    return Column(
      key: ValueKey(
        'live_${_mode.name}_${_screenshotLayout.name}_${_durationPreset.name}',
      ),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            MetadataChip(
              icon: Icons.auto_stories_rounded,
              label: _arabicSurahName,
              foregroundColor: const Color(0xFFF7F1E1),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              borderColor: Colors.white.withValues(alpha: 0.12),
            ),
            MetadataChip(
              icon: Icons.format_list_numbered_rounded,
              label:
                  _mode == ShareComposerMode.screenshot &&
                      _screenshotLayout == ShareScreenshotLayout.readerPage
                  ? '${context.l10n.page} ${widget.currentPage}'
                  : _rangeLabel(_fromAyah, _toAyah),
              foregroundColor: const Color(0xFFF7F1E1),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              borderColor: Colors.white.withValues(alpha: 0.12),
            ),
            if (_mode != ShareComposerMode.screenshot)
              MetadataChip(
                icon: Icons.multitrack_audio_rounded,
                label: reciterName,
                foregroundColor: const Color(0xFFF7F1E1),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                borderColor: Colors.white.withValues(alpha: 0.12),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Center(
            child: _PreviewFrame(
              aspectRatio: _previewAspectRatio,
              child: switch (_mode) {
                ShareComposerMode.screenshot =>
                  _screenshotLayout == ShareScreenshotLayout.readerPage
                      ? _ReaderPagePreview(
                          bytes: widget.readerPreviewBytes,
                          pageNumber: widget.currentPage,
                          surahName: _surahName,
                        )
                      : SharePosterRenderer(
                          surahNumber: widget.surahNumber,
                          fromAyah: _fromAyah,
                          toAyah: _toAyah,
                          reciterName: reciterName,
                        ),
                ShareComposerMode.audio => _AudioArtworkPreview(
                  surahNumber: widget.surahNumber,
                  fromAyah: _fromAyah,
                  toAyah: _toAyah,
                  reciterName: reciterName,
                  durationPreset: _durationPreset,
                ),
                ShareComposerMode.reel => ReelContentRenderer(
                  surahNumber: widget.surahNumber,
                  fromAyah: _fromAyah,
                  toAyah: _toAyah,
                  reciterName: reciterName,
                ),
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewPreview(ShareContent content) {
    final reviewKey = switch (content) {
      ShareScreenshot(:final filePath) => ValueKey('review_image_$filePath'),
      ShareAudioClip(:final filePath) => ValueKey('review_audio_$filePath'),
      ShareReel(:final filePath) => ValueKey('review_reel_$filePath'),
    };

    return Column(
      key: reviewKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            MetadataChip(
              icon: Icons.check_circle_rounded,
              label: context.l10n.readyToShare,
              foregroundColor: const Color(0xFFF7F1E1),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              borderColor: Colors.white.withValues(alpha: 0.12),
            ),
            MetadataChip(
              icon: Icons.auto_stories_rounded,
              label: content.surahName,
              foregroundColor: const Color(0xFFF7F1E1),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              borderColor: Colors.white.withValues(alpha: 0.12),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Center(
            child: switch (content) {
              ShareScreenshot(:final filePath) => _PreviewFrame(
                aspectRatio: 4 / 5,
                child: _GeneratedImagePreview(filePath: filePath),
              ),
              ShareAudioClip(
                :final filePath,
                :final fromAyah,
                :final toAyah,
                :final reciterName,
              ) =>
                _MediaPreviewFrame(
                  aspectRatio: 4 / 5,
                  child: _GeneratedAudioPreview(
                    key: ValueKey('generated_audio_$filePath'),
                    filePath: filePath,
                    surahNumber: widget.surahNumber,
                    fromAyah: fromAyah,
                    toAyah: toAyah,
                    reciterName: reciterName,
                  ),
                ),
              ShareReel(:final filePath) => _MediaPreviewFrame(
                aspectRatio: 9 / 16,
                child: _GeneratedReelPreview(
                  key: ValueKey('generated_reel_$filePath'),
                  filePath: filePath,
                ),
              ),
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handlePrimaryAction() async {
    final cubit = context.read<ShareCubit>();

    switch (_mode) {
      case ShareComposerMode.screenshot:
        final useReaderCapture =
            _screenshotLayout == ShareScreenshotLayout.readerPage;
        await cubit.prepareScreenshot(
          boundaryKey: useReaderCapture
              ? widget.readerBoundaryKey
              : _posterBoundaryKey,
          surahName: _surahName,
          pageNumber: widget.currentPage,
          appName: context.l10n.appTitle,
          sharedViaLabel: context.l10n.sharedViaTilawa,
          preparingImageLabel: context.shareProgressMessages.preparingImage,
          brandCapture: useReaderCapture,
        );
        return;
      case ShareComposerMode.audio:
        await cubit.prepareAudioClip(
          surahName: _surahName,
          progressMessages: context.shareProgressMessages,
          maxDurationSeconds: _durationPreset.maxDurationSeconds,
        );
        return;
      case ShareComposerMode.reel:
        await cubit.generateReel(
          surahName: _surahName,
          progressMessages: context.shareProgressMessages,
          appName: context.l10n.appTitle,
          sharedViaLabel: context.l10n.sharedViaTilawa,
          boundaryKey: _reelBoundaryKey,
          maxDurationSeconds: _durationPreset.maxDurationSeconds,
        );
        return;
    }
  }

  void _handleFromAyahChanged(int value) {
    setState(() {
      _fromAyah = value;
      if (_toAyah < _fromAyah) {
        _toAyah = _fromAyah;
      }
    });
    context.read<ShareCubit>().updateVerseRange(
      fromAyah: _fromAyah,
      toAyah: _toAyah,
    );
  }

  void _handleToAyahChanged(int value) {
    setState(() {
      _toAyah = value;
      if (_fromAyah > _toAyah) {
        _fromAyah = _toAyah;
      }
    });
    context.read<ShareCubit>().updateVerseRange(
      fromAyah: _fromAyah,
      toAyah: _toAyah,
    );
  }

  String? _progressLabelForState(BuildContext context, ShareState state) {
    return switch (state.status) {
      ShareStatus.capturing => context.l10n.preparingScreenshot,
      ShareStatus.generating => state.progressMessage,
      ShareStatus.sharing => context.l10n.sharing,
      _ => null,
    };
  }

  double get _previewAspectRatio => switch (_mode) {
    ShareComposerMode.reel => 9 / 16,
    ShareComposerMode.screenshot =>
      _screenshotLayout == ShareScreenshotLayout.readerPage ? 3 / 4 : 4 / 5,
    ShareComposerMode.audio => 4 / 5,
  };

  String _rangeLabel(int fromAyah, int toAyah) {
    return fromAyah == toAyah
        ? '${context.l10n.ayah} $fromAyah'
        : '${context.l10n.ayahs} $fromAyah - $toAyah';
  }
}

class _ComposerControls extends StatelessWidget {
  const _ComposerControls({
    super.key,
    required this.mode,
    required this.screenshotLayout,
    required this.durationPreset,
    required this.fromAyah,
    required this.toAyah,
    required this.maxAyah,
    required this.verseCount,
    required this.isBusy,
    required this.rangeIsValid,
    required this.showVerseLimit,
    required this.reciterName,
    required this.arabicSurahName,
    required this.currentPage,
    required this.errorMessage,
    required this.progressLabel,
    required this.onModeChanged,
    required this.onLayoutChanged,
    required this.onDurationChanged,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onPrimaryAction,
  });

  final ShareComposerMode mode;
  final ShareScreenshotLayout screenshotLayout;
  final ShareDurationPreset durationPreset;
  final int fromAyah;
  final int toAyah;
  final int maxAyah;
  final int verseCount;
  final bool isBusy;
  final bool rangeIsValid;
  final bool showVerseLimit;
  final String reciterName;
  final String arabicSurahName;
  final int currentPage;
  final String? errorMessage;
  final String? progressLabel;
  final ValueChanged<ShareComposerMode> onModeChanged;
  final ValueChanged<ShareScreenshotLayout> onLayoutChanged;
  final ValueChanged<ShareDurationPreset> onDurationChanged;
  final ValueChanged<int> onFromChanged;
  final ValueChanged<int> onToChanged;
  final Future<void> Function() onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TilawaSectionTitle(title: context.l10n.shareMode),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SelectionPill(
              label: context.l10n.shareModeScreenshot,
              icon: Icons.image_rounded,
              selected: mode == ShareComposerMode.screenshot,
              onTap: () => onModeChanged(ShareComposerMode.screenshot),
              selectedColor: const Color(0xFFE1C17B),
              selectedForegroundColor: const Color(0xFF0B342E),
            ),
            SelectionPill(
              label: context.l10n.shareModeAudio,
              icon: Icons.graphic_eq_rounded,
              selected: mode == ShareComposerMode.audio,
              onTap: () => onModeChanged(ShareComposerMode.audio),
              selectedColor: const Color(0xFFE1C17B),
              selectedForegroundColor: const Color(0xFF0B342E),
            ),
            SelectionPill(
              label: context.l10n.shareModeReel,
              icon: Icons.movie_creation_outlined,
              selected: mode == ShareComposerMode.reel,
              onTap: () => onModeChanged(ShareComposerMode.reel),
              selectedColor: const Color(0xFFE1C17B),
              selectedForegroundColor: const Color(0xFF0B342E),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            MetadataChip(
              icon: Icons.auto_stories_rounded,
              label: arabicSurahName,
            ),
            MetadataChip(
              icon: Icons.menu_book_rounded,
              label: '${context.l10n.page} $currentPage',
            ),
            if (mode != ShareComposerMode.screenshot)
              MetadataChip(
                icon: Icons.multitrack_audio_rounded,
                label: reciterName,
              ),
          ],
        ),
        if (mode == ShareComposerMode.screenshot) ...[
          const SizedBox(height: 16),
          TilawaSectionTitle(title: context.l10n.shareContentLayout),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SelectionPill(
                label: context.l10n.shareLayoutReaderPage,
                icon: Icons.menu_book_rounded,
                selected: screenshotLayout == ShareScreenshotLayout.readerPage,
                onTap: () => onLayoutChanged(ShareScreenshotLayout.readerPage),
                selectedColor: const Color(0xFF1D675A),
              ),
              SelectionPill(
                label: context.l10n.shareLayoutPassageCard,
                icon: Icons.style_rounded,
                selected: screenshotLayout == ShareScreenshotLayout.passageCard,
                onTap: () => onLayoutChanged(ShareScreenshotLayout.passageCard),
                selectedColor: const Color(0xFF1D675A),
              ),
            ],
          ),
        ],
        if (mode != ShareComposerMode.screenshot ||
            screenshotLayout == ShareScreenshotLayout.passageCard) ...[
          const SizedBox(height: 16),
          TilawaSectionTitle(title: context.l10n.verses),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _VerseDropdown(
                  label: context.l10n.fromAyah,
                  value: fromAyah,
                  min: 1,
                  max: toAyah,
                  enabled: !isBusy,
                  onChanged: onFromChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VerseDropdown(
                  label: context.l10n.toAyah,
                  value: toAyah,
                  min: fromAyah,
                  max: maxAyah,
                  enabled: !isBusy,
                  onChanged: onToChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (showVerseLimit)
            Text(
              rangeIsValid
                  ? context.l10n.shareVerseLimit(ShareLimits.maxVersesPerClip)
                  : context.l10n.maxVersesExceeded(
                      ShareLimits.maxVersesPerClip,
                    ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: rangeIsValid
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.error,
              ),
            ),
        ] else ...[
          const SizedBox(height: 16),
          Text(
            context.l10n.shareReaderPageHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
        if (mode != ShareComposerMode.screenshot) ...[
          const SizedBox(height: 16),
          TilawaSectionTitle(title: context.l10n.shareDuration),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SelectionPill(
                label: context.l10n.shareDurationAuto,
                selected: durationPreset == ShareDurationPreset.auto,
                onTap: () => onDurationChanged(ShareDurationPreset.auto),
                selectedColor: const Color(0xFF1D675A),
              ),
              SelectionPill(
                label: context.l10n.shareDurationShort,
                selected: durationPreset == ShareDurationPreset.short,
                onTap: () => onDurationChanged(ShareDurationPreset.short),
                selectedColor: const Color(0xFF1D675A),
              ),
              SelectionPill(
                label: context.l10n.shareDurationMedium,
                selected: durationPreset == ShareDurationPreset.medium,
                onTap: () => onDurationChanged(ShareDurationPreset.medium),
                selectedColor: const Color(0xFF1D675A),
              ),
              SelectionPill(
                label: context.l10n.shareDurationLong,
                selected: durationPreset == ShareDurationPreset.long,
                onTap: () => onDurationChanged(ShareDurationPreset.long),
                selectedColor: const Color(0xFF1D675A),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.shareDurationHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          TilawaFeedbackStrip(
            icon: Icons.error_outline_rounded,
            message: errorMessage!,
            backgroundColor: const Color(0xFFFFECE9),
            foregroundColor: const Color(0xFF8A241C),
          ),
        ],
        if (progressLabel != null) ...[
          const SizedBox(height: 16),
          TilawaFeedbackStrip(
            icon: Icons.hourglass_top_rounded,
            message: progressLabel!,
            backgroundColor: const Color(0xFFF5EFE1),
            foregroundColor: const Color(0xFF6E5A2D),
            showSpinner: isBusy,
          ),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: isBusy || !rangeIsValid ? null : () => onPrimaryAction(),
          icon: Icon(switch (mode) {
            ShareComposerMode.screenshot => Icons.image_rounded,
            ShareComposerMode.audio => Icons.graphic_eq_rounded,
            ShareComposerMode.reel => Icons.movie_creation_outlined,
          }),
          label: Text(switch (mode) {
            ShareComposerMode.screenshot => context.l10n.prepareScreenshot,
            ShareComposerMode.audio => context.l10n.prepareAudioClip,
            ShareComposerMode.reel => context.l10n.prepareReel,
          }),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE1C17B),
            foregroundColor: const Color(0xFF0B342E),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    super.key,
    required this.content,
    required this.onEdit,
    required this.onShare,
  });

  final ShareContent content;
  final VoidCallback onEdit;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.shareReviewTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          switch (content) {
            ShareScreenshot() => context.l10n.shareReviewScreenshot,
            ShareAudioClip() => context.l10n.shareReviewAudio,
            ShareReel() => context.l10n.shareReviewReel,
          },
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onEdit,
                child: Text(context.l10n.edit),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded),
                label: Text(switch (content) {
                  ShareScreenshot() => context.l10n.shareScreenshot,
                  ShareAudioClip() => context.l10n.shareAudio,
                  ShareReel() => context.l10n.shareReel,
                }),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.aspectRatio, required this.child});

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 760),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 1080,
                height: aspectRatio < 0.6
                    ? 1920
                    : aspectRatio >= 0.8
                    ? 1350
                    : 1440,
                child: IgnorePointer(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaPreviewFrame extends StatelessWidget {
  const _MediaPreviewFrame({required this.aspectRatio, required this.child});

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 760),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: AspectRatio(aspectRatio: aspectRatio, child: child),
        ),
      ),
    );
  }
}

class _ReaderPagePreview extends StatelessWidget {
  const _ReaderPagePreview({
    required this.bytes,
    required this.pageNumber,
    required this.surahName,
  });

  final Uint8List? bytes;
  final int pageNumber;
  final String surahName;

  @override
  Widget build(BuildContext context) {
    if (bytes == null) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F1E1), Color(0xFFEADCB9)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 48,
                  color: Color(0xFF0B342E),
                ),
                const SizedBox(height: 14),
                Text(
                  surahName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B342E),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${context.l10n.page} $pageNumber',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF355B54),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Image.memory(bytes!, fit: BoxFit.cover);
  }
}

class _AudioArtworkPreview extends StatelessWidget {
  const _AudioArtworkPreview({
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
    required this.reciterName,
    required this.durationPreset,
  });

  final int surahNumber;
  final int fromAyah;
  final int toAyah;
  final String reciterName;
  final ShareDurationPreset durationPreset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SharePosterRenderer(
          surahNumber: surahNumber,
          fromAyah: fromAyah,
          toAyah: toAyah,
          reciterName: reciterName,
        ),
        Positioned(
          left: 36,
          right: 36,
          bottom: 34,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF0B342E).withValues(alpha: 0.82),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE1C17B).withValues(alpha: 0.18),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Color(0xFFE1C17B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    durationPreset.maxDurationSeconds == null
                        ? context.l10n.shareDurationAuto
                        : context.l10n.shareDurationPresetLabel(
                            durationPreset.maxDurationSeconds!,
                          ),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GeneratedImagePreview extends StatelessWidget {
  const _GeneratedImagePreview({required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(filePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _GeneratedAudioPreview extends StatefulWidget {
  const _GeneratedAudioPreview({
    super.key,
    required this.filePath,
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
    required this.reciterName,
  });

  final String filePath;
  final int surahNumber;
  final int fromAyah;
  final int toAyah;
  final String reciterName;

  @override
  State<_GeneratedAudioPreview> createState() => _GeneratedAudioPreviewState();
}

class _GeneratedAudioPreviewState extends State<_GeneratedAudioPreview> {
  late final ja.AudioPlayer _audioPlayer;
  String? _errorMessage;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = ja.AudioPlayer();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant _GeneratedAudioPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      if (!File(widget.filePath).existsSync()) {
        throw StateError(context.l10n.generatedAudioFileNotFound);
      }
      await _audioPlayer.stop();
      await _audioPlayer.setFilePath(widget.filePath);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isInitializing = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isInitializing = false;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final playerState = _audioPlayer.playerState;
    if (playerState.processingState == ja.ProcessingState.completed) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      return;
    }

    if (playerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 1080,
              height: 1350,
              child: SharePosterRenderer(
                surahNumber: widget.surahNumber,
                fromAyah: widget.fromAyah,
                toAyah: widget.toAyah,
                reciterName: widget.reciterName,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.04),
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.58),
                ],
              ),
            ),
          ),
        ),
        if (_isInitializing)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          ColoredBox(
            color: Colors.black.withValues(alpha: 0.42),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        else
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: const Color(0xFF0B342E).withValues(alpha: 0.92),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: StreamBuilder<ja.PlayerState>(
                stream: _audioPlayer.playerStateStream,
                initialData: _audioPlayer.playerState,
                builder: (context, playerSnapshot) {
                  final playerState =
                      playerSnapshot.data ?? _audioPlayer.playerState;
                  final isPlaying = playerState.playing;
                  final isCompleted =
                      playerState.processingState ==
                      ja.ProcessingState.completed;

                  return StreamBuilder<Duration?>(
                    stream: _audioPlayer.durationStream,
                    initialData: _audioPlayer.duration,
                    builder: (context, durationSnapshot) {
                      final duration = durationSnapshot.data ?? Duration.zero;

                      return StreamBuilder<Duration>(
                        stream: _audioPlayer.positionStream,
                        initialData: _audioPlayer.position,
                        builder: (context, positionSnapshot) {
                          final position =
                              positionSnapshot.data ?? Duration.zero;

                          return StreamBuilder<Duration>(
                            stream: _audioPlayer.bufferedPositionStream,
                            initialData: _audioPlayer.bufferedPosition,
                            builder: (context, bufferedSnapshot) {
                              final bufferedPosition =
                                  bufferedSnapshot.data ?? Duration.zero;

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(
                                            0xFFE1C17B,
                                          ).withValues(alpha: 0.18),
                                        ),
                                        child: IconButton(
                                          onPressed: _togglePlayback,
                                          icon: Icon(
                                            isCompleted
                                                ? Icons.replay_rounded
                                                : isPlaying
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                            color: const Color(0xFFE1C17B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              context.l10n.shareReviewAudio,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_formatPreviewDuration(position)} / ${_formatPreviewDuration(duration)}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.74,
                                                        ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SeekBar(
                                    duration: duration,
                                    position: position,
                                    bufferedPosition: bufferedPosition,
                                    onChangeEnd: _audioPlayer.seek,
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

String _formatPreviewDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _GeneratedReelPreview extends StatefulWidget {
  const _GeneratedReelPreview({super.key, required this.filePath});

  final String filePath;

  @override
  State<_GeneratedReelPreview> createState() => _GeneratedReelPreviewState();
}

class _GeneratedReelPreviewState extends State<_GeneratedReelPreview> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant _GeneratedReelPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    await _disposeControllers();

    if (!File(widget.filePath).existsSync()) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.generatedReelFileNotFound;
      });
      return;
    }

    final controller = VideoPlayerController.file(File(widget.filePath));

    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(1);
    } catch (error) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
      return;
    }

    _videoPlayerController = controller;
    _chewieController = ChewieController(
      videoPlayerController: controller,
      aspectRatio:
          controller.value.isInitialized && controller.value.aspectRatio > 0
          ? controller.value.aspectRatio
          : 9 / 16,
      autoPlay: true,
      looping: false,
      showControls: true,
      allowMuting: true,
      placeholder: const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, errorMessage) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _disposeControllers() async {
    final chewieController = _chewieController;
    final videoPlayerController = _videoPlayerController;

    _chewieController = null;
    _videoPlayerController = null;

    await chewieController?.pause();
    chewieController?.dispose();
    await videoPlayerController?.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return ColoredBox(
        color: Colors.black12,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    if (_chewieController == null) {
      return const ColoredBox(
        color: Colors.black12,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}

class _VerseDropdown extends StatelessWidget {
  const _VerseDropdown({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final initialValue = value.clamp(min, max);

    return DropdownButtonFormField<int>(
      initialValue: initialValue,
      onChanged: enabled ? (value) => onChanged(value!) : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
      items: List.generate(max - min + 1, (index) {
        final current = min + index;
        return DropdownMenuItem<int>(value: current, child: Text('$current'));
      }),
    );
  }
}
