import 'dart:io';

import 'package:flutter/material.dart';

class PreviewFrame extends StatelessWidget {
  const PreviewFrame({
    super.key,
    required this.aspectRatio,
    required this.child,
    this.maxWidth = 420,
    this.maxHeight = 760,
  });

  final double aspectRatio;
  final Widget child;
  final double? maxWidth;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
        maxHeight: maxHeight ?? double.infinity,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        color: theme.colorScheme.surface.withValues(alpha: 0.08),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.16),
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

class MediaPreviewFrame extends StatelessWidget {
  const MediaPreviewFrame({
    super.key,
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
