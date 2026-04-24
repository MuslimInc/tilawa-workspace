import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/share_content.dart';
import '../../domain/entities/share_limits.dart';
import '../../domain/entities/widget_capture_handle.dart';
import '../cubit/share_cubit.dart';
import '../cubit/share_state.dart';
import '../share_progress_messages_l10n.dart';
import '../utils/share_reciter_options.dart';
import '../utils/video_page_specs.dart';
import '../utils/video_reel_composer_presets.dart';
import '../widgets/reciter_picker_sheet.dart';
import '../widgets/share_preview_widgets.dart';
import '../widgets/video_content_renderer.dart';
import '../widgets/video_reel_widgets.dart';

class VideoReelComposerScreen extends StatefulWidget {
  const VideoReelComposerScreen({
    super.key,
    required this.surahNumber,
    required this.currentPage,
    required this.initialFromAyah,
    required this.initialToAyah,
    required this.reciterName,
    required this.reciterServerUrl,
    required this.readerBoundaryKey,
    this.readerPreviewBytesNotifier,
  });

  final int surahNumber;
  final int currentPage;
  final int initialFromAyah;
  final int initialToAyah;
  final String reciterName;
  final String reciterServerUrl;
  final GlobalKey readerBoundaryKey;
  final ValueListenable<Uint8List?>? readerPreviewBytesNotifier;

  static Route<void> route({
    required ShareCubit cubit,
    required int surahNumber,
    required int currentPage,
    required int initialFromAyah,
    required int initialToAyah,
    required String reciterName,
    required String reciterServerUrl,
    required GlobalKey readerBoundaryKey,
    ValueListenable<Uint8List?>? readerPreviewBytesNotifier,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) =>
          BlocProvider.value(
            value: cubit,
            child: VideoReelComposerScreen(
              surahNumber: surahNumber,
              currentPage: currentPage,
              initialFromAyah: initialFromAyah,
              initialToAyah: initialToAyah,
              reciterName: reciterName,
              reciterServerUrl: reciterServerUrl,
              readerBoundaryKey: readerBoundaryKey,
              readerPreviewBytesNotifier: readerPreviewBytesNotifier,
            ),
          ),
    );
  }

  @override
  State<VideoReelComposerScreen> createState() =>
      _VideoReelComposerScreenState();
}

class _VideoReelComposerScreenState extends State<VideoReelComposerScreen> {
  final Map<int, GlobalKey> _videoBoundaryKeys = {};
  bool _singleVideoCaptureSurfaceVisible = false;
  bool _videoIsMuted = false;

  @override
  void initState() {
    super.initState();
    final pageData = getPageData(widget.currentPage);
    final primarySurahEntries = pageData
        .where((entry) => entry.surah == widget.surahNumber)
        .toList();

    final firstAyah = primarySurahEntries.isNotEmpty
        ? primarySurahEntries.first.start
        : 1;
    final lastAyah = primarySurahEntries.isNotEmpty
        ? primarySurahEntries.last.end
        : getVerseCount(widget.surahNumber);

    context.read<ShareCubit>().configureAudioClip(
      surahNumber: widget.surahNumber,
      fromAyah: widget.initialFromAyah,
      toAyah: widget.initialToAyah,
      minAyah: firstAyah,
      maxAyah: lastAyah,
      reciterName: widget.reciterName,
      serverUrl: widget.reciterServerUrl,
    );
  }

  void _syncVideoBoundaryKeys(List<VideoPageSpec> specs) {
    final requiredIndices = Iterable<int>.generate(specs.length).toSet();
    _videoBoundaryKeys.removeWhere((key, _) => !requiredIndices.contains(key));
    for (final index in requiredIndices) {
      _videoBoundaryKeys.putIfAbsent(index, () => GlobalKey());
    }
  }

  void _showReciterPicker() async {
    final cubit = context.read<ShareCubit>();
    if (cubit.state.reciterOptions.isEmpty) {
      await cubit.loadReciterOptions();
    }
    if (!mounted) return;

    final result = await showModalBottomSheet<ShareReciterOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReciterPickerSheet(
        options: cubit.state.reciterOptions,
        selectedReciterName: cubit.state.reciterName ?? widget.reciterName,
        selectedServerUrl:
            cubit.state.reciterServerUrl ?? widget.reciterServerUrl,
      ),
    );

    if (result != null && mounted) {
      cubit.updateReciter(name: result.name, serverUrl: result.serverUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShareCubit, ShareState>(
      listenWhen: (prev, curr) => prev.videoPageSpecs != curr.videoPageSpecs,
      listener: (context, state) =>
          _syncVideoBoundaryKeys(state.videoPageSpecs),
      builder: (context, state) {
        final isBusy =
            state.status == ShareStatus.capturing ||
            state.status == ShareStatus.generating ||
            state.status == ShareStatus.sharing;

        final isReviewing = state.status == ShareStatus.reviewing;
        final isVideoReview = isReviewing && state.content is ShareVideo;
        final isScreenshotReview =
            isReviewing && state.content is ShareScreenshot;

        final fromAyah = state.fromAyah ?? widget.initialFromAyah;
        final toAyah = state.toAyah ?? widget.initialToAyah;
        final minAyah = state.minAyah ?? 1;
        final maxAyah = state.maxAyah ?? getVerseCount(widget.surahNumber);
        final reciterName = state.reciterName ?? widget.reciterName;
        final Color backgroundColor = context.colorScheme.surface;

        return Stack(
          children: [
            if (state.videoPageSpecs.length > 1 ||
                _singleVideoCaptureSurfaceVisible)
              Offstage(
                offstage: !isBusy,
                child: RepaintBoundary(
                  child: _OffScreenRenderers(
                    videoBoundaryKeys: _videoBoundaryKeys,
                    videoPageSpecs: state.videoPageSpecs,
                    surahNumber: widget.surahNumber,
                    reciterName: reciterName,
                    backgroundColor: backgroundColor,
                  ),
                ),
              ),
            ImmersiveComposerScaffold(
              title: isReviewing
                  ? context.l10n.shareReadyTitle
                  : context.l10n.shareModeReel,
              subtitle: isReviewing ? null : context.l10n.shareComposerSubtitle,
              onClose: () => Navigator.of(context).maybePop(),
              background: ColoredBox(color: backgroundColor),
              preview: AnimatedSwitcher(
                duration: Theme.of(context).tokens.durationMedium,
                child: isVideoReview
                    ? MediaPreviewFrame(
                        aspectRatio: 9 / 16,
                        child: GeneratedVideoPreview(
                          filePath: (state.content as ShareVideo).filePath,
                          isMuted: _videoIsMuted,
                          onMuteChanged: (muted) =>
                              setState(() => _videoIsMuted = muted),
                        ),
                      )
                    : isScreenshotReview
                    ? MediaPreviewFrame(
                        child: GeneratedImagePreview(
                          filePath: (state.content as ShareScreenshot).filePath,
                        ),
                      )
                    : _buildLivePreview(
                        reciterName,
                        fromAyah,
                        toAyah,
                        state.videoPageSpecs,
                      ),
              ),
              bottomPanel: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VideoStepIndicator(status: state.status),
                  AnimatedSwitcher(
                    duration: Theme.of(context).tokens.durationFast,
                    child: isReviewing
                        ? VideoReviewPanel(
                            content: state.content!,
                            onEdit: () => context
                                .read<ShareCubit>()
                                .discardPreparedContent(),
                            onShare: () =>
                                context.read<ShareCubit>().shareContent(),
                          )
                        : ComposerControls(
                            durationPreset: ShareDurationPreset.auto,
                            fromAyah: fromAyah,
                            toAyah: toAyah,
                            minAyah: minAyah,
                            maxAyah: maxAyah,
                            isBusy: isBusy,
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
                            progressLabel: _progressLabelForState(
                              context,
                              state,
                            ),
                            onReciterTap: _showReciterPicker,
                            onDurationChanged: (_) {},
                            onFromChanged: (v) => context
                                .read<ShareCubit>()
                                .updateVerseRange(fromAyah: v),
                            onToChanged: (v) => context
                                .read<ShareCubit>()
                                .updateVerseRange(toAyah: v),
                            onPrimaryAction: () =>
                                _handleGenerateVideo(context, state, maxAyah),
                            onCancel: () =>
                                context.read<ShareCubit>().cancelGeneration(),
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isValidRange(int from, int to, int max) {
    final count = to - from + 1;
    return from >= 1 &&
        to >= from &&
        to <= max &&
        count <= ShareLimits.maxVersesPerClip;
  }

  Future<void> _handleGenerateVideo(
    BuildContext context,
    ShareState state,
    int maxAyah,
  ) async {
    final from = state.fromAyah ?? widget.initialFromAyah;
    final to = state.toAyah ?? widget.initialToAyah;
    if (!_isValidRange(from, to, maxAyah)) return;

    final cubit = context.read<ShareCubit>();
    final messages = context.shareProgressMessages;
    final viaLabel = context.l10n.sharedViaTilawa;

    final Set<int> capturePages = <int>{
      for (final spec in state.videoPageSpecs) spec.pageNumber,
    };
    await Future.wait([
      for (final page in capturePages)
        quranQcfLocator<QuranFontService>().ensureSingleFontLoaded(page),
    ]);
    if (!mounted) return;

    setState(() => _singleVideoCaptureSurfaceVisible = true);

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    cubit.generateVideo(
      surahName: getSurahNameArabic(widget.surahNumber),
      progressMessages: messages,
      appName: 'Tilawa',
      sharedViaLabel: viaLabel,
      handles: _videoBoundaryKeys.values
          .map((key) => WidgetCaptureHandle(key))
          .toList(),
      maxDurationSeconds: null,
    );
  }

  Widget _buildLivePreview(
    String reciterName,
    int fromAyah,
    int toAyah,
    List<VideoPageSpec> specs,
  ) {
    final Color backgroundColor = context.colorScheme.surface;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: RepaintBoundary(
              child: VideoContentRenderer(
                surahNumber: widget.surahNumber,
                fromAyah: fromAyah,
                toAyah: toAyah,
                reciterName: reciterName,
                pageSpecs: specs.isEmpty ? null : [specs.first],
                backgroundColor: backgroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _progressLabelForState(BuildContext context, ShareState state) {
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
}

class _OffScreenRenderers extends StatelessWidget {
  const _OffScreenRenderers({
    required this.videoBoundaryKeys,
    required this.videoPageSpecs,
    required this.surahNumber,
    required this.reciterName,
    this.backgroundColor,
  });

  final Map<int, GlobalKey> videoBoundaryKeys;
  final List<VideoPageSpec> videoPageSpecs;
  final int surahNumber;
  final String reciterName;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: 0,
      maxWidth: double.infinity,
      minHeight: 0,
      maxHeight: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          videoPageSpecs.length,
          (i) => RepaintBoundary(
            key: videoBoundaryKeys[i],
            child: SizedBox(
              width: VideoContentRenderer.videoWidth,
              height: VideoContentRenderer.videoHeight,
              child: VideoContentRenderer(
                surahNumber: surahNumber,
                fromAyah: videoPageSpecs[i].fromAyah,
                toAyah: videoPageSpecs[i].toAyah,
                reciterName: reciterName,
                pageSpecs: [videoPageSpecs[i]],
                isCapturing: true,
                backgroundColor: backgroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
