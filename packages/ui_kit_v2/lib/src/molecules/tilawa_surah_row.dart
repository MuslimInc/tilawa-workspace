import 'package:flutter/material.dart';

import '../atoms/atoms.dart';
import '../foundation/foundation.dart';

/// A surah list row. Star ayah badge → name+meta → Arabic name.
/// Mirrors `.tw-surahrow`.
class TilawaSurahRow extends StatefulWidget {
  const TilawaSurahRow({
    required this.number,
    required this.name,
    required this.arabicName,
    required this.meta,
    this.onTap,
    this.isActive = false,
    super.key,
  });

  final int number;
  final String name;
  final String arabicName;
  final String meta;
  final VoidCallback? onTap;
  final bool isActive;

  @override
  State<TilawaSurahRow> createState() => _TilawaSurahRowState();
}

class _TilawaSurahRowState extends State<TilawaSurahRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final c = theme.tokens.colors;

    final bg = widget.isActive
        ? const Color(0x0A2D5C3F)
        : _hovered
        ? const Color(0x082D5C3F)
        : Colors.transparent;

    return Semantics(
      button: widget.onTap != null,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: widget.onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: TilawaMotion.fast,
            color: bg,
            padding: const EdgeInsets.symmetric(
              horizontal: TilawaSpacing.padX,
              vertical: 12,
            ),
            child: Row(
              children: [
                TilawaNumBadge(
                  number: widget.number,
                  variant: TilawaNumBadgeVariant.soft,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: theme.typography.h3Mobile.copyWith(color: c.fg1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.meta,
                        style: theme.typography.captionMobile,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    widget.arabicName,
                    style: theme.typography.arabic.copyWith(
                      fontSize: 22,
                      height: 1.3,
                      color: TilawaPalette.green700,
                    ),
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
