import 'dart:ui';

import 'package:flutter/material.dart';

import '../atoms/atoms.dart';
import '../foundation/foundation.dart';

/// Floating now-playing card. Glassy white with a hairline brand-tinted
/// progress at the bottom. Mirrors `.tw-nowplaying`.
class TilawaNowPlayingDock extends StatelessWidget {
  const TilawaNowPlayingDock({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.isPlaying,
    required this.onPlayPause,
    this.artGlyph,
    this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final double progress;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final String? artGlyph;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final c = theme.tokens.colors;

    return ClipRRect(
      borderRadius: TilawaRadii.brLg,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xF0FFFFFF),
              borderRadius: TilawaRadii.brLg,
              border: Border.all(color: c.hairline),
              boxShadow: TilawaShadows.el2,
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _Art(glyph: artGlyph),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: TilawaFontFamily.ui,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.fg1,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: TilawaFontFamily.ui,
                              fontSize: 11,
                              color: c.fg2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TilawaIconBtn(
                      icon: isPlaying ? Icons.pause : Icons.play_arrow,
                      onPressed: onPlayPause,
                      semanticLabel: isPlaying ? 'Pause' : 'Play',
                      variant: TilawaIconBtnVariant.solid,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TilawaProgressBar(value: progress, height: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Art extends StatelessWidget {
  const _Art({this.glyph});

  final String? glyph;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TilawaPalette.green700, TilawaPalette.green500],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          glyph ?? 'ﷲ',
          style: TextStyle(
            fontFamily: TilawaFontFamily.arabic,
            fontSize: 22,
            height: 1,
            color: TilawaPalette.gold300,
          ),
        ),
      ),
    );
  }
}
