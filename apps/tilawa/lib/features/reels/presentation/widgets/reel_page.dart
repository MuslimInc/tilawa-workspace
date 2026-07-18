import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import 'package:video_player/video_player.dart';

import '../../domain/entities/reel.dart';
import '../services/reel_player_pool.dart';
import '../utils/reel_category_labels.dart';
import 'reel_actions_column.dart';
import 'reel_heart_burst.dart';

class ReelPage extends StatefulWidget {
  const ReelPage({
    super.key,
    required this.reel,
    required this.pool,
    required this.isActive,
    required this.showBurst,
    required this.onToggleSave,
    required this.onReact,
    required this.onDoubleTapReact,
    required this.onShare,
    required this.onMore,
    required this.onCompleted,
    required this.onBurstDone,
  });

  final Reel reel;
  final ReelPlayerPool pool;
  final bool isActive;
  final bool showBurst;
  final VoidCallback onToggleSave;
  final VoidCallback onReact;
  final VoidCallback onDoubleTapReact;
  final VoidCallback onShare;
  final VoidCallback onMore;
  final VoidCallback onCompleted;
  final VoidCallback onBurstDone;

  @override
  State<ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<ReelPage> {
  bool _completedFired = false;
  bool _longPressing = false;
  VideoPlayerController? _listening;

  @override
  void initState() {
    super.initState();
    _attachListener();
  }

  @override
  void didUpdateWidget(covariant ReelPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reel.id != widget.reel.id) {
      _completedFired = false;
    }
    _attachListener();
  }

  void _attachListener() {
    final next = widget.pool.controllerFor(widget.reel.id);
    if (_listening == next) return;
    _listening?.removeListener(_onControllerTick);
    _listening = next;
    _listening?.addListener(_onControllerTick);
  }

  void _onControllerTick() {
    final c = _listening;
    if (c == null || !c.value.isInitialized) return;
    final pos = c.value.position;
    final dur = c.value.duration;
    if (!_completedFired &&
        dur.inMilliseconds > 0 &&
        pos >= dur - const Duration(milliseconds: 400)) {
      _completedFired = true;
      widget.onCompleted();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _listening?.removeListener(_onControllerTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    _attachListener();
    final controller = widget.pool.controllerFor(widget.reel.id);

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 9 / 16
                    : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            )
          else if (controller != null && controller.value.hasError)
            _ErrorBody(
              message: l10n.reelsPlaybackError,
              onRetry: () => widget.pool.retry(widget.reel),
            )
          else
            Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: widget.reel.thumbUrl,
                  fit: BoxFit.cover,
                ),
                const Center(child: CircularProgressIndicator.adaptive()),
              ],
            ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.pool.togglePlayPause(),
              onLongPressStart: (_) async {
                setState(() => _longPressing = true);
                await widget.pool.pause();
              },
              onLongPressEnd: (_) async {
                setState(() => _longPressing = false);
                if (widget.isActive) await widget.pool.play();
              },
              onDoubleTap: widget.onDoubleTapReact,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.32,
                ),
              ),
            ),
          ),
          Positioned(
            left: tokens.spaceMedium,
            right: 72,
            bottom: tokens.spaceLarge + MediaQuery.paddingOf(context).bottom,
            child: _ReelInfo(
              reel: widget.reel,
              duration: controller?.value.isInitialized == true
                  ? controller!.value.duration
                  : null,
            ),
          ),
          Positioned(
            right: tokens.spaceSmall,
            bottom:
                tokens.spaceExtraLarge + MediaQuery.paddingOf(context).bottom,
            child: ReelActionsColumn(
              hasReaction: widget.reel.reaction != null,
              isSaved: widget.reel.isSaved,
              onReact: widget.onReact,
              onSave: widget.onToggleSave,
              onShare: widget.onShare,
              onMore: widget.onMore,
            ),
          ),
          if (controller != null && controller.value.isInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: false,
                colors: VideoProgressColors(
                  playedColor: scheme.primary,
                  bufferedColor: scheme.primary.withValues(alpha: 0.3),
                  backgroundColor: scheme.onSurface.withValues(alpha: 0.2),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          if (widget.showBurst)
            Positioned.fill(
              child: IgnorePointer(
                child: ReelHeartBurst(onDone: widget.onBurstDone),
              ),
            ),
          if (_longPressing)
            const Center(
              child: Icon(
                Icons.pause_circle_filled,
                size: 64,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReelInfo extends StatelessWidget {
  const _ReelInfo({required this.reel, this.duration});

  final Reel reel;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final category = ReelCategoryLabels.forId(context, reel.categoryId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: CachedNetworkImageProvider(reel.thumbUrl),
            ),
            SizedBox(width: tokens.spaceSmall),
            Expanded(
              child: Text(
                reel.sheikhName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  shadows: const [
                    Shadow(blurRadius: 8, color: Colors.black54),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceSmall),
        Text(
          category,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
          ),
        ),
        if (duration != null && duration!.inSeconds > 0) ...[
          SizedBox(height: tokens.spaceExtraSmall),
          Text(
            _formatDuration(duration!),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.white70),
          ),
        ],
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
            SizedBox(height: tokens.spaceMedium),
            TilawaButton(
              onPressed: onRetry,
              text: context.l10n.reelsRetry,
            ),
          ],
        ),
      ),
    );
  }
}
