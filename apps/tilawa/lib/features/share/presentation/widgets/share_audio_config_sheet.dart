import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:tilawa/core/extensions.dart';

import '../../data/services/audio_clip_service.dart';
import '../../domain/entities/share_content.dart';
import '../cubit/share_cubit.dart';
import '../cubit/share_state.dart';
import 'reel_content_renderer.dart';

/// Bottom sheet for configuring and generating an audio clip to share.
///
/// Shows verse range pickers, a reciter selector, and a generate button
/// with progress tracking.
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
  late int _maxAyah;
  final GlobalKey _reelContentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fromAyah = widget.initialFromAyah;
    _toAyah = widget.initialToAyah;
    _maxAyah = getVerseCount(widget.surahNumber);

    // Configure the cubit with initial values.
    context.read<ShareCubit>().configureAudioClip(
      surahNumber: widget.surahNumber,
      fromAyah: _fromAyah,
      toAyah: _toAyah,
      reciterName: widget.reciterName,
      serverUrl: widget.reciterServerUrl,
      boundaryKey: widget.boundaryKey,
    );
  }

  String get _surahName =>
      context.l10n.localeName == 'ar'
          ? getSurahNameArabic(widget.surahNumber)
          : getSurahNameEnglish(widget.surahNumber);

  int get _verseCount => _toAyah - _fromAyah + 1;

  bool get _isValid =>
      _fromAyah >= 1 &&
      _toAyah >= _fromAyah &&
      _toAyah <= _maxAyah &&
      _verseCount <= AudioClipService.maxVerses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<ShareCubit, ShareState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == ShareStatus.idle &&
          current.content == null,
      listener: (context, state) {
        // Sharing completed or cancelled — close sheet.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final isGenerating = state.status == ShareStatus.generating;
        final isSharing = state.status == ShareStatus.sharing;
        final hasError = state.status == ShareStatus.error;

        return Stack(
          children: [
            // Off-screen renderer for reel content capture
            Positioned(
              left: -2000,
              top: 0,
              child: RepaintBoundary(
                key: _reelContentKey,
                child: ReelContentRenderer(
                  surahNumber: widget.surahNumber,
                  fromAyah: _fromAyah,
                  toAyah: _toAyah,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Title
                      Text(
                        context.l10n.shareAudioClip,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_surahName  •  ${widget.reciterName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Verse range pickers
                      Row(
                        children: [
                          Expanded(
                            child: _VerseDropdown(
                              label: context.l10n.fromAyah,
                              value: _fromAyah,
                              max: _toAyah,
                              min: 1,
                              enabled: !isGenerating && !isSharing,
                              onChanged: (v) {
                                setState(() => _fromAyah = v);
                                context.read<ShareCubit>().updateVerseRange(
                                  fromAyah: v,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _VerseDropdown(
                              label: context.l10n.toAyah,
                              value: _toAyah,
                              max: _maxAyah,
                              min: _fromAyah,
                              enabled: !isGenerating && !isSharing,
                              onChanged: (v) {
                                setState(() => _toAyah = v);
                                context.read<ShareCubit>().updateVerseRange(
                                  toAyah: v,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Verse count info
                      if (_verseCount > AudioClipService.maxVerses)
                        Text(
                          context.l10n.maxVersesExceeded(AudioClipService.maxVerses),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        )
                      else
                        Text(
                          '${context.l10n.verses}: $_verseCount',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Progress indicator
                      if (isGenerating) ...[
                        LinearProgressIndicator(value: state.progress),
                        const SizedBox(height: 8),
                        Text(
                          state.progressMessage,
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {
                            context.read<ShareCubit>().cancelGeneration();
                          },
                          child: Text(context.l10n.cancel),
                        ),
                      ] else if (state.status == ShareStatus.reviewing && state.content is ShareReel) ...[
                        // Reel preview
                        _ReelPreview(
                          filePath: state.content!.filePath,
                          onShare: () => context.read<ShareCubit>().shareContent(),
                        ),
                      ] else if (isSharing) ...[
                        const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.sharing,
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        // Error message
                        if (hasError && state.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              state.errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isValid
                                    ? () {
                                  context.read<ShareCubit>().generateAndShareAudioClip(
                                    surahName: _surahName,
                                  );
                                }
                                    : null,
                                icon: const Icon(Icons.audiotrack),
                                label: Text(context.l10n.shareAudio),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _isValid
                                    ? () {
                                  context.read<ShareCubit>().generateReel(
                                    surahName: _surahName,
                                    boundaryKey: _reelContentKey,
                                  );
                                }
                                    : null,
                                icon: const Icon(Icons.movie),
                                label: Text(context.l10n.generateReel),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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

class _VerseDropdown extends StatelessWidget {
  const _VerseDropdown({
    required this.label,
    required this.value,
    required this.max,
    required this.min,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int max;
  final int min;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value.clamp(min, max),
          isExpanded: true,
          isDense: true,
          onChanged: enabled ? (v) => onChanged(v!) : null,
          items: List.generate(
            max - min + 1,
                (i) {
              final v = min + i;
              return DropdownMenuItem(value: v, child: Text('$v'));
            },
          ),
        ),
      ),
    );
  }
}

class _ReelPreview extends StatefulWidget {
  const _ReelPreview({
    required this.filePath,
    required this.onShare,
  });

  final String filePath;
  final VoidCallback onShare;

  @override
  State<_ReelPreview> createState() => _ReelPreviewState();
}

class _ReelPreviewState extends State<_ReelPreview> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.file(File(widget.filePath));
    await _videoPlayerController.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: 9 / 16,
      autoPlay: true,
      looping: false,
      showControls: true,
      placeholder: const Center(child: CircularProgressIndicator()),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController == null) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        Text(
          context.l10n.reviewReel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 400,
            child: Chewie(controller: _chewieController!),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: widget.onShare,
            icon: const Icon(Icons.share),
            label: Text(context.l10n.shareReel),
          ),
        ),
      ],
    );
  }
}
