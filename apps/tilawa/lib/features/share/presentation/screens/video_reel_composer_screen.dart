import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/share/domain/entities/share_content.dart';
import 'package:tilawa/features/share/domain/entities/share_limits.dart';
import 'package:tilawa/features/share/domain/entities/widget_capture_handle.dart';
import 'package:tilawa/features/share/presentation/cubit/share_cubit.dart';
import 'package:tilawa/features/share/presentation/cubit/share_state.dart';
import 'package:tilawa/features/share/presentation/share_progress_messages_l10n.dart';
import 'package:tilawa/features/share/presentation/utils/share_reciter_options.dart';
import 'package:tilawa/features/share/presentation/utils/share_feature_flags.dart';
import 'package:tilawa/features/share/presentation/utils/video_page_specs.dart';
import 'package:tilawa/features/share/presentation/utils/video_reel_composer_presets.dart';
import 'package:tilawa/features/share/presentation/widgets/composer_controls.dart';
import 'package:tilawa/features/share/presentation/widgets/mushaf_page_renderer.dart';
import 'package:tilawa/features/share/presentation/widgets/reciter_picker_sheet.dart';
import 'package:tilawa/features/share/presentation/widgets/share_preview_widgets.dart';
import 'package:tilawa/features/share/presentation/widgets/video_composition.dart';
import 'package:tilawa/features/share/presentation/widgets/video_content_renderer.dart';
import 'package:tilawa/features/share/presentation/widgets/video_reel_design.dart';
import 'package:tilawa/features/share/presentation/widgets/video_review_panel.dart';
import 'package:tilawa/features/share/presentation/widgets/video_step_indicator.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class VideoReelComposerScreen extends StatefulWidget {
  const VideoReelComposerScreen({
    super.key,
    required this.surahNumber,
    required this.initialFromAyah,
    required this.initialToAyah,
    required this.reciterName,
    required this.reciterServerUrl,
  });

  final int surahNumber;
  final int initialFromAyah;
  final int initialToAyah;
  final String reciterName;
  final String reciterServerUrl;

  @override
  State<VideoReelComposerScreen> createState() =>
      _VideoReelComposerScreenState();
}

class _VideoReelComposerScreenState extends State<VideoReelComposerScreen> {
  final Map<int, GlobalKey> _videoBoundaryKeys = {};
  final ValueNotifier<bool> _videoIsMuted = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _singleVideoCaptureSurfaceVisible =
      ValueNotifier<bool>(false);
  bool _isGenerateRequestInFlight = false;
  bool _isSavingPreparedContent = false;

  @override
  void dispose() {
    _videoIsMuted.dispose();
    _singleVideoCaptureSurfaceVisible.value = false;
    _singleVideoCaptureSurfaceVisible.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<ShareCubit>().configureAudioClip(
      surahNumber: widget.surahNumber,
      fromAyah: widget.initialFromAyah,
      toAyah: widget.initialToAyah,
      reciterName: widget.reciterName,
      serverUrl: widget.reciterServerUrl,
    );
    final state = context.read<ShareCubit>().state;
    _syncVideoBoundaryKeys(state.videoPageSpecs);
  }

  void _syncVideoBoundaryKeys(List<VideoPageSpec> specs) {
    final activePages = specs.map((s) => s.pageNumber).toSet();
    _videoBoundaryKeys.removeWhere((page, _) => !activePages.contains(page));
    for (final spec in specs) {
      _videoBoundaryKeys.putIfAbsent(spec.pageNumber, () => GlobalKey());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ShareCubit, ShareState>(
          listenWhen: (prev, curr) =>
              prev.videoPageSpecs != curr.videoPageSpecs,
          listener: (context, state) =>
              _syncVideoBoundaryKeys(state.videoPageSpecs),
        ),
        BlocListener<ShareCubit, ShareState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            final bool isGenerating =
                state.status == ShareStatus.capturing ||
                state.status == ShareStatus.generating;
            if (!isGenerating && _singleVideoCaptureSurfaceVisible.value) {
              _singleVideoCaptureSurfaceVisible.value = false;
            }
            if (!isGenerating) {
              _isGenerateRequestInFlight = false;
            }
          },
        ),
        BlocListener<ShareCubit, ShareState>(
          listenWhen: (previous, current) {
            final completedShare =
                previous.status == ShareStatus.sharing &&
                current.status == ShareStatus.idle &&
                current.content == null;
            final failedShare =
                previous.status == ShareStatus.sharing &&
                current.status == ShareStatus.error;
            return completedShare || failedShare;
          },
          listener: (context, state) {
            if (!mounted) return;
            if (state.status == ShareStatus.idle && state.content == null) {
              _showInfoToast(context, context.l10n.shareReadyTitle);
            } else if (state.status == ShareStatus.error &&
                state.errorMessage != null) {
              _showErrorToast(context, state.errorMessage!);
            }
          },
        ),
      ],
      child: ValueListenableBuilder<bool>(
        valueListenable: _singleVideoCaptureSurfaceVisible,
        builder: (context, captureVisible, _) {
          return BlocBuilder<ShareCubit, ShareState>(
            buildWhen: (p, c) =>
                p.videoPageSpecs != c.videoPageSpecs ||
                p.status != c.status ||
                p.capturingIndex != c.capturingIndex,
            builder: (context, state) {
              final isGeneratingVisuals =
                  state.status == ShareStatus.capturing ||
                  state.status == ShareStatus.generating;
              final reciterName = state.reciterName ?? widget.reciterName;
              final reelPalette = VideoReelPalette.fromContext(context);
              final backgroundColor = reelPalette.mushafBackgroundColor;

              return Stack(
                children: [
                  if (captureVisible || isGeneratingVisuals)
                    Offstage(
                      offstage: !isGeneratingVisuals,
                      child: _OffScreenRenderers(
                        videoBoundaryKeys: _videoBoundaryKeys,
                        videoPageSpecs: state.videoPageSpecs,
                        capturingIndex: state.capturingIndex,
                        surahNumber: widget.surahNumber,
                        reciterName: reciterName,
                        backgroundColor: backgroundColor,
                        isCapturing: true,
                      ),
                    ),
                  ImmersiveComposerScaffold(
                    key: const ValueKey('immersive_composer_scaffold'),
                    backgroundIntent: BackgroundIntent.media,
                    title: context.l10n.shareModeReel,
                    subtitle: context.l10n.shareComposerSubtitle,
                    onClose: () => Navigator.of(context).maybePop(),
                    background:
                        BlocSelector<ShareCubit, ShareState, _BackgroundState>(
                          selector: (state) => _BackgroundState(
                            status: state.status,
                            content: state.content,
                            fromAyah: state.fromAyah ?? widget.initialFromAyah,
                            toAyah: state.toAyah ?? widget.initialToAyah,
                            reciterName:
                                state.reciterName ?? widget.reciterName,
                          ),
                          builder: (context, bState) {
                            final reelPalette = VideoReelPalette.fromContext(
                              context,
                            );
                            final isReviewing =
                                bState.status == ShareStatus.reviewing;
                            final isScreenshotReview =
                                isReviewing &&
                                bState.content is ShareScreenshot;

                            final isBusyGenerating =
                                bState.status == ShareStatus.capturing ||
                                bState.status == ShareStatus.generating;

                            final child =
                                isReviewing && bState.content is ShareVideo
                                ? MediaPreviewFrame(
                                    key: const ValueKey('video_preview'),
                                    aspectRatio: 9 / 16,
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: _videoIsMuted,
                                      builder: (context, isMuted, _) {
                                        return GeneratedVideoPreview(
                                          filePath:
                                              (bState.content as ShareVideo)
                                                  .filePath,
                                          isMuted: isMuted,
                                          onMuteChanged: (muted) =>
                                              _videoIsMuted.value = muted,
                                        );
                                      },
                                    ),
                                  )
                                : isScreenshotReview
                                ? MediaPreviewFrame(
                                    key: const ValueKey('image_preview'),
                                    child: GeneratedImagePreview(
                                      filePath:
                                          (bState.content as ShareScreenshot)
                                              .filePath,
                                    ),
                                  )
                                : isBusyGenerating
                                ? _GeneratingBackdrop(
                                    key: const ValueKey('generating_backdrop'),
                                    backgroundColor:
                                        reelPalette.mushafBackgroundColor,
                                  )
                                : _VideoLivePreview(
                                    key: const ValueKey('live_preview'),
                                    surahNumber: widget.surahNumber,
                                    fromAyah: bState.fromAyah,
                                    toAyah: bState.toAyah,
                                    initialFromAyah: widget.initialFromAyah,
                                    initialToAyah: widget.initialToAyah,
                                    reciterName:
                                        bState.reciterName ??
                                        widget.reciterName,
                                    backgroundColor:
                                        reelPalette.mushafBackgroundColor,
                                  );

                            return child;
                          },
                        ),
                    preview: const SizedBox.expand(),
                    bottomPanel: BlocBuilder<ShareCubit, ShareState>(
                      buildWhen: (p, c) =>
                          p.status != c.status ||
                          p.progress != c.progress ||
                          p.progressMessage != c.progressMessage ||
                          p.fromAyah != c.fromAyah ||
                          p.toAyah != c.toAyah ||
                          p.reciterName != c.reciterName ||
                          p.isLoadingReciters != c.isLoadingReciters ||
                          p.errorMessage != c.errorMessage,
                      builder: (context, state) {
                        final isReviewing =
                            state.status == ShareStatus.reviewing;
                        final isBusy =
                            state.status == ShareStatus.capturing ||
                            state.status == ShareStatus.generating ||
                            state.status == ShareStatus.sharing;
                        final isGeneratingVideo =
                            state.status == ShareStatus.capturing ||
                            state.status == ShareStatus.generating;

                        final fromAyah =
                            state.fromAyah ?? widget.initialFromAyah;
                        final toAyah = state.toAyah ?? widget.initialToAyah;
                        final maxAyah = getVerseCount(widget.surahNumber);
                        final reciterName =
                            state.reciterName ?? widget.reciterName;

                        return Column(
                          key: const ValueKey('bottom_panel_root'),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            VideoStepIndicator(
                              status: state.status,
                              progress: state.progress,
                            ),
                            if (isReviewing && !isBusy)
                              VideoReviewPanel(
                                key: const ValueKey('review_panel'),
                                content: state.content!,
                                onEdit: () => context
                                    .read<ShareCubit>()
                                    .discardPreparedContent(),
                                isSaving: _isSavingPreparedContent,
                                onSave: _isSavingPreparedContent
                                    ? () {}
                                    : () => _handleSavePreparedContent(context),
                                onShare: () =>
                                    context.read<ShareCubit>().shareContent(),
                              )
                            else
                              ComposerControls(
                                key: const ValueKey('composer_controls'),
                                durationPreset: ShareDurationPreset.auto,
                                fromAyah: fromAyah,
                                toAyah: toAyah,
                                minAyah: state.minAyah ?? 1,
                                maxAyah: maxAyah,
                                isBusy: isBusy,
                                isGeneratingVideo: isGeneratingVideo,
                                isError: state.status == ShareStatus.error,
                                rangeIsValid: _isValidRange(
                                  fromAyah,
                                  toAyah,
                                  maxAyah,
                                ),
                                reciterName: reciterName,
                                isLoadingReciters: state.isLoadingReciters,
                                canSelectReciter: true,
                                arabicSurahName: getSurahNameArabic(
                                  widget.surahNumber,
                                ),
                                errorMessage: state.status == ShareStatus.error
                                    ? state.errorMessage
                                    : null,
                                rangeIssue: _rangeIssueLabel(
                                  context,
                                  from: fromAyah,
                                  to: toAyah,
                                  max: maxAyah,
                                ),
                                progressLabel: _progressLabelForState(
                                  context,
                                  state,
                                ),
                                progressPercent: isGeneratingVideo
                                    ? state.progress
                                    : null,
                                onFromChanged: (v) => context
                                    .read<ShareCubit>()
                                    .updateVerseRange(fromAyah: v),
                                onToChanged: (v) => context
                                    .read<ShareCubit>()
                                    .updateVerseRange(toAyah: v),
                                onPrimaryAction: () => _handleGenerateVideo(
                                  context,
                                  state,
                                  maxAyah,
                                ),
                                onCancel: () => context
                                    .read<ShareCubit>()
                                    .cancelGeneration(),
                                onDurationChanged: (_) {},
                                onReciterTap: () => _showReciterPicker(context),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  bool _isValidRange(int from, int to, int max) {
    final count = to - from + 1;
    return from >= 1 &&
        to >= from &&
        to <= max &&
        count <= ShareLimits.maxVersesPerClip;
  }

  String? _rangeIssueLabel(
    BuildContext context, {
    required int from,
    required int to,
    required int max,
  }) {
    if (from < 1 || to > max) {
      return context.l10n.shareInvalidRangeBounds;
    }
    if (to < from) {
      return context.l10n.shareInvalidRangeOrder;
    }
    final count = to - from + 1;
    if (count > ShareLimits.maxVersesPerClip) {
      return context.l10n.maxVersesExceeded(ShareLimits.maxVersesPerClip);
    }
    return null;
  }

  Future<void> _handleGenerateVideo(
    BuildContext context,
    ShareState state,
    int maxAyah,
  ) async {
    if (_isGenerateRequestInFlight) return;

    final from = state.fromAyah ?? widget.initialFromAyah;
    final to = state.toAyah ?? widget.initialToAyah;
    if (!_isValidRange(from, to, maxAyah)) return;

    _isGenerateRequestInFlight = true;

    final cubit = context.read<ShareCubit>();
    final messages = context.shareProgressMessages;
    final appTitle = context.l10n.appTitle;
    final viaLabel = context.l10n.sharedViaTilawa;

    final Set<int> capturePages = <int>{
      for (final spec in state.videoPageSpecs) spec.pageNumber,
    };
    await Future.wait([
      for (final page in capturePages)
        quranQcfLocator<QuranFontService>().ensureSingleFontLoaded(page),
    ]);
    if (!mounted) {
      _isGenerateRequestInFlight = false;
      return;
    }

    _singleVideoCaptureSurfaceVisible.value = true;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      _isGenerateRequestInFlight = false;
      return;
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      _isGenerateRequestInFlight = false;
      return;
    }

    try {
      await cubit.generateVideo(
        surahName: getSurahNameArabic(widget.surahNumber),
        progressMessages: messages,
        appName: appTitle,
        sharedViaLabel: viaLabel,
        handles: _videoBoundaryKeys.values
            .map((key) => WidgetCaptureHandle(key))
            .toList(),
        maxDurationSeconds: null,
      );
    } finally {
      _isGenerateRequestInFlight = false;
    }
  }

  Future<void> _showReciterPicker(BuildContext context) async {
    final cubit = context.read<ShareCubit>();
    if (cubit.state.reciterOptions.isEmpty) {
      await cubit.loadReciterOptions();
      if (!context.mounted) return;
    }

    final state = cubit.state;
    showTilawaModalBottomSheet<ShareReciterOption>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReciterPickerSheet(
        options: state.reciterOptions,
        selectedReciterName: state.reciterName ?? widget.reciterName,
        selectedServerUrl: state.reciterServerUrl ?? '',
      ),
    ).then((option) {
      if (option != null && mounted) {
        cubit.updateReciter(name: option.name, serverUrl: option.serverUrl);
      }
    });
  }

  String? _progressLabelForState(BuildContext context, ShareState state) {
    if (state.progressMessage.isNotEmpty) {
      return state.progressMessage;
    }
    if (state.status == ShareStatus.capturing) {
      return context.l10n.capturingReaderVisuals;
    }
    if (state.status == ShareStatus.generating) {
      return context.l10n.preparingReelStatus;
    }
    if (state.status == ShareStatus.sharing) {
      return context.l10n.preparingVideoEncoding;
    }
    return null;
  }

  Future<void> _handleSavePreparedContent(BuildContext context) async {
    if (_isSavingPreparedContent) return;
    setState(() => _isSavingPreparedContent = true);

    final cubit = context.read<ShareCubit>();
    final l10n = context.l10n;
    try {
      await cubit.savePreparedContent();
      if (!context.mounted) return;
      final exportedPath = cubit.state.lastSaveExportPath;
      if (exportedPath == null) return;
      _showInfoToast(
        context,
        '${l10n.save} ${l10n.completed}: ${exportedPath.split('/').last}',
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^[\w]+:\s*'), '');
      _showErrorToast(context, msg);
    } finally {
      if (mounted) {
        setState(() => _isSavingPreparedContent = false);
      }
    }
  }

  void _showInfoToast(BuildContext context, String message) {
    TilawaFeedback.showToast(
      context,
      message: message,
      variant: TilawaFeedbackVariant.info,
    );
  }

  void _showErrorToast(BuildContext context, String message) {
    TilawaFeedback.showToast(
      context,
      message: message,
      variant: TilawaFeedbackVariant.error,
    );
  }
}

/// Lightweight backdrop shown in place of [_VideoLivePreview] while the
/// composer is capturing frames or encoding the video. Renders only a
/// colored canvas plus the cubit's progress label — no mushaf tree — so
/// only the offstage capture surface is paying for layout/raster during
/// generation.
class _GeneratingBackdrop extends StatelessWidget {
  const _GeneratingBackdrop({super.key, required this.backgroundColor});

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return ColoredBox(
      color: backgroundColor,
      child: BlocSelector<ShareCubit, ShareState, String>(
        selector: (state) => state.progressMessage,
        builder: (context, progressMessage) {
          if (progressMessage.isEmpty) {
            return const SizedBox.expand();
          }
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
              child: Text(
                progressMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VideoLivePreview extends StatefulWidget {
  const _VideoLivePreview({
    super.key,
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
    required this.initialFromAyah,
    required this.initialToAyah,
    required this.reciterName,
    required this.backgroundColor,
  });

  final int surahNumber;
  final int fromAyah;
  final int toAyah;
  final int initialFromAyah;
  final int initialToAyah;
  final String reciterName;
  final Color backgroundColor;

  @override
  State<_VideoLivePreview> createState() => _VideoLivePreviewState();
}

class _VideoLivePreviewState extends State<_VideoLivePreview> {
  @override
  Widget build(BuildContext context) {
    final specs = buildVideoPageSpecs(
      surahNumber: widget.surahNumber,
      fromAyah: widget.fromAyah,
      toAyah: widget.toAyah,
      isInitialSelection:
          widget.fromAyah == widget.initialFromAyah &&
          widget.toAyah == widget.initialToAyah,
    );

    if (kReelComposerSingleTree) {
      return ColoredBox(
        color: widget.backgroundColor,
        child: specs.length == 1
            ? _buildCompositionPage(context, specs.single, 0, specs.length)
            : PageView.builder(
                itemCount: specs.length,
                itemBuilder: (context, index) => _buildCompositionPage(
                  context,
                  specs[index],
                  index,
                  specs.length,
                ),
              ),
      );
    }

    return Container(
      color: widget.backgroundColor,
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: RepaintBoundary(
            child: VideoContentRenderer(
              surahNumber: widget.surahNumber,
              fromAyah: widget.fromAyah,
              toAyah: widget.toAyah,
              reciterName: widget.reciterName,
              pageSpecs: specs,
              isCapturing: false,
              backgroundColor: widget.backgroundColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompositionPage(
    BuildContext context,
    VideoPageSpec spec,
    int index,
    int totalPages,
  ) {
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: VideoComposition(
          spec: VideoCompositionSpec(
            surahNumber: widget.surahNumber,
            pageSpec: spec,
            pageIndex: index,
            totalPages: totalPages,
            reciterName: widget.reciterName,
            mode: VideoCompositionMode.edit,
            localeName: context.l10n.localeName,
            backgroundColor: widget.backgroundColor,
          ),
        ),
      ),
    );
  }
}

class _OffScreenRenderers extends StatelessWidget {
  const _OffScreenRenderers({
    required this.videoBoundaryKeys,
    required this.videoPageSpecs,
    required this.capturingIndex,
    required this.surahNumber,
    required this.reciterName,
    required this.backgroundColor,
    required this.isCapturing,
  });

  final Map<int, GlobalKey> videoBoundaryKeys;
  final List<VideoPageSpec> videoPageSpecs;
  final int? capturingIndex;
  final int surahNumber;
  final String reciterName;
  final Color backgroundColor;
  final bool isCapturing;

  /// Cached renderer instance to avoid recreating on every build.
  static final MushafPageRenderer _renderer =
      MushafPageRenderer.defaultRenderer();

  @override
  Widget build(BuildContext context) {
    if (videoPageSpecs.isEmpty) {
      return const SizedBox.shrink();
    }

    final reelPalette = VideoReelPalette.fromContext(context);
    final int safeIndex = (capturingIndex ?? 0).clamp(
      0,
      videoPageSpecs.length - 1,
    );
    final VideoPageSpec spec = videoPageSpecs[safeIndex];
    final GlobalKey? key = videoBoundaryKeys[spec.pageNumber];
    if (key == null) {
      return const SizedBox.shrink();
    }

    if (kReelComposerSingleTree) {
      return SizedBox.expand(
        child: Center(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: RepaintBoundary(
              key: key,
              child: VideoComposition(
                spec: VideoCompositionSpec(
                  surahNumber: surahNumber,
                  pageSpec: spec,
                  pageIndex: safeIndex,
                  totalPages: videoPageSpecs.length,
                  reciterName: reciterName,
                  mode: VideoCompositionMode.capture,
                  localeName: context.l10n.localeName,
                  backgroundColor: backgroundColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: VideoContentRenderer.videoWidth,
              height: VideoContentRenderer.videoHeight,
              child: ColoredBox(
                color: backgroundColor,
                child: _renderer.build(
                  context: context,
                  pageSpec: spec,
                  surahNumber: surahNumber,
                  verseBackgroundColor: (s, v) =>
                      (s == surahNumber &&
                          v >= spec.fromAyah &&
                          v <= spec.toAyah)
                      ? reelPalette.verseHighlightColor
                      : null,
                  verseTextColor: (s, v) => null,
                  textColor: reelPalette.mushafTextColor,
                  pageBackgroundColor: backgroundColor,
                  isCapturing: isCapturing,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundState {
  final ShareStatus status;
  final ShareContent? content;
  final int fromAyah;
  final int toAyah;
  final String? reciterName;

  _BackgroundState({
    required this.status,
    required this.content,
    required this.fromAyah,
    required this.toAyah,
    required this.reciterName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BackgroundState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          content == other.content &&
          fromAyah == other.fromAyah &&
          toAyah == other.toAyah &&
          reciterName == other.reciterName;

  @override
  int get hashCode =>
      Object.hash(status, content, fromAyah, toAyah, reciterName);
}
