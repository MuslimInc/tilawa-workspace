import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:quran/quran.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/logger.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:video_player/video_player.dart';

import '../../../reciters/domain/usecases/get_reciters_use_case.dart';
import '../../data/services/reciter_audio_mapping.dart';
import '../../domain/entities/share_content.dart';
import '../../domain/entities/share_limits.dart';
import '../cubit/share_cubit.dart';
import '../cubit/share_state.dart';
import '../share_progress_messages_l10n.dart';
import '../utils/quran_share_text_formatter.dart';
import '../utils/reel_page_specs.dart';
import '../utils/share_ayah_range_utils.dart';
import '../utils/share_reciter_options.dart';
import '../widgets/page_passage_card_renderer.dart';
import '../widgets/reader_page_content_renderer.dart';
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
    this.readerPreviewBytesNotifier,
  });

  final int surahNumber;
  final int currentPage;
  final int initialFromAyah;
  final int initialToAyah;
  final String reciterName;
  final String reciterServerUrl;
  final GlobalKey readerBoundaryKey;

  /// Notifier that delivers the blurred backdrop preview bytes asynchronously
  /// so the route push is not blocked by GPU readback + PNG encoding.
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
              readerPreviewBytesNotifier: readerPreviewBytesNotifier,
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
  final GlobalKey _readerPageBoundaryKey = GlobalKey();
  final List<GlobalKey> _reelBoundaryKeys = <GlobalKey>[];
  List<ShareReciterOption> _reciterOptions = const <ShareReciterOption>[];
  bool _isLoadingReciters = false;
  Future<void>? _reciterOptionsLoadTask;
  bool _singleReelCaptureSurfaceVisible = false;

  // Cached reel page specs — recomputed only when fromAyah/toAyah change, not
  // on every bloc emission. Previously this getter was called on each
  // BlocConsumer rebuild (including every progress tick), wasting CPU.
  late List<ReelPageSpec> _cachedReelPageSpecs;

  // Stable backdrop widget — built once and reused. Previously _buildBackdrop()
  // was called inside BlocConsumer.builder, allocating a new widget instance on
  // every ShareCubit emission.
  Widget? _backdropWidget;

  // Mirrors the cubit's effective reciter name so off-screen renderers (which
  // live outside BlocConsumer) can reflect reciter changes without needing to
  // read bloc state from a StatelessWidget.
  late String _currentReciterName;

  @override
  void initState() {
    final int tInit = DateTime.now().millisecondsSinceEpoch;
    logger.d(
      '[SHARE_SCREEN] initState start | surah=${widget.surahNumber} page=${widget.currentPage} | t=${tInit}ms',
    );
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
    _cachedReelPageSpecs = _buildReelPageSpecs();
    _syncReelBoundaryKeys();
    _backdropWidget = _buildBackdrop();

    context.read<ShareCubit>().configureAudioClip(
      surahNumber: widget.surahNumber,
      fromAyah: _fromAyah,
      toAyah: _toAyah,
      reciterName: widget.reciterName,
      serverUrl: widget.reciterServerUrl,
      boundaryKey: widget.readerBoundaryKey,
    );

    logger.d(
      '[SHARE_SCREEN] initState complete | took=${DateTime.now().millisecondsSinceEpoch - tInit}ms',
    );
  }

  String get _surahName => context.l10n.localeName == 'ar'
      ? getSurahNameArabic(widget.surahNumber)
      : getSurahNameEnglish(widget.surahNumber);

  String get _arabicSurahName => getSurahNameArabic(widget.surahNumber);

  int get _verseCount => _toAyah - _fromAyah + 1;

  List<int> get _currentPageSurahNumbers {
    final List<int> surahNumbers = <int>[];
    for (final Map<String, int?> entry in getPageData(widget.currentPage)) {
      final int? surahNumber = entry['surah'];
      if (surahNumber == null || surahNumbers.contains(surahNumber)) {
        continue;
      }
      surahNumbers.add(surahNumber);
    }
    return surahNumbers;
  }

  bool get _hasMultipleSurahsOnPage => _currentPageSurahNumbers.length > 1;

  bool get _usesPagePassageCard =>
      _mode == ShareComposerMode.screenshot &&
      _screenshotLayout == ShareScreenshotLayout.passageCard &&
      _hasMultipleSurahsOnPage;

  String get _currentPageArabicSurahNames =>
      _currentPageSurahNumbers.map(getSurahNameArabic).join(' • ');

  String get _currentPageEnglishSurahNames =>
      _currentPageSurahNumbers.map(getSurahNameEnglish).join(' • ');

  String get _effectivePreviewArabicSurahName =>
      _usesPagePassageCard ? _currentPageArabicSurahNames : _arabicSurahName;

  String get _effectiveShareSurahName => _usesPagePassageCard
      ? (context.l10n.localeName == 'ar'
            ? _currentPageArabicSurahNames
            : _currentPageEnglishSurahNames)
      : _surahName;

  String get _effectiveShareArabicSurahName =>
      _usesPagePassageCard ? _currentPageArabicSurahNames : _arabicSurahName;

  List<ReelPageSpec> _buildReelPageSpecs() => buildReelPageSpecs(
    surahNumber: widget.surahNumber,
    fromAyah: _fromAyah,
    toAyah: _toAyah,
  );

  bool get _hasLogicalRange =>
      _fromAyah >= 1 && _toAyah >= _fromAyah && _toAyah <= _maxAyah;

  bool get _enforcesVerseLimit => _mode != ShareComposerMode.screenshot;

  bool get _isValidRange =>
      _hasLogicalRange &&
      (!_enforcesVerseLimit || _verseCount <= ShareLimits.maxVersesPerClip);

  void _syncReelBoundaryKeys() {
    final int requiredCount = _cachedReelPageSpecs.length;

    while (_reelBoundaryKeys.length < requiredCount) {
      _reelBoundaryKeys.add(GlobalKey());
    }

    if (_reelBoundaryKeys.length > requiredCount) {
      _reelBoundaryKeys.removeRange(requiredCount, _reelBoundaryKeys.length);
    }
  }

  Future<void> _loadReciterOptions() async {
    setState(() => _isLoadingReciters = true);

    final result = await getIt<GetRecitersUseCase>()();
    if (!mounted) return;

    final List<ShareReciterOption> options = result.fold(
      (_) => const <ShareReciterOption>[],
      (List<ReciterEntity> reciters) => buildShareReciterOptions(
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

    final ShareCubit cubit = context.read<ShareCubit>();
    final ShareState currentState = cubit.state;
    final String currentReciterName =
        currentState.reciterName ?? widget.reciterName;
    final String currentReciterServerUrl =
        currentState.reciterServerUrl ?? widget.reciterServerUrl;
    ShareReciterOption? resolvedOption;
    for (final ShareReciterOption option in options) {
      if (matchesShareReciterOption(
        option,
        selectedReciterName: currentReciterName,
        selectedServerUrl: currentReciterServerUrl,
      )) {
        resolvedOption = option;
        break;
      }
    }

    resolvedOption ??= _preferredFallbackReciterOption(options);
    if (resolvedOption == null) {
      return;
    }

    final bool hasExactSelection =
        currentReciterName.trim() == resolvedOption.name &&
        currentReciterServerUrl.trim() == resolvedOption.serverUrl;
    if (!hasExactSelection) {
      cubit.updateReciter(
        name: resolvedOption.name,
        serverUrl: resolvedOption.serverUrl,
      );
    }
    if (mounted) {
      setState(() => _currentReciterName = resolvedOption!.name);
    }
  }

  Future<void> _ensureReciterOptionsLoaded() {
    if (_reciterOptions.isNotEmpty || _isLoadingReciters) {
      return _reciterOptionsLoadTask ?? Future<void>.value();
    }

    return _reciterOptionsLoadTask ??= _loadReciterOptions().whenComplete(() {
      _reciterOptionsLoadTask = null;
    });
  }

  ShareReciterOption? _preferredFallbackReciterOption(
    List<ShareReciterOption> options,
  ) {
    for (final ShareReciterOption option in options) {
      if (ReciterAudioMapping.resolveFolder(option.serverUrl) ==
          ReciterAudioMapping.defaultReciterFolder) {
        return option;
      }
    }
    return options.isEmpty ? null : options.first;
  }

  Future<void> _showReciterPicker() async {
    await _ensureReciterOptionsLoaded();
    if (!mounted || _reciterOptions.isEmpty) {
      return;
    }

    final ShareCubit cubit = context.read<ShareCubit>();
    final ShareState currentState = cubit.state;
    final ShareReciterOption? selection =
        await showModalBottomSheet<ShareReciterOption>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _ReciterPickerSheet(
            options: _reciterOptions,
            selectedReciterName: currentState.reciterName ?? widget.reciterName,
            selectedServerUrl:
                currentState.reciterServerUrl ?? widget.reciterServerUrl,
          ),
        );

    if (!mounted || selection == null) {
      return;
    }

    cubit.discardPreparedContent();
    cubit.updateReciter(name: selection.name, serverUrl: selection.serverUrl);
    setState(() {
      _currentReciterName = selection.name;
      _singleReelCaptureSurfaceVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Off-screen capture renderers and the backdrop are independent of
    // ShareCubit state — hoisted outside BlocConsumer so they are not
    // rebuilt on every cubit emission (progress ticks, reciter updates, etc.).
    return Stack(
      children: [
        if (_mode == ShareComposerMode.reel &&
            (_cachedReelPageSpecs.length > 1 ||
                _singleReelCaptureSurfaceVisible))
          _OffScreenRenderers(
            reelBoundaryKeys: _reelBoundaryKeys,
            reelPageSpecs: _cachedReelPageSpecs,
            surahNumber: widget.surahNumber,
            reciterName: _currentReciterName,
          ),

        // --- Main composer UI driven by ShareCubit ---
        BlocConsumer<ShareCubit, ShareState>(
          listenWhen: (previous, current) =>
              previous.status == ShareStatus.sharing &&
              current.status == ShareStatus.idle &&
              current.content == null,
          listener: (context, state) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          // Skip rebuilds that only change progressMessage/progress during
          // generation — the progress strip reads directly from state so it
          // still updates, but the heavy scaffold subtree is not re-laid-out.
          buildWhen: (previous, current) {
            // Always rebuild on status transitions.
            if (previous.status != current.status) {
              logger.d(
                '[SHARE_REBUILD] buildWhen=true | reason=status ${previous.status}→${current.status}',
              );
              return true;
            }
            // Always rebuild when content or reciter changes.
            if (previous.content != current.content) {
              logger.d(
                '[SHARE_REBUILD] buildWhen=true | reason=content changed',
              );
              return true;
            }
            if (previous.reciterName != current.reciterName) {
              logger.d(
                '[SHARE_REBUILD] buildWhen=true | reason=reciterName changed',
              );
              return true;
            }
            if (previous.reciterServerUrl != current.reciterServerUrl) {
              logger.d(
                '[SHARE_REBUILD] buildWhen=true | reason=reciterServerUrl changed',
              );
              return true;
            }
            if (previous.errorMessage != current.errorMessage) {
              logger.d(
                '[SHARE_REBUILD] buildWhen=true | reason=errorMessage changed',
              );
              return true;
            }
            // Skip rebuilds that only carry a progress message update.
            logger.d(
              '[SHARE_REBUILD] buildWhen=false | skipped progress-only emit | msg="${current.progressMessage}"',
            );
            return false;
          },
          builder: (context, state) {
            final isBusy =
                state.status == ShareStatus.capturing ||
                state.status == ShareStatus.generating ||
                state.status == ShareStatus.sharing;
            final isReviewing =
                state.status == ShareStatus.reviewing && state.content != null;
            final reviewContent = isReviewing ? state.content! : null;
            final isReelReview = reviewContent is ShareReel;
            final theme = Theme.of(context);
            final tokens = theme.tokens;
            final reciterName = state.reciterName ?? widget.reciterName;

            return ImmersiveComposerScaffold(
              title: isReviewing
                  ? context.l10n.shareReadyTitle
                  : context.l10n.createShare,
              subtitle: isReviewing
                  ? (isReelReview ? null : context.l10n.shareReviewSubtitle)
                  : context.l10n.shareComposerSubtitle,
              onClose: () => Navigator.of(context).maybePop(),
              background: _backdropWidget,
              backgroundGradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0C302B),
                  Color(0xFF164B42),
                  Color(0xFF1E5D52),
                ],
              ),
              compactPanelHeightFactor: isReelReview ? 0.32 : null,
              regularPanelHeightFactor: isReelReview ? 0.28 : null,
              compactPreviewHeightFactor: isReelReview ? 0.56 : null,
              regularPreviewHeightFactor: isReelReview ? 0.7 : null,
              panelMinHeight: isReelReview ? 156 : null,
              previewMaxHeight: isReelReview ? 640 : null,
              preview: AnimatedSwitcher(
                duration: tokens.durationMedium,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: isReviewing
                    ? _buildReviewPreview(reviewContent!)
                    : _buildLivePreview(reciterName),
              ),
              bottomPanel: AnimatedSwitcher(
                duration: tokens.durationFast,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: isReviewing
                    ? _ReviewPanel(
                        key: const ValueKey('review_panel'),
                        content: reviewContent!,
                        compact: isReelReview,
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
                        reciterName: reciterName,
                        isLoadingReciters: _isLoadingReciters,
                        canSelectReciter: _reciterOptions.isNotEmpty,
                        arabicSurahName: _effectivePreviewArabicSurahName,
                        currentPage: widget.currentPage,
                        showVerseRangeControls: !_usesPagePassageCard,
                        errorMessage: state.status == ShareStatus.error
                            ? state.errorMessage
                            : null,
                        progressLabel: _progressLabelForState(context, state),
                        onReciterTap: _showReciterPicker,
                        onModeChanged: (mode) {
                          setState(() {
                            _mode = mode;
                            _singleReelCaptureSurfaceVisible = false;
                          });
                          if (mode != ShareComposerMode.screenshot) {
                            unawaited(_ensureReciterOptionsLoaded());
                          }
                          context.read<ShareCubit>().discardPreparedContent();
                        },
                        onLayoutChanged: (layout) {
                          setState(() {
                            _screenshotLayout = layout;
                            _singleReelCaptureSurfaceVisible = false;
                          });
                          context.read<ShareCubit>().discardPreparedContent();
                        },
                        onDurationChanged: (preset) {
                          setState(() {
                            _durationPreset = preset;
                            _singleReelCaptureSurfaceVisible = false;
                          });
                          context.read<ShareCubit>().discardPreparedContent();
                        },
                        onFromChanged: _handleFromAyahChanged,
                        onToChanged: _handleToAyahChanged,
                        onPrimaryAction: _handlePrimaryAction,
                        onShareText: () =>
                            _handleShareText(reciterName: reciterName),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget? _buildBackdrop() {
    final notifier = widget.readerPreviewBytesNotifier;
    if (notifier == null) return null;

    return ValueListenableBuilder<Uint8List?>(
      valueListenable: notifier,
      builder: (context, bytes, _) {
        if (bytes == null) return const SizedBox.shrink();
        return Opacity(
          opacity: 0.16,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        );
      },
    );
  }

  Widget _buildLivePreview(String reciterName) {
    final TextDirection textDirection = Directionality.of(context);

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
                ShareComposerMode.screenshot => _buildScreenshotPreview(
                  reciterName: reciterName,
                  uiTextDirection: textDirection,
                ),
                ShareComposerMode.audio => _AudioArtworkPreview(
                  surahNumber: widget.surahNumber,
                  fromAyah: _fromAyah,
                  toAyah: _toAyah,
                  reciterName: reciterName,
                  durationPreset: _durationPreset,
                ),
                ShareComposerMode.reel => _buildReelPreview(
                  reciterName: reciterName,
                ),
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenshotPreview({
    required String reciterName,
    required TextDirection uiTextDirection,
  }) {
    if (_screenshotLayout == ShareScreenshotLayout.readerPage) {
      return RepaintBoundary(
        key: _readerPageBoundaryKey,
        child: ReaderPageContentRenderer(
          pageNumber: widget.currentPage,
          uiTextDirection: uiTextDirection,
        ),
      );
    }

    return RepaintBoundary(
      key: _posterBoundaryKey,
      child: _usesPagePassageCard
          ? PagePassageCardRenderer(
              pageNumber: widget.currentPage,
              arabicSurahNames: _currentPageArabicSurahNames,
              englishSurahNames: _currentPageEnglishSurahNames,
              reciterName: reciterName,
              uiTextDirection: uiTextDirection,
            )
          : SharePosterRenderer(
              surahNumber: widget.surahNumber,
              fromAyah: _fromAyah,
              toAyah: _toAyah,
              reciterName: reciterName,
            ),
    );
  }

  Widget _buildReelPreview({required String reciterName}) {
    return ReelContentRenderer(
      surahNumber: widget.surahNumber,
      fromAyah: _fromAyah,
      toAyah: _toAyah,
      reciterName: reciterName,
      pageSpecs: _cachedReelPageSpecs,
    );
  }

  Widget _buildReviewPreview(ShareContent content) {
    final reviewKey = switch (content) {
      ShareScreenshot(:final filePath) => ValueKey('review_image_$filePath'),
      ShareAudioClip(:final filePath) => ValueKey('review_audio_$filePath'),
      ShareReel(:final filePath) => ValueKey('review_reel_$filePath'),
      ShareText() => const ValueKey('review_text'),
    };

    if (content case ShareReel(:final filePath, :final surahName)) {
      return _ReelReviewPreview(
        key: reviewKey,
        filePath: filePath,
        surahName: surahName,
      );
    }

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
              ShareReel() => const SizedBox.shrink(),
              ShareText(:final text) => _PreviewFrame(
                aspectRatio: 4 / 5,
                child: Container(
                  color: const Color(0xFFF7F1E1),
                  padding: const EdgeInsets.all(48),
                  alignment: Alignment.center,
                  child: Text(
                    text,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF0B342E),
                      height: 1.5,
                    ),
                  ),
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
    final progressMessages = context.shareProgressMessages;
    final appName = context.l10n.appTitle;
    final sharedViaLabel = context.l10n.sharedViaTilawa;

    switch (_mode) {
      case ShareComposerMode.screenshot:
        final useReaderCapture =
            _screenshotLayout == ShareScreenshotLayout.readerPage;
        await cubit.prepareScreenshot(
          boundaryKey: useReaderCapture
              ? _readerPageBoundaryKey
              : _posterBoundaryKey,
          surahName: _effectiveShareSurahName,
          pageNumber: widget.currentPage,
          appName: appName,
          sharedViaLabel: sharedViaLabel,
          preparingImageLabel: progressMessages.preparingImage,
          brandCapture: useReaderCapture,
        );
        return;
      case ShareComposerMode.audio:
        await _ensureReciterOptionsLoaded();
        await cubit.prepareAudioClip(
          surahName: _surahName,
          progressMessages: progressMessages,
          maxDurationSeconds: _durationPreset.maxDurationSeconds,
        );
        return;
      case ShareComposerMode.reel:
        await _ensureReciterOptionsLoaded();
        final bool requiresSingleCaptureSurface =
            _cachedReelPageSpecs.length == 1;
        if (requiresSingleCaptureSurface &&
            !_singleReelCaptureSurfaceVisible &&
            mounted) {
          setState(() => _singleReelCaptureSurfaceVisible = true);
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted) {
            return;
          }
        }
        try {
          await cubit.generateReel(
            surahName: _surahName,
            progressMessages: progressMessages,
            appName: appName,
            sharedViaLabel: sharedViaLabel,
            boundaryKeys: _reelBoundaryKeys,
            maxDurationSeconds: _durationPreset.maxDurationSeconds,
          );
        } finally {
          if (requiresSingleCaptureSurface &&
              mounted &&
              _singleReelCaptureSurfaceVisible) {
            setState(() => _singleReelCaptureSurfaceVisible = false);
          }
        }
        return;
    }
  }

  void _handleFromAyahChanged(int value) {
    setState(() {
      _fromAyah = value;
      if (_toAyah < _fromAyah) {
        _toAyah = _fromAyah;
      }
      _syncReelBoundaryKeys();
      _singleReelCaptureSurfaceVisible = false;
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
      _syncReelBoundaryKeys();
      _singleReelCaptureSurfaceVisible = false;
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

  Future<void> _handleShareText({required String reciterName}) {
    final kind = switch (_mode) {
      ShareComposerMode.screenshot =>
        _screenshotLayout == ShareScreenshotLayout.readerPage ||
                _usesPagePassageCard
            ? QuranShareTextKind.screenshotPage
            : QuranShareTextKind.screenshotPassage,
      ShareComposerMode.audio => QuranShareTextKind.audio,
      ShareComposerMode.reel => QuranShareTextKind.reel,
    };

    final text = buildQuranShareText(
      l10n: context.l10n,
      surahName: _effectiveShareSurahName,
      arabicSurahName: _effectiveShareArabicSurahName,
      kind: kind,
      currentPage: widget.currentPage,
      fromAyah: _fromAyah,
      toAyah: _toAyah,
      reciterName: _mode == ShareComposerMode.screenshot ? null : reciterName,
    );

    return context.read<ShareCubit>().shareText(text, surahName: _surahName);
  }
}

/// Holds off-screen capture surfaces for reel export.
///
/// Extracted from `_ShareComposerScreenState.build()` so it lives outside
/// [BlocConsumer] and is not rebuilt on every [ShareCubit] emission. The state
/// parent rebuilds this widget only when ayah range, reciter, or page changes —
/// not on progress ticks.
class _OffScreenRenderers extends StatelessWidget {
  const _OffScreenRenderers({
    required this.reelBoundaryKeys,
    required this.reelPageSpecs,
    required this.surahNumber,
    required this.reciterName,
  });

  final List<GlobalKey> reelBoundaryKeys;
  final List<ReelPageSpec> reelPageSpecs;
  final int surahNumber;
  final String reciterName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Reel page capture surfaces
        for (int index = 0; index < reelPageSpecs.length; index++)
          Positioned(
            left: -3000 - (index * 1200),
            top: -3000,
            child: RepaintBoundary(
              key: reelBoundaryKeys[index],
              child: ReelContentPage(
                surahNumber: surahNumber,
                pageSpec: reelPageSpecs[index],
                pageIndex: index,
                totalPages: reelPageSpecs.length,
                reciterName: reciterName,
              ),
            ),
          ),
      ],
    );
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
    required this.isLoadingReciters,
    required this.canSelectReciter,
    required this.arabicSurahName,
    required this.currentPage,
    required this.showVerseRangeControls,
    required this.errorMessage,
    required this.progressLabel,
    required this.onReciterTap,
    required this.onModeChanged,
    required this.onLayoutChanged,
    required this.onDurationChanged,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onPrimaryAction,
    required this.onShareText,
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
  final bool isLoadingReciters;
  final bool canSelectReciter;
  final String arabicSurahName;
  final int currentPage;
  final bool showVerseRangeControls;
  final String? errorMessage;
  final String? progressLabel;
  final Future<void> Function() onReciterTap;
  final ValueChanged<ShareComposerMode> onModeChanged;
  final ValueChanged<ShareScreenshotLayout> onLayoutChanged;
  final ValueChanged<ShareDurationPreset> onDurationChanged;
  final ValueChanged<int> onFromChanged;
  final ValueChanged<int> onToChanged;
  final Future<void> Function() onPrimaryAction;
  final Future<void> Function() onShareText;

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
        if (showVerseRangeControls &&
            (mode != ShareComposerMode.screenshot ||
                screenshotLayout == ShareScreenshotLayout.passageCard)) ...[
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
          TilawaSectionTitle(title: context.l10n.reciters),
          const SizedBox(height: 10),
          _ReciterSelectorButton(
            reciterName: reciterName,
            isLoading: isLoadingReciters,
            enabled: !isBusy && canSelectReciter,
            onTap: onReciterTap,
          ),
          if (!isLoadingReciters && !canSelectReciter) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.reciterInfoNotAvailable,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: isBusy || !rangeIsValid ? null : () => onShareText(),
          icon: const Icon(Icons.text_snippet_outlined),
          label: Text(context.l10n.shareAsText),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(
              color: const Color(0xFFE1C17B).withValues(alpha: 0.6),
            ),
            foregroundColor: const Color(0xFFF7F1E1),
            textStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
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

class _ReciterSelectorButton extends StatelessWidget {
  const _ReciterSelectorButton({
    required this.reciterName,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  final String reciterName;
  final bool isLoading;
  final bool enabled;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return OutlinedButton(
      onPressed: enabled ? () => onTap() : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.multitrack_audio_rounded, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reciterName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF7F1E1),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.expand_more_rounded),
        ],
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
  final String selectedReciterName;
  final String selectedServerUrl;

  @override
  State<_ReciterPickerSheet> createState() => _ReciterPickerSheetState();
}

class _ReciterPickerSheetState extends State<_ReciterPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<ShareReciterOption> get _filteredOptions {
    final String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.options;
    }

    return widget.options
        .where((option) => option.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<ShareReciterOption> filteredOptions = _filteredOptions;

    return FractionallySizedBox(
      heightFactor: 0.84,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 12),
                const TilawaSheetHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.recitersList,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: context.l10n.close,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: TilawaSearchField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    hintText: context.l10n.searchReciters,
                    onChanged: (_) => setState(() {}),
                    onClear: () => setState(_searchController.clear),
                    onTapOutside: (_) => _searchFocusNode.unfocus(),
                    showShadow: true,
                    borderRadius: BorderRadius.circular(18),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                Expanded(
                  child: filteredOptions.isEmpty
                      ? Center(
                          child: Text(
                            context.l10n.noResultsFound,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          itemCount: filteredOptions.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final ShareReciterOption option =
                                filteredOptions[index];
                            final bool isSelected = matchesShareReciterOption(
                              option,
                              selectedReciterName: widget.selectedReciterName,
                              selectedServerUrl: widget.selectedServerUrl,
                            );

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => Navigator.of(context).pop(option),
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: isSelected
                                        ? const Color(
                                            0xFFE1C17B,
                                          ).withValues(alpha: 0.18)
                                        : theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFE1C17B)
                                          : theme.colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          option.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle_rounded
                                            : Icons.chevron_right_rounded,
                                        color: isSelected
                                            ? const Color(0xFF0B342E)
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    super.key,
    required this.content,
    required this.onEdit,
    required this.onShare,
    this.compact = false,
  });

  final ShareContent content;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = compact
        ? switch (content) {
            ShareScreenshot() => context.l10n.shareReviewScreenshot,
            ShareAudioClip() => context.l10n.shareReviewAudio,
            ShareReel() => context.l10n.shareReviewReel,
            ShareText() => context.l10n.shareAsText,
          }
        : context.l10n.shareReviewTitle;
    final subtitle = switch (content) {
      ShareScreenshot() => context.l10n.shareReviewScreenshot,
      ShareAudioClip() => context.l10n.shareReviewAudio,
      ShareReel() => context.l10n.shareReviewReel,
      ShareText() => context.l10n.shareAsText,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        SizedBox(height: compact ? 12 : 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: compact ? 14 : 16),
                ),
                child: Text(
                  context.l10n.edit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded),
                label: Text(
                  switch (content) {
                    ShareScreenshot() => context.l10n.shareScreenshot,
                    ShareAudioClip() => context.l10n.shareAudio,
                    ShareReel() => context.l10n.shareReel,
                    ShareText() => context.l10n.shareAsText,
                  },
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: compact ? 14 : 16),
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
  const _MediaPreviewFrame({
    required this.aspectRatio,
    required this.child,
    this.padding = 14,
  });

  final double aspectRatio;
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 460, maxHeight: 760),
      padding: EdgeInsets.all(padding),
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

class _ReelReviewPreview extends StatelessWidget {
  const _ReelReviewPreview({
    super.key,
    required this.filePath,
    required this.surahName,
  });

  final String filePath;
  final String surahName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment.center,
          child: _MediaPreviewFrame(
            aspectRatio: 9 / 16,
            padding: 8,
            child: _GeneratedReelPreview(
              key: ValueKey('generated_reel_surface_$filePath'),
              filePath: filePath,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Wrap(
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
                  label: surahName,
                  foregroundColor: const Color(0xFFF7F1E1),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  borderColor: Colors.white.withValues(alpha: 0.12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
  String? _errorMessage;
  bool _isMuted = false;

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
      await controller.play();
    } catch (error) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
      return;
    }

    _videoPlayerController = controller;
    if (mounted) {
      setState(() {
        _errorMessage = null;
        _isMuted = false;
      });
    }
  }

  Future<void> _disposeControllers() async {
    final videoPlayerController = _videoPlayerController;
    _videoPlayerController = null;
    await videoPlayerController?.pause();
    await videoPlayerController?.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final controller = _videoPlayerController;
    if (controller == null) return;

    final value = controller.value;
    final isCompleted =
        value.duration > Duration.zero && value.position >= value.duration;

    if (isCompleted) {
      await controller.seekTo(Duration.zero);
      await controller.play();
      return;
    }

    if (value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  Future<void> _toggleMute() async {
    final controller = _videoPlayerController;
    if (controller == null) return;

    final nextMuted = !_isMuted;
    await controller.setVolume(nextMuted ? 0 : 1);
    if (!mounted) return;
    setState(() {
      _isMuted = nextMuted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoPlayerController;
    final theme = Theme.of(context);
    final tokens = theme.tokens;

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

    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black12,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final videoSize = value.size.isEmpty
            ? const Size(1080, 1920)
            : value.size;
        final isCompleted =
            value.duration > Duration.zero && value.position >= value.duration;

        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: videoSize.width,
                  height: videoSize.height,
                  child: VideoPlayer(controller),
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
                      Colors.black.withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.48),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _togglePlayback,
                  splashColor: Colors.white.withValues(alpha: 0.08),
                  highlightColor: Colors.transparent,
                ),
              ),
            ),
            if (value.isBuffering)
              const Center(child: CircularProgressIndicator()),
            Positioned(
              top: tokens.spaceMedium,
              right: tokens.spaceMedium,
              child: _PreviewOverlayButton(
                icon: _isMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                onPressed: _toggleMute,
                diameter: tokens.iconSizeLarge * 1.6,
              ),
            ),
            Center(
              child: _PreviewOverlayButton(
                icon: isCompleted
                    ? Icons.replay_rounded
                    : value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                onPressed: _togglePlayback,
                diameter: tokens.iconSizeLarge * 2.2,
                iconSize: tokens.iconSizeLarge * 1.2,
                backgroundColor: const Color(
                  0xFF0B342E,
                ).withValues(alpha: 0.82),
                foregroundColor: const Color(0xFFE1C17B),
              ),
            ),
            Positioned(
              left: tokens.spaceMedium,
              right: tokens.spaceMedium,
              bottom: tokens.spaceMedium,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radiusSmall),
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  padding: EdgeInsets.zero,
                  colors: VideoProgressColors(
                    playedColor: const Color(0xFFE1C17B),
                    bufferedColor: Colors.white.withValues(alpha: 0.22),
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
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

class _PreviewOverlayButton extends StatelessWidget {
  const _PreviewOverlayButton({
    required this.icon,
    required this.onPressed,
    required this.diameter,
    this.iconSize,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double diameter;
  final double? iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            backgroundColor ?? const Color(0xFF0B342E).withValues(alpha: 0.72),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: tokens.blurShadow,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: iconSize ?? tokens.iconSizeMedium,
        color: foregroundColor ?? Colors.white,
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
