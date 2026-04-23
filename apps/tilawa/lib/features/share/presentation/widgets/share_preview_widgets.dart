import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class MediaPreviewFrame extends StatelessWidget {
  const MediaPreviewFrame({
    super.key,
    required this.aspectRatio,
    required this.child,
    this.padding,
  });

  final double aspectRatio;
  final Widget child;
  final double? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 760),
        child: TilawaCard(
          padding: EdgeInsets.all(padding ?? tokens.spaceLarge),
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          borderColor: Colors.white.withValues(alpha: 0.12),
          borderRadius: 34, // Custom large radius for immersive preview
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: AspectRatio(aspectRatio: aspectRatio, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class GeneratedImagePreview extends StatelessWidget {
  const GeneratedImagePreview({super.key, required this.filePath});

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

class GeneratedVideoPreview extends StatefulWidget {
  const GeneratedVideoPreview({
    super.key,
    required this.filePath,
    required this.isMuted,
    this.onMuteChanged,
  });

  final String filePath;
  final bool isMuted;
  final ValueChanged<bool>? onMuteChanged;

  @override
  State<GeneratedVideoPreview> createState() => _GeneratedVideoPreviewState();
}

class _GeneratedVideoPreviewState extends State<GeneratedVideoPreview> {
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
  void didUpdateWidget(GeneratedVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMuted != widget.isMuted) {
      _controller?.setVolume(widget.isMuted ? 0 : 1);
    }
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
