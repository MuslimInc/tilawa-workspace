import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/share_content.dart';
import '../cubit/share_cubit.dart';
import '../cubit/share_state.dart';
import '../utils/share_ayah_range_utils.dart';
import '../widgets/reader_page_content_renderer.dart';
import '../widgets/share_composer_widgets.dart';
import '../widgets/share_poster_renderer.dart';
import '../widgets/share_preview_widgets.dart';

enum ShareScreenshotLayout { readerPage, passageCard }

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
  late int _fromAyah;
  late int _toAyah;
  late final int _maxAyah;
  ShareScreenshotLayout _layout = ShareScreenshotLayout.readerPage;

  final GlobalKey _posterBoundaryKey = GlobalKey();
  final GlobalKey _readerPageBoundaryKey = GlobalKey();

  Widget? _backdropWidget;

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
    _backdropWidget = _buildBackdrop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShareCubit, ShareState>(
      listener: (context, state) {
        if (state.status == ShareStatus.idle && state.content == null) {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final isBusy =
            state.status == ShareStatus.capturing ||
            state.status == ShareStatus.generating ||
            state.status == ShareStatus.sharing;
        final isReviewing = state.status == ShareStatus.reviewing;

        return ImmersiveComposerScaffold(
          title: isReviewing
              ? context.l10n.shareReadyTitle
              : context.l10n.shareScreenshot,
          subtitle: isReviewing ? null : context.l10n.shareComposerSubtitle,
          onClose: () => Navigator.of(context).maybePop(),
          background: _backdropWidget,
          compactPanelHeightFactor: isReviewing ? 0.32 : null,
          regularPanelHeightFactor: isReviewing ? 0.28 : null,
          compactPreviewHeightFactor: isReviewing ? 0.56 : null,
          regularPreviewHeightFactor: isReviewing ? 0.7 : null,
          panelMinHeight: isReviewing ? 156 : null,
          previewMaxHeight: isReviewing ? 640 : null,
          preview: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isReviewing && state.content is ShareScreenshot
                ? _ReviewPreview(
                    filePath: (state.content as ShareScreenshot).filePath,
                    surahName: state.content!.surahName,
                  )
                : _buildLivePreview(),
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
              isReviewing
                  ? _ReviewPanel(
                      content: state.content!,
                      onEdit: () =>
                          context.read<ShareCubit>().discardPreparedContent(),
                      onShare: () => context.read<ShareCubit>().shareContent(),
                    )
                  : _ComposerControls(
                      layout: _layout,
                      fromAyah: _fromAyah,
                      toAyah: _toAyah,
                      maxAyah: _maxAyah,
                      isBusy: isBusy,
                      onLayoutChanged: (l) => setState(() => _layout = l),
                      onFromChanged: (v) => setState(() {
                        _fromAyah = v;
                        if (_toAyah < v) _toAyah = v;
                      }),
                      onToChanged: (v) => setState(() {
                        _toAyah = v;
                        if (_fromAyah > v) _fromAyah = v;
                      }),
                      onPrimaryAction: () => _handleCapture(context),
                    ),
            ],
          ),
        );
      },
    );
  }

  void _handleCapture(BuildContext context) {
    context.read<ShareCubit>().prepareScreenshot(
      boundaryKey: _layout == ShareScreenshotLayout.readerPage
          ? _readerPageBoundaryKey
          : _posterBoundaryKey,
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

  Widget _buildLivePreview() {
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
          child: _layout == ShareScreenshotLayout.readerPage
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
                    fromAyah: _fromAyah,
                    toAyah: _toAyah,
                    reciterName: widget.reciterName,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ReviewPreview extends StatelessWidget {
  const _ReviewPreview({required this.filePath, required this.surahName});
  final String filePath, surahName;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: PreviewFrame(
        aspectRatio: 4 / 5,
        child: GeneratedImagePreview(filePath: filePath),
      ),
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    required this.content,
    required this.onEdit,
    required this.onShare,
  });
  final ShareContent content;
  final VoidCallback onEdit, onShare;
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return Padding(
      padding: EdgeInsets.all(tokens.spaceMedium),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: onEdit,
                child: Text(context.l10n.edit),
              ),
            ),
          ),
          SizedBox(width: tokens.spaceSmall),
          Expanded(
            child: SizedBox(
              height: 44,
              child: FilledButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded),
                label: Text(
                  context.l10n.share,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerControls extends StatelessWidget {
  const _ComposerControls({
    required this.layout,
    required this.fromAyah,
    required this.toAyah,
    required this.maxAyah,
    required this.isBusy,
    required this.onLayoutChanged,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onPrimaryAction,
  });
  final ShareScreenshotLayout layout;
  final int fromAyah, toAyah, maxAyah;
  final bool isBusy;
  final ValueChanged<ShareScreenshotLayout> onLayoutChanged;
  final ValueChanged<int> onFromChanged, onToChanged;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Padding(
      padding: EdgeInsets.all(tokens.spaceMedium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShareControlsCard(
            children: [
              _LayoutTile(layout: layout, onLayoutChanged: onLayoutChanged),
              if (layout == ShareScreenshotLayout.passageCard) ...[
                const ShareTileDivider(),
                _AyahRangeTile(
                  fromAyah: fromAyah,
                  toAyah: toAyah,
                  maxAyah: maxAyah,
                  onFromChanged: onFromChanged,
                  onToChanged: onToChanged,
                ),
              ],
            ],
          ),
          SizedBox(height: tokens.spaceMedium),
          FilledButton.icon(
            onPressed: isBusy ? null : onPrimaryAction,
            icon: const Icon(Icons.screenshot_rounded),
            label: Text(context.l10n.shareScreenshot),
          ),
        ],
      ),
    );
  }
}

class _LayoutTile extends StatelessWidget {
  const _LayoutTile({required this.layout, required this.onLayoutChanged});
  final ShareScreenshotLayout layout;
  final ValueChanged<ShareScreenshotLayout> onLayoutChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShareControlTileShell(
      icon: Icons.layers_rounded,
      label: context.l10n.shareMode,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DropdownButton<ShareScreenshotLayout>(
            value: layout,
            underline: const SizedBox(),
            onChanged: (l) =>
                onLayoutChanged(l ?? ShareScreenshotLayout.readerPage),
            items: [
              DropdownMenuItem(
                value: ShareScreenshotLayout.readerPage,
                child: Text(context.l10n.shareLayoutReaderPage),
              ),
              DropdownMenuItem(
                value: ShareScreenshotLayout.passageCard,
                child: Text(context.l10n.shareLayoutPassageCard),
              ),
            ],
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahRangeTile extends StatelessWidget {
  const _AyahRangeTile({
    required this.fromAyah,
    required this.toAyah,
    required this.maxAyah,
    required this.onFromChanged,
    required this.onToChanged,
  });
  final int fromAyah;
  final int toAyah;
  final int maxAyah;
  final ValueChanged<int> onFromChanged;
  final ValueChanged<int> onToChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return ShareControlTileShell(
      icon: Icons.format_list_numbered_rounded,
      label: context.l10n.ayah,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerEnd,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AyahStepper(
              value: fromAyah,
              min: 1,
              max: maxAyah,
              onChanged: onFromChanged,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
              child: Text(
                '-',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            AyahStepper(
              value: toAyah,
              min: 1,
              max: maxAyah,
              onChanged: onToChanged,
            ),
          ],
        ),
      ),
    );
  }
}
