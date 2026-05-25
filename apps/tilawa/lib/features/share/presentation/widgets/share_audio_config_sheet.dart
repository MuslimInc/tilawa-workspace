import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/share_content.dart';
import '../../domain/entities/share_limits.dart';
import '../../domain/entities/widget_capture_handle.dart';
import '../cubit/share_cubit.dart';
import '../cubit/share_state.dart';
import '../share_progress_messages_l10n.dart';
import '../utils/share_ayah_range_utils.dart';
import '../utils/video_page_specs.dart';
import 'mushaf_page_renderer.dart';
import 'video_content_renderer.dart';

/// Bottom sheet for configuring and generating an audio clip or reel.
class ShareAudioConfigSheet extends StatefulWidget {
  const ShareAudioConfigSheet({
    super.key,
    required this.surahNumber,
    required this.initialFromAyah,
    required this.initialToAyah,
    required this.reciterName,
    required this.reciterServerUrl,
    this.boundaryKey,
  });

  final int surahNumber;
  final int initialFromAyah;
  final int initialToAyah;
  final String reciterName;
  final String reciterServerUrl;
  final GlobalKey? boundaryKey;

  @override
  State<ShareAudioConfigSheet> createState() => _ShareAudioConfigSheetState();
}

class _ShareAudioConfigSheetState extends State<ShareAudioConfigSheet> {
  late int _fromAyah;
  late int _toAyah;
  late int _minAyah;
  late int _maxAyah;
  final List<GlobalKey> _videoContentKeys = <GlobalKey>[];
  final MushafPageRenderer _pageRenderer = MushafPageRenderer.defaultRenderer();

  @override
  void initState() {
    super.initState();
    final pageData = getPageData(
      getPageNumber(widget.surahNumber, widget.initialFromAyah),
    );
    final primarySurahEntries = pageData
        .where((entry) => entry.surah == widget.surahNumber)
        .toList();

    final firstAyah = primarySurahEntries.isNotEmpty
        ? primarySurahEntries.first.start
        : 1;
    final lastAyah = primarySurahEntries.isNotEmpty
        ? primarySurahEntries.last.end
        : getVerseCount(widget.surahNumber);

    _minAyah = firstAyah;
    _maxAyah = lastAyah;
    final ayahRange = normalizeShareAyahRange(
      surahNumber: widget.surahNumber,
      fromAyah: widget.initialFromAyah,
      toAyah: widget.initialToAyah,
    );
    _fromAyah = ayahRange.fromAyah.clamp(_minAyah, _maxAyah);
    _toAyah = ayahRange.toAyah.clamp(_fromAyah, _maxAyah);
    _syncVideoContentKeys();

    context.read<ShareCubit>().configureAudioClip(
      surahNumber: widget.surahNumber,
      fromAyah: _fromAyah,
      toAyah: _toAyah,
      minAyah: firstAyah,
      maxAyah: lastAyah,
      reciterName: widget.reciterName,
      serverUrl: widget.reciterServerUrl,
    );
  }

  String get _surahName => context.l10n.localeName == 'ar'
      ? getSurahNameArabic(widget.surahNumber)
      : getSurahNameEnglish(widget.surahNumber);

  String get _arabicSurahName => getSurahNameArabic(widget.surahNumber);

  String get _englishSurahName => getSurahNameEnglish(widget.surahNumber);

  int get _verseCount => _toAyah - _fromAyah + 1;

  List<VideoPageSpec> get _videoPageSpecs => buildVideoPageSpecs(
    surahNumber: widget.surahNumber,
    fromAyah: _fromAyah,
    toAyah: _toAyah,
  );

  bool get _isValid =>
      _fromAyah >= 1 &&
      _toAyah >= _fromAyah &&
      _toAyah <= _maxAyah &&
      _verseCount <= ShareLimits.maxVersesPerClip;

  void _syncVideoContentKeys() {
    final int requiredCount = _videoPageSpecs.length;

    while (_videoContentKeys.length < requiredCount) {
      _videoContentKeys.add(GlobalKey());
    }

    if (_videoContentKeys.length > requiredCount) {
      _videoContentKeys.removeRange(requiredCount, _videoContentKeys.length);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        final List<VideoPageSpec> videoPageSpecs = _videoPageSpecs;
        final isGenerating = state.status == ShareStatus.generating;
        final isSharing = state.status == ShareStatus.sharing;
        final isReviewing =
            state.status == ShareStatus.reviewing &&
            state.content is ShareVideo;
        final isBusy = isGenerating || isSharing;
        final reciterName = state.reciterName ?? widget.reciterName;

        return Stack(
          children: [
            if (state.status == ShareStatus.generating &&
                state.capturingIndex != null)
              Positioned(
                left: -2400,
                top: 0,
                child: RepaintBoundary(
                  key: _videoContentKeys[state.capturingIndex!],
                  child: VideoContentPage(
                    surahNumber: widget.surahNumber,
                    pageSpec: videoPageSpecs[state.capturingIndex!],
                    pageIndex: state.capturingIndex!,
                    totalPages: videoPageSpecs.length,
                    reciterName: reciterName,
                    isCapturing: true,
                    pageRenderer: _pageRenderer,
                    backgroundColor: context.colorScheme.surface,
                  ),
                ),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  12 + context.keyboardInset,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppShareComposerColors.gold.withValues(
                        alpha: 0.22,
                      ),
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppShareComposerColors.deepGreen,
                        AppShareComposerColors.forestGreen,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 26,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const TilawaSheetHandle(color: Colors.white24),
                              _ConfigHeader(
                                arabicSurahName: _arabicSurahName,
                                englishSurahName: _englishSurahName,
                                reciterName: reciterName,
                                verseCount: _verseCount,
                              ),
                              const SizedBox(height: 18),
                              AnimatedSwitcher(
                                duration: Theme.of(
                                  context,
                                ).tokens.durationFast,
                                child: isReviewing
                                    ? _VideoReviewPreview(
                                        key: const ValueKey('generated_video'),
                                        filePath: state.content!.filePath,
                                        onShare: () => context
                                            .read<ShareCubit>()
                                            .shareContent(),
                                      )
                                    : _LiveVideoPreview(
                                        key: ValueKey(
                                          'live_preview_${widget.surahNumber}_${_fromAyah}_${_toAyah}_$reciterName',
                                        ),
                                        child: VideoContentRenderer(
                                          surahNumber: widget.surahNumber,
                                          fromAyah: _fromAyah,
                                          toAyah: _toAyah,
                                          reciterName: reciterName,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 18),
                              _RangeSelectionCard(
                                fromAyah: _fromAyah,
                                toAyah: _toAyah,
                                minAyah: _minAyah,
                                maxAyah: _maxAyah,
                                verseCount: _verseCount,
                                enabled: !isBusy,
                                onFromChanged: (value) {
                                  setState(() {
                                    _fromAyah = value;
                                    if (_toAyah < _fromAyah) {
                                      _toAyah = _fromAyah;
                                    }
                                    _syncVideoContentKeys();
                                  });
                                  context.read<ShareCubit>().updateVerseRange(
                                    fromAyah: _fromAyah,
                                    toAyah: _toAyah,
                                  );
                                },
                                onToChanged: (value) {
                                  setState(() {
                                    _toAyah = value;
                                    if (_fromAyah > _toAyah) {
                                      _fromAyah = _toAyah;
                                    }
                                    _syncVideoContentKeys();
                                  });
                                  context.read<ShareCubit>().updateVerseRange(
                                    fromAyah: _fromAyah,
                                    toAyah: _toAyah,
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              if (state.status == ShareStatus.error &&
                                  state.errorMessage != null) ...[
                                _FeedbackCard.error(
                                  message: state.errorMessage!,
                                ),
                                const SizedBox(height: 14),
                              ],
                              if (isGenerating) ...[
                                _ProgressCard(
                                  progress: state.progress,
                                  message: state.progressMessage,
                                  onCancel: () {
                                    context
                                        .read<ShareCubit>()
                                        .cancelGeneration();
                                  },
                                ),
                                const SizedBox(height: 14),
                              ] else if (isSharing) ...[
                                _SharingCard(label: context.l10n.sharing),
                                const SizedBox(height: 14),
                              ],
                              TilawaButton(
                                text: context.l10n.generateReel,
                                variant: TilawaButtonVariant.primary,
                                isFullWidth: true,
                                leadingIcon: const Icon(
                                  Icons.movie_creation_outlined,
                                ),
                                onPressed: _isValid && !isBusy
                                    ? () {
                                        context
                                            .read<ShareCubit>()
                                            .generateVideo(
                                              surahName: _surahName,
                                              progressMessages:
                                                  context.shareProgressMessages,
                                              appName: context.l10n.appTitle,
                                              sharedViaLabel:
                                                  context.l10n.sharedViaTilawa,
                                              handles: _videoContentKeys
                                                  .map(
                                                    (k) =>
                                                        WidgetCaptureHandle(k),
                                                  )
                                                  .toList(),
                                            );
                                      }
                                    : null,
                                backgroundColor: AppShareComposerColors.gold,
                                foregroundColor:
                                    AppShareComposerColors.deepGreen,
                                borderRadius: 18,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 10),
                              TilawaButton(
                                text: context.l10n.shareAudio,
                                variant: TilawaButtonVariant.outline,
                                isFullWidth: true,
                                leadingIcon: const Icon(
                                  Icons.graphic_eq_rounded,
                                ),
                                onPressed: _isValid && !isBusy
                                    ? () {
                                        context
                                            .read<ShareCubit>()
                                            .generateAndShareAudioClip(
                                              surahName: _surahName,
                                              progressMessages:
                                                  context.shareProgressMessages,
                                            );
                                      }
                                    : null,
                                foregroundColor: Colors.white,
                                borderColor: Colors.white.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: 18,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ConfigHeader extends StatelessWidget {
  const _ConfigHeader({
    required this.arabicSurahName,
    required this.englishSurahName,
    required this.reciterName,
    required this.verseCount,
  });

  final String arabicSurahName;
  final String englishSurahName;
  final String reciterName;
  final int verseCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        color: Colors.white.withValues(alpha: 0.07),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: AppShareComposerColors.gold.withValues(alpha: 0.14),
                  border: Border.all(
                    color: AppShareComposerColors.gold.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      size: 16,
                      color: AppShareComposerColors.gold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.appTitle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppShareComposerColors.cream,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _MetadataPill(
                icon: Icons.multitrack_audio_rounded,
                label: '$verseCount ${context.l10n.verses}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            arabicSurahName,
            style: GoogleFonts.amiri(
              fontSize: 30,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            englishSurahName,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.audioClipConfigSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetadataPill(icon: Icons.person_rounded, label: reciterName),
              _MetadataPill(
                icon: Icons.done_all_rounded,
                label: context.l10n.shareVerseLimit(
                  ShareLimits.maxVersesPerClip,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeSelectionCard extends StatelessWidget {
  const _RangeSelectionCard({
    required this.fromAyah,
    required this.toAyah,
    required this.minAyah,
    required this.maxAyah,
    required this.verseCount,
    required this.enabled,
    required this.onFromChanged,
    required this.onToChanged,
  });

  final int fromAyah;
  final int toAyah;
  final int minAyah;
  final int maxAyah;
  final int verseCount;
  final bool enabled;
  final ValueChanged<int> onFromChanged;
  final ValueChanged<int> onToChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exceedsLimit = verseCount > ShareLimits.maxVersesPerClip;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.verses,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$fromAyah - $toAyah',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _VerseDropdown(
                  label: context.l10n.fromAyah,
                  value: fromAyah,
                  min: minAyah,
                  max: toAyah,
                  enabled: enabled,
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
                  enabled: enabled,
                  onChanged: onToChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SelectionBadge(
                icon: Icons.multitrack_audio_rounded,
                label: '$verseCount ${context.l10n.verses}',
              ),
              _SelectionBadge(
                icon: exceedsLimit ? Icons.warning_amber_rounded : Icons.check,
                label: exceedsLimit
                    ? context.l10n.maxVersesExceeded(
                        ShareLimits.maxVersesPerClip,
                      )
                    : context.l10n.shareVerseLimit(
                        ShareLimits.maxVersesPerClip,
                      ),
                isError: exceedsLimit,
              ),
            ],
          ),
        ],
      ),
    );
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
    final clampedValue = value.clamp(min, max);

    return DropdownButtonFormField<int>(
      initialValue: clampedValue,
      onChanged: enabled ? (value) => onChanged(value!) : null,
      iconEnabledColor: AppShareComposerColors.deepGreen,
      dropdownColor: AppShareComposerColors.cream,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppShareComposerColors.cream,
        labelStyle: const TextStyle(
          color: AppShareComposerColors.deepGreen,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppShareComposerColors.deepGreen.withValues(alpha: 0.08),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppShareComposerColors.deepGreen.withValues(alpha: 0.04),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppShareComposerColors.gold),
        ),
      ),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppShareComposerColors.deepGreen,
        fontWeight: FontWeight.w700,
      ),
      items: List.generate(max - min + 1, (index) {
        final current = min + index;
        return DropdownMenuItem<int>(value: current, child: Text('$current'));
      }),
    );
  }
}

class _LiveVideoPreview extends StatelessWidget {
  const _LiveVideoPreview({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.liveReelPreview,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.play_circle_outline_rounded,
                color: AppShareComposerColors.gold,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.16),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: VideoContentRenderer.videoWidth,
                    height: VideoContentRenderer.videoHeight,
                    child: IgnorePointer(child: child),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.message,
    required this.onCancel,
  });

  final double progress;
  final String message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedProgress = progress == 0 ? null : progress;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: normalizedProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppShareComposerColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TilawaButton(
              text: context.l10n.cancel,
              variant: TilawaButtonVariant.ghost,
              size: TilawaButtonSize.small,
              shrinkWrapTapTarget: true,
              leadingIcon: const Icon(Icons.close_rounded),
              onPressed: onCancel,
              foregroundColor: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}

class _SharingCard extends StatelessWidget {
  const _SharingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: TilawaLoadingIndicator(
              centered: false,
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppShareComposerColors.gold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard.error({required this.message})
    : backgroundColor = AppShareComposerColors.feedbackErrorBackground,
      outlineColor = AppShareComposerColors.feedbackErrorOutline,
      icon = Icons.error_outline_rounded;

  final String message;
  final Color backgroundColor;
  final Color outlineColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: backgroundColor,
        border: Border.all(color: outlineColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: outlineColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataPill extends StatelessWidget {
  const _MetadataPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppShareComposerColors.gold),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({
    required this.icon,
    required this.label,
    this.isError = false,
  });

  final IconData icon;
  final String label;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = isError
        ? AppShareComposerColors.feedbackErrorBackground
        : Colors.black.withValues(alpha: 0.16);
    final accent = isError
        ? AppShareComposerColors.feedbackErrorOutline
        : AppShareComposerColors.mint;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: backgroundColor,
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.84),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoReviewPreview extends StatelessWidget {
  const _VideoReviewPreview({
    super.key,
    required this.filePath,
    required this.onShare,
  });

  final String filePath;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool exists = File(filePath).existsSync();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.reviewReel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: ColoredBox(
                color: Colors.black12,
                child: Center(
                  child: Icon(
                    exists
                        ? Icons.movie_creation_outlined
                        : Icons.error_outline,
                    size: 40,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TilawaButton(
              text: context.l10n.shareReel,
              variant: TilawaButtonVariant.primary,
              isFullWidth: true,
              leadingIcon: const Icon(Icons.share_rounded),
              onPressed: onShare,
              backgroundColor: AppShareComposerColors.mint,
              foregroundColor: AppShareComposerColors.deepGreen,
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
            ),
          ),
        ],
      ),
    );
  }
}
