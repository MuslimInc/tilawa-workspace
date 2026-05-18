import 'package:flutter/material.dart';

import '../atoms/atoms.dart';
import '../foundation/foundation.dart';

/// Audio transport row. Seek bar + times + transport buttons.
/// Mirrors `.tw-transport`.
class TilawaPlayerTransport extends StatelessWidget {
  const TilawaPlayerTransport({
    required this.progress,
    required this.elapsed,
    required this.remaining,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    this.onRepeat,
    this.onShuffle,
    super.key,
  });

  final double progress;
  final String elapsed;
  final String remaining;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onRepeat;
  final VoidCallback? onShuffle;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final c = theme.tokens.colors;

    final timeStyle = TextStyle(
      fontFamily: TilawaFontFamily.ui,
      fontSize: 11,
      color: c.fg2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TilawaSpacing.padX,
        0,
        TilawaSpacing.padX,
        20,
      ),
      child: Column(
        children: [
          TilawaProgressBar(value: progress, showThumb: true),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(elapsed, style: timeStyle),
              Text(remaining, style: timeStyle),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TilawaIconBtn(
                icon: Icons.shuffle,
                onPressed: onShuffle,
                semanticLabel: 'Shuffle',
              ),
              TilawaIconBtn(
                icon: Icons.skip_previous,
                onPressed: onPrevious,
                semanticLabel: 'Previous verse',
              ),
              TilawaIconBtn(
                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                onPressed: onPlayPause,
                semanticLabel: isPlaying ? 'Pause' : 'Play',
                variant: TilawaIconBtnVariant.solid,
                size: TilawaIconBtnSize.lg,
              ),
              TilawaIconBtn(
                icon: Icons.skip_next,
                onPressed: onNext,
                semanticLabel: 'Next verse',
              ),
              TilawaIconBtn(
                icon: Icons.repeat,
                onPressed: onRepeat,
                semanticLabel: 'Repeat',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
