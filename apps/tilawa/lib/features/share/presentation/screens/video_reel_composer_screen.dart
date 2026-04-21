import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:video_player/video_player.dart';

import '../../../reciters/domain/usecases/get_reciters_use_case.dart';
import '../../data/services/reciter_audio_mapping.dart';
import '../../domain/entities/share_content.dart';
import '../../domain/entities/share_limits.dart';
import '../cubit/share_cubit.dart';
import '../cubit/share_state.dart';
import '../share_progress_messages_l10n.dart';
import '../utils/share_ayah_range_utils.dart';
import '../utils/share_reciter_options.dart';
import '../utils/video_page_specs.dart';
import '../widgets/share_composer_widgets.dart';
import '../widgets/share_preview_widgets.dart';
import '../widgets/video_content_renderer.dart';

enum ShareDurationPreset { auto, short, medium, long }

extension on ShareDurationPreset {
  int? get maxDurationSeconds => switch (this) {
    ShareDurationPreset.auto => null,
    ShareDurationPreset.short => 30,
    ShareDurationPreset.medium => 60,
    ShareDurationPreset.long => 90,
  };
}

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
  late int _fromAyah;
  late int _toAyah;
  late final int _maxAyah;

  ShareDurationPreset _durationPreset = ShareDurationPreset.auto;
  final Map<int, GlobalKey> _videoBoundaryKeys = {};
  List<VideoPageSpec> _cachedVideoPageSpecs = const [];
  List<ShareReciterOption> _reciterOptions = const <ShareReciterOption>[];
  bool _isLoadingReciters = false;
  bool _singleVideoCaptureSurfaceVisible = false;

  Widget? _backdropWidget;
  bool _videoIsMuted = false;
  late String _currentReciterName;

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
    _currentReciterName = widget.reciterName;
    _cachedVideoPageSpecs = buildVideoPageSpecs(
      surahNumber: widget.surahNumber,
      fromAyah: _fromAyah,
      toAyah: _toAyah,
    );
    _syncVideoBoundaryKeys();
    _backdropWidget = _buildBackdrop();

    context.read<ShareCubit>().configureAudioClip(
      surahNumber: widget.surahNumber,
      fromAyah: _fromAyah,
      toAyah: _toAyah,
      reciterName: widget.reciterName,
      serverUrl: widget.reciterServerUrl,
    );
  }

  void _syncVideoBoundaryKeys() {
    final existingIndices = _videoBoundaryKeys.keys.toSet();
    final requiredIndices = Iterable<int>.generate(
      _cachedVideoPageSpecs.length,
    ).toSet();
    for (final index in existingIndices.difference(requiredIndices)) {
      _videoBoundaryKeys.remove(index);
    }
    for (final index in requiredIndices.difference(existingIndices)) {
      _videoBoundaryKeys[index] = GlobalKey();
    }
  }

  Future<void> _loadReciterOptions() async {
    setState(() => _isLoadingReciters = true);
    final result = await getIt<GetRecitersUseCase>()();
    if (!mounted) return;

    final options = result.fold(
      (_) => const <ShareReciterOption>[],
      (reciters) => buildShareReciterOptions(
        reciters: reciters,
        surahNumber: widget.surahNumber,
        selectedReciterName: widget.reciterName,
        selectedServerUrl: widget.reciterServerUrl,
      ),
    );

    setState(() {
      _reciterOptions = options;
      _isLoadingReciters = false;
    });

    final cubit = context.read<ShareCubit>();
    final state = cubit.state;
    final rName = state.reciterName ?? widget.reciterName;
    final rUrl = state.reciterServerUrl ?? widget.reciterServerUrl;

    final resolvedOption = _preferredFallbackReciterOption(
      options,
      rName,
      rUrl,
    );
    if (resolvedOption != null) {
      if (rName.trim() != resolvedOption.name ||
          rUrl.trim() != resolvedOption.serverUrl) {
        cubit.updateReciter(
          name: resolvedOption.name,
          serverUrl: resolvedOption.serverUrl,
        );
      }
      if (mounted) setState(() => _currentReciterName = resolvedOption.name);
    }
  }

  ShareReciterOption? _preferredFallbackReciterOption(
    List<ShareReciterOption> options,
    String name,
    String url,
  ) {
    for (final o in options) {
      if (matchesShareReciterOption(
        o,
        selectedReciterName: name,
        selectedServerUrl: url,
      )) {
        return o;
      }
    }
    for (final o in options) {
      if (ReciterAudioMapping.resolveFolder(o.serverUrl) ==
          ReciterAudioMapping.defaultReciterFolder) {
        return o;
      }
    }
    return options.isEmpty ? null : options.first;
  }

  Future<void> _showReciterPicker() async {
    if (_reciterOptions.isEmpty && !_isLoadingReciters) {
      await _loadReciterOptions();
    }
    if (!mounted || _reciterOptions.isEmpty) return;

    final cubit = context.read<ShareCubit>();
    final selection = await showModalBottomSheet<ShareReciterOption>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReciterPickerSheet(
        options: _reciterOptions,
        selectedReciterName: cubit.state.reciterName ?? widget.reciterName,
        selectedServerUrl:
            cubit.state.reciterServerUrl ?? widget.reciterServerUrl,
      ),
    );

    if (!mounted || selection == null) {
      return;
    }

    cubit.discardPreparedContent();
    cubit.updateReciter(name: selection.name, serverUrl: selection.serverUrl);
    setState(() {
      _currentReciterName = selection.name;
      _singleVideoCaptureSurfaceVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = context.select<ShareCubit, bool>((cubit) {
      final status = cubit.state.status;
      return status == ShareStatus.capturing ||
          status == ShareStatus.generating ||
          status == ShareStatus.sharing;
    });

    return Stack(
      children: [
        if (_cachedVideoPageSpecs.length > 1 ||
            _singleVideoCaptureSurfaceVisible)
          Offstage(
            offstage: !isBusy,
            child: RepaintBoundary(
              child: _OffScreenRenderers(
                videoBoundaryKeys: _videoBoundaryKeys,
                videoPageSpecs: _cachedVideoPageSpecs,
                surahNumber: widget.surahNumber,
                reciterName: _currentReciterName,
              ),
            ),
          ),
        BlocConsumer<ShareCubit, ShareState>(
          listener: (context, state) {
            if (state.status == ShareStatus.idle && state.content == null) {
              // if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            }
          },
          buildWhen: (prev, curr) =>
              prev.status != curr.status ||
              prev.content != curr.content ||
              prev.errorMessage != curr.errorMessage ||
              prev.reciterName != curr.reciterName,
          builder: (context, state) {
            final isBusy =
                state.status == ShareStatus.capturing ||
                state.status == ShareStatus.generating ||
                state.status == ShareStatus.sharing;

            final isReviewing = state.status == ShareStatus.reviewing;
            final isVideoReview = isReviewing && state.content is ShareVideo;
            final isScreenshotReview =
                isReviewing && state.content is ShareScreenshot;
            final reciterName = state.reciterName ?? widget.reciterName;

            return ImmersiveComposerScaffold(
              title: isReviewing
                  ? context.l10n.shareReadyTitle
                  : context.l10n.shareModeReel,
              subtitle: isReviewing ? null : context.l10n.shareComposerSubtitle,
              onClose: () => Navigator.of(context).maybePop(),
              enableAutoHide: false,
              preview: AnimatedSwitcher(
                duration: Theme.of(context).tokens.durationMedium,
                child: isVideoReview
                    ? _VideoReviewPreview(
                        filePath: (state.content as ShareVideo).filePath,
                        surahName: state.content!.surahName,
                        isMuted: _videoIsMuted,
                        onMuteChanged: (muted) =>
                            setState(() => _videoIsMuted = muted),
                      )
                    : isScreenshotReview
                    ? _ScreenshotReviewPreview(
                        filePath: (state.content as ShareScreenshot).filePath,
                        surahName: state.content!.surahName,
                      )
                    : _buildLivePreview(reciterName),
              ),
              bottomPanel: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _VideoStepIndicator(status: state.status),
                  AnimatedSwitcher(
                    duration: Theme.of(context).tokens.durationFast,
                    child: isReviewing
                        ? _VideoReviewPanel(
                            content: state.content!,
                            onEdit: () => context
                                .read<ShareCubit>()
                                .discardPreparedContent(),
                            onShare: () =>
                                context.read<ShareCubit>().shareContent(),
                          )
                        : _ComposerControls(
                            durationPreset: _durationPreset,
                            fromAyah: _fromAyah,
                            toAyah: _toAyah,
                            maxAyah: _maxAyah,
                            isBusy: isBusy,
                            rangeIsValid: _isValidRange(),
                            reciterName: reciterName,
                            isLoadingReciters: _isLoadingReciters,
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
                            onDurationChanged: (preset) {
                              setState(() => _durationPreset = preset);
                              context
                                  .read<ShareCubit>()
                                  .discardPreparedContent();
                            },
                            onFromChanged: _handleFromAyahChanged,
                            onToChanged: _handleToAyahChanged,
                            onPrimaryAction: () =>
                                _handleGenerateVideo(context),
                            onCancel: () =>
                                context.read<ShareCubit>().cancelGeneration(),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isValidRange() {
    final count = _toAyah - _fromAyah + 1;
    return _fromAyah >= 1 &&
        _toAyah >= _fromAyah &&
        _toAyah <= _maxAyah &&
        count <= ShareLimits.maxVersesPerClip;
  }

  void _handleFromAyahChanged(int v) {
    setState(() {
      _fromAyah = v;
      if (_toAyah < v) _toAyah = v;
      _updateVideoSpecs();
    });
    context.read<ShareCubit>().discardPreparedContent();
  }

  void _handleToAyahChanged(int v) {
    setState(() {
      _toAyah = v;
      if (_fromAyah > v) _fromAyah = v;
      _updateVideoSpecs();
    });
    context.read<ShareCubit>().discardPreparedContent();
  }

  void _updateVideoSpecs() {
    _cachedVideoPageSpecs = buildVideoPageSpecs(
      surahNumber: widget.surahNumber,
      fromAyah: _fromAyah,
      toAyah: _toAyah,
    );
    _syncVideoBoundaryKeys();
    _singleVideoCaptureSurfaceVisible = false;
  }

  Future<void> _handleGenerateVideo(BuildContext context) async {
    if (!_isValidRange()) return;

    final cubit = context.read<ShareCubit>();
    final messages = context.shareProgressMessages;
    final viaLabel = context.l10n.sharedViaTilawa;

    // QCF fonts load on demand from a CDN — preload them before making the
    // offscreen tree visible so FFmpeg doesn't race a font fetch.
    final Set<int> capturePages = <int>{
      for (final spec in _cachedVideoPageSpecs) spec.pageNumber,
    };
    await Future.wait([
      for (final page in capturePages)
        QuranFontService.instance.ensureSingleFontLoaded(page),
    ]);
    if (!mounted) return;

    setState(() => _singleVideoCaptureSurfaceVisible = true);

    // Two end-of-frame awaits: the first commits the Offstage→visible flip
    // and mounts the RepaintBoundary + LayoutBuilder; the second gives
    // `QuranPagePreparationService.preparePage` a frame to populate prepared
    // content before FFmpeg asks for a screenshot.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    cubit.generateVideo(
      surahName: getSurahNameArabic(widget.surahNumber),
      progressMessages: messages,
      appName: 'Tilawa',
      sharedViaLabel: viaLabel,
      boundaryKeys: _videoBoundaryKeys.values.toList(),
      maxDurationSeconds: _durationPreset.maxDurationSeconds,
    );
  }

  Widget? _buildBackdrop() {
    final notifier = widget.readerPreviewBytesNotifier;
    if (notifier == null) return null;
    // Opacity forces a saveLayer each frame. Bake the alpha into the image via
    // modulate blending so the compositor can skip the offscreen pass.
    return RepaintBoundary(
      child: ValueListenableBuilder<Uint8List?>(
        valueListenable: notifier,
        builder: (context, bytes, _) => bytes == null
            ? const SizedBox.shrink()
            : Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                colorBlendMode: BlendMode.modulate,
              ),
      ),
    );
  }

  Widget _buildLivePreview(String reciterName) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wrap(
          //   alignment: WrapAlignment.center,
          //   spacing: tokens.spaceSmall,
          //   runSpacing: tokens.spaceExtraSmall,
          //   children: [
          //     MetadataChip(
          //       icon: Icons.auto_stories_rounded,
          //       label: getSurahNameArabic(widget.surahNumber),
          //       foregroundColor: chipForeground,
          //       backgroundColor: chipBackground,
          //       borderColor: chipBorder,
          //     ),
          //     MetadataChip(
          //       icon: Icons.format_list_numbered_rounded,
          //       label: '$_fromAyah - $_toAyah',
          //       foregroundColor: chipForeground,
          //       backgroundColor: chipBackground,
          //       borderColor: chipBorder,
          //     ),
          //     MetadataChip(
          //       icon: Icons.multitrack_audio_rounded,
          //       label: reciterName,
          //       foregroundColor: chipForeground,
          //       backgroundColor: chipBackground,
          //       borderColor: chipBorder,
          //     ),
          //   ],
          // ),
          // SizedBox(height: tokens.spaceMedium),
          Expanded(
            child: RepaintBoundary(
              child: VideoContentRenderer(
                surahNumber: widget.surahNumber,
                fromAyah: _fromAyah,
                toAyah: _toAyah,
                reciterName: reciterName,
                pageSpecs: _cachedVideoPageSpecs.isEmpty
                    ? null
                    : [_cachedVideoPageSpecs.first],
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

// Internal Boilerplate Widgets (Simplified copy from ShareComposerScreen)
class _OffScreenRenderers extends StatelessWidget {
  const _OffScreenRenderers({
    required this.videoBoundaryKeys,
    required this.videoPageSpecs,
    required this.surahNumber,
    required this.reciterName,
  });
  final Map<int, GlobalKey> videoBoundaryKeys;
  final List<VideoPageSpec> videoPageSpecs;
  final int surahNumber;
  final String reciterName;
  @override
  Widget build(BuildContext context) {
    // Offstage capture surfaces: stack N × 1080×1920 frames vertically without
    // overflow. OverflowBox lets the Column exceed the parent (Scaffold-sized)
    // height budget — the tree is Offstage so nothing paints, but layout would
    // otherwise log overflow for every additional page beyond the first.
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
                // Flags ambient orbs + heavy shadow off for the capture pass.
                // The PNG is downsampled to the target video resolution inside
                // ScreenshotService, so those layers add build cost without any
                // visible difference in the final frame.
                isCapturing: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoStepIndicator extends StatelessWidget {
  const _VideoStepIndicator({required this.status});
  final ShareStatus status;
  @override
  Widget build(BuildContext context) {
    final isBusy =
        status == ShareStatus.capturing ||
        status == ShareStatus.generating ||
        status == ShareStatus.sharing;
    if (!isBusy) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    // Isolate the indeterminate progress animation so its continuous repaint
    // does not invalidate the heavy preview rendered alongside it.
    return RepaintBoundary(
      child: SizedBox(
        height: tokens.progressHeight,
        child: LinearProgressIndicator(
          backgroundColor: theme.colorScheme.surface.withValues(
            alpha: tokens.opacitySubtle,
          ),
          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
        ),
      ),
    );
  }
}

class _VideoReviewPanel extends StatelessWidget {
  const _VideoReviewPanel({
    required this.content,
    required this.onEdit,
    required this.onShare,
  });
  final ShareContent content;
  final VoidCallback onEdit;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceMedium,
      ),
      child: Row(
        spacing: tokens.spaceSmall,
        children: [
          Expanded(
            child: SizedBox(
              height: Theme.of(
                context,
              ).componentTokens.immersiveComposer.headerButtonSize,
              child: OutlinedButton(
                onPressed: onEdit,
                child: Text(context.l10n.edit),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: Theme.of(
                context,
              ).componentTokens.immersiveComposer.headerButtonSize,
              child: FilledButton.icon(
                onPressed: onShare,
                icon: Icon(
                  Icons.share_rounded,
                  size: Theme.of(context).tokens.iconSizeSmall,
                ),
                label: Text(context.l10n.shareReel),
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
    required this.durationPreset,
    required this.fromAyah,
    required this.toAyah,
    required this.maxAyah,
    required this.isBusy,
    required this.rangeIsValid,
    required this.reciterName,
    required this.isLoadingReciters,
    required this.canSelectReciter,
    required this.arabicSurahName,
    this.errorMessage,
    this.progressLabel,
    required this.onReciterTap,
    required this.onDurationChanged,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onPrimaryAction,
    required this.onCancel,
  });
  final ShareDurationPreset durationPreset;
  final int fromAyah, toAyah, maxAyah;
  final bool isBusy, rangeIsValid, isLoadingReciters, canSelectReciter;
  final String reciterName, arabicSurahName;
  final String? errorMessage, progressLabel;
  final VoidCallback onReciterTap, onPrimaryAction, onCancel;
  final ValueChanged<ShareDurationPreset> onDurationChanged;
  final ValueChanged<int> onFromChanged, onToChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    if (isBusy) {
      return Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Text(
          progressLabel ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShareControlsCard(
            children: [
              _ReciterTile(
                reciterName: reciterName,
                isLoading: isLoadingReciters,
                enabled: canSelectReciter,
                onTap: onReciterTap,
              ),
              const ShareTileDivider(),
              _AyahRangeTile(
                fromAyah: fromAyah,
                toAyah: toAyah,
                maxAyah: maxAyah,
                onFromChanged: onFromChanged,
                onToChanged: onToChanged,
              ),
            ],
          ),
          if (errorMessage != null) ...[
            SizedBox(height: tokens.spaceSmall),
            Text(
              errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: tokens.spaceMedium),
          FilledButton.icon(
            onPressed: rangeIsValid ? onPrimaryAction : null,
            icon: const Icon(Icons.movie_creation_rounded),
            label: Text(context.l10n.generateReel),
          ),
        ],
      ),
    );
  }
}

class _ReciterTile extends StatelessWidget {
  const _ReciterTile({
    required this.reciterName,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });
  final String reciterName;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return ShareControlTileShell(
      onTap: enabled ? onTap : null,
      icon: Icons.multitrack_audio_rounded,
      label: context.l10n.reciters,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              reciterName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: tokens.spaceSmall),
          if (isLoading)
            SizedBox(
              width: tokens.iconSizeSmall,
              height: tokens.iconSizeSmall,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              size: tokens.iconSizeMedium,
              color: theme.colorScheme.onSurfaceVariant,
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

class _ReciterPickerSheet extends StatefulWidget {
  const _ReciterPickerSheet({
    required this.options,
    required this.selectedReciterName,
    required this.selectedServerUrl,
  });
  final List<ShareReciterOption> options;
  final String selectedReciterName, selectedServerUrl;
  @override
  State<_ReciterPickerSheet> createState() => _ReciterPickerSheetState();
}

class _ReciterPickerSheetState extends State<_ReciterPickerSheet> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((o) => o.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final tokens = Theme.of(context).tokens;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.8,
      padding: EdgeInsets.all(tokens.spaceLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusExtraLarge),
        ),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(hintText: context.l10n.searchReciters),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final o = filtered[i];
                final sel = matchesShareReciterOption(
                  o,
                  selectedReciterName: widget.selectedReciterName,
                  selectedServerUrl: widget.selectedServerUrl,
                );
                return ListTile(
                  title: Text(o.name),
                  trailing: sel ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(context, o),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenshotReviewPreview extends StatelessWidget {
  const _ScreenshotReviewPreview({
    required this.filePath,
    required this.surahName,
  });
  final String filePath, surahName;
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: GeneratedImagePreview(filePath: filePath),
    );
  }
}

class _VideoReviewPreview extends StatelessWidget {
  const _VideoReviewPreview({
    required this.filePath,
    required this.surahName,
    required this.isMuted,
    required this.onMuteChanged,
  });
  final String filePath, surahName;
  final bool isMuted;
  final ValueChanged<bool> onMuteChanged;
  @override
  Widget build(BuildContext context) {
    return _GeneratedVideoPreview(
      filePath: filePath,
      isMuted: isMuted,
      onMuteChanged: onMuteChanged,
    );
  }
}

class _GeneratedVideoPreview extends StatefulWidget {
  const _GeneratedVideoPreview({
    required this.filePath,
    required this.isMuted,
    required this.onMuteChanged,
  });
  final String filePath;
  final bool isMuted;
  final ValueChanged<bool> onMuteChanged;
  @override
  State<_GeneratedVideoPreview> createState() => _GeneratedVideoPreviewState();
}

class _GeneratedVideoPreviewState extends State<_GeneratedVideoPreview> {
  VideoPlayerController? _controller;
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _controller = VideoPlayerController.file(File(widget.filePath));
    await _controller!.initialize();
    await _controller!.setLooping(true);
    await _controller!.setVolume(widget.isMuted ? 0 : 1);
    await _controller!.play();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
