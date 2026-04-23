import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/share_content.dart';
import '../../domain/entities/widget_capture_handle.dart';
import '../cubit/share_cubit.dart';
import '../cubit/share_state.dart';
import '../widgets/reader_page_content_renderer.dart';
import '../widgets/screenshot_composer_widgets.dart';
import '../widgets/share_poster_renderer.dart';
import '../widgets/share_preview_widgets.dart';
import '../widgets/video_reel_widgets.dart';

class ScreenshotComposerScreen extends StatefulWidget {
  const ScreenshotComposerScreen({
    super.key,
    required this.surahNumber,
    required this.currentPage,
    required this.initialFromAyah,
    required this.initialToAyah,
    required this.reciterName,
    required this.readerBoundaryKey,
    this.readerPreviewBytesNotifier,
  });

  final int surahNumber;
  final int currentPage;
  final int initialFromAyah;
  final int initialToAyah;
  final String reciterName;
  final GlobalKey readerBoundaryKey;
  final ValueListenable<Uint8List?>? readerPreviewBytesNotifier;

  static Route<void> route({
    required ShareCubit cubit,
    required int surahNumber,
    required int currentPage,
    required int initialFromAyah,
    required int initialToAyah,
    required String reciterName,
    required GlobalKey readerBoundaryKey,
    ValueListenable<Uint8List?>? readerPreviewBytesNotifier,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) =>
          BlocProvider.value(
            value: cubit,
            child: ScreenshotComposerScreen(
              surahNumber: surahNumber,
              currentPage: currentPage,
              initialFromAyah: initialFromAyah,
              initialToAyah: initialToAyah,
              reciterName: reciterName,
              readerBoundaryKey: readerBoundaryKey,
              readerPreviewBytesNotifier: readerPreviewBytesNotifier,
            ),
          ),
    );
  }

  @override
  State<ScreenshotComposerScreen> createState() =>
      _ScreenshotComposerScreenState();
}

class _ScreenshotComposerScreenState extends State<ScreenshotComposerScreen> {
  final GlobalKey _posterBoundaryKey = GlobalKey();
  final GlobalKey _readerPageBoundaryKey = GlobalKey();

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
      serverUrl: '', // Not needed for screenshot
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShareCubit, ShareState>(
      builder: (context, state) {
        final isBusy =
            state.status == ShareStatus.capturing ||
            state.status == ShareStatus.generating ||
            state.status == ShareStatus.sharing;
        final isReviewing = state.status == ShareStatus.reviewing;

        final fromAyah = state.fromAyah ?? widget.initialFromAyah;
        final toAyah = state.toAyah ?? widget.initialToAyah;
        final minAyah = state.minAyah ?? 1;
        final maxAyah = state.maxAyah ?? getVerseCount(widget.surahNumber);

        return ImmersiveComposerScaffold(
          title: isReviewing
              ? context.l10n.shareReadyTitle
              : context.l10n.shareScreenshot,
          subtitle: isReviewing ? null : context.l10n.shareComposerSubtitle,
          onClose: () => Navigator.of(context).maybePop(),
          background: _buildBackdrop(),
          preview: AnimatedSwitcher(
            duration: Theme.of(context).tokens.durationMedium,
            child: isReviewing && state.content is ShareScreenshot
                ? MediaPreviewFrame(
                    aspectRatio: 4 / 5,
                    child: GeneratedImagePreview(
                      filePath: (state.content as ShareScreenshot).filePath,
                    ),
                  )
                : _buildLivePreview(state, fromAyah, toAyah),
          ),
          bottomPanel: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isBusy)
                SizedBox(
                  height: Theme.of(context).tokens.progressHeight,
                  child: LinearProgressIndicator(
                    backgroundColor: Theme.of(context).colorScheme.surface
                        .withValues(
                          alpha: Theme.of(context).tokens.opacitySubtle,
                        ),
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              AnimatedSwitcher(
                duration: Theme.of(context).tokens.durationFast,
                child: isReviewing
                    ? VideoReviewPanel(
                        content: state.content!,
                        onEdit: () =>
                            context.read<ShareCubit>().discardPreparedContent(),
                        onShare: () =>
                            context.read<ShareCubit>().shareContent(),
                      )
                    : ScreenshotComposerControls(
                        layout: state.screenshotLayout,
                        fromAyah: fromAyah,
                        toAyah: toAyah,
                        minAyah: minAyah,
                        maxAyah: maxAyah,
                        isBusy: isBusy,
                        onLayoutChanged: (l) => context
                            .read<ShareCubit>()
                            .updateScreenshotLayout(l),
                        onFromChanged: (v) => context
                            .read<ShareCubit>()
                            .updateVerseRange(fromAyah: v),
                        onToChanged: (v) => context
                            .read<ShareCubit>()
                            .updateVerseRange(toAyah: v),
                        onPrimaryAction: () => _handleCapture(
                          context,
                          state,
                          WidgetCaptureHandle(
                            state.screenshotLayout ==
                                    ShareScreenshotLayout.readerPage
                                ? _readerPageBoundaryKey
                                : _posterBoundaryKey,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleCapture(
    BuildContext context,
    ShareState state,
    WidgetCaptureHandle handle,
  ) {
    context.read<ShareCubit>().prepareScreenshot(
      handle: handle,
      surahName: getSurahNameArabic(widget.surahNumber),
      pageNumber: widget.currentPage,
      appName: 'Tilawa',
      sharedViaLabel: context.l10n.sharedViaTilawa,
      preparingImageLabel: context.l10n.preparingScreenshot,
    );
  }

  Widget? _buildBackdrop() {
    final notifier = widget.readerPreviewBytesNotifier;
    if (notifier == null) return null;
    return ValueListenableBuilder<Uint8List?>(
      valueListenable: notifier,
      builder: (context, bytes, _) => bytes == null
          ? const SizedBox.shrink()
          : Opacity(
              opacity: 0.16,
              child: Image.memory(bytes, fit: BoxFit.cover),
            ),
    );
  }

  Widget _buildLivePreview(ShareState state, int fromAyah, int toAyah) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return Column(
      children: [
        MetadataChip(
          icon: Icons.auto_stories_rounded,
          label: getSurahNameArabic(widget.surahNumber),
        ),
        SizedBox(height: tokens.spaceMedium),
        Expanded(
          child: state.screenshotLayout == ShareScreenshotLayout.readerPage
              ? RepaintBoundary(
                  key: _readerPageBoundaryKey,
                  child: ReaderPageContentRenderer(
                    pageNumber: widget.currentPage,
                    uiTextDirection: Directionality.of(context),
                  ),
                )
              : RepaintBoundary(
                  key: _posterBoundaryKey,
                  child: SharePosterRenderer(
                    surahNumber: widget.surahNumber,
                    fromAyah: fromAyah,
                    toAyah: toAyah,
                    reciterName: widget.reciterName,
                  ),
                ),
        ),
      ],
    );
  }
}
