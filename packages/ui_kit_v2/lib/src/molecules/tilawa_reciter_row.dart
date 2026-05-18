import 'package:flutter/material.dart';

import '../atoms/atoms.dart';
import '../foundation/foundation.dart';

/// Reciter list row. Avatar → name + meta (school · language) → optional
/// check / chevron. Mirrors `.tw-reciterrow`.
class TilawaReciterRow extends StatefulWidget {
  const TilawaReciterRow({
    required this.name,
    required this.meta,
    this.initials,
    this.imageUrl,
    this.isSelected = false,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String name;
  final String meta;
  final String? initials;
  final String? imageUrl;
  final bool isSelected;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  State<TilawaReciterRow> createState() => _TilawaReciterRowState();
}

class _TilawaReciterRowState extends State<TilawaReciterRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final c = theme.tokens.colors;

    final initials = widget.initials ?? _initialsOf(widget.name);
    final trailing = widget.trailing ??
        (widget.isSelected
            ? Icon(Icons.check, size: 20, color: c.brand)
            : const SizedBox.shrink());

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: TilawaMotion.fast,
          color: _hovered ? const Color(0x082D5C3F) : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: TilawaSpacing.padX,
            vertical: 10,
          ),
          child: Row(
            children: [
              TilawaAvatar(
                initials: initials,
                image: widget.imageUrl == null
                    ? null
                    : NetworkImage(widget.imageUrl!),
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
                    const SizedBox(height: 3),
                    Text(
                      widget.meta,
                      style: theme.typography.captionMobile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  static String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}
