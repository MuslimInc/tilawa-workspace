import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class MediaPreviewFrame extends StatelessWidget {
  const MediaPreviewFrame({
    super.key,
    required this.child,
    this.aspectRatio,
    this.padding,
  });

  final Widget child;
  final double? aspectRatio;
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
          backgroundColor: theme.colorScheme.surfaceContainerHigh,
          borderColor: theme.colorScheme.outlineVariant.withValues(
            alpha: tokens.opacitySubtle,
          ),
          borderRadius: 34,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(tokens.radiusExtraLarge),
            ),
            child: aspectRatio == null
                ? child
                : AspectRatio(aspectRatio: aspectRatio!, child: child),
          ),
        ),
      ),
    );
  }
}

class GeneratedImagePreview extends StatefulWidget {
  const GeneratedImagePreview({super.key, required this.filePath});

  final String filePath;

  @override
  State<GeneratedImagePreview> createState() => _GeneratedImagePreviewState();
}

class _GeneratedImagePreviewState extends State<GeneratedImagePreview> {
  late Future<Size> _imageSizeFuture;

  @override
  void initState() {
    super.initState();
    _imageSizeFuture = _resolveImageSize();
  }

  @override
  void didUpdateWidget(covariant GeneratedImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _imageSizeFuture = _resolveImageSize();
    }
  }

  Future<Size> _resolveImageSize() {
    final ImageProvider provider = FileImage(File(widget.filePath));
    final ImageStream stream = provider.resolve(const ImageConfiguration());
    final Completer<Size> completer = Completer<Size>();
    late final ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        if (!completer.isCompleted) {
          completer.complete(
            Size(image.image.width.toDouble(), image.image.height.toDouble()),
          );
        }
        stream.removeListener(listener);
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<Size>(
      future: _imageSizeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const TilawaLoadingIndicator(),
          );
        }

        if (!snapshot.hasData) {
          return ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final Size imageSize = snapshot.data!;

        return AspectRatio(
          aspectRatio: imageSize.width / imageSize.height,
          child: ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(theme.tokens.radiusSmall),
                child: Image.file(
                  File(widget.filePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GeneratedVideoPreview extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool exists = File(filePath).existsSync();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_creation_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            exists
                ? context.l10n.shareModeReel
                : context.l10n.reelPreviewLoadFailed,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
