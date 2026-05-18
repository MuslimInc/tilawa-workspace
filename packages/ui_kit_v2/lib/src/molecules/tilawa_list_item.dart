import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

enum TilawaListItemTone {
  normal,
  danger,
}

/// Settings-style row. Icon → label + sub → trailing (value text, toggle,
/// or chevron). Mirrors `.tw-listitem`.
class TilawaListItem extends StatefulWidget {
  const TilawaListItem({
    required this.label,
    this.icon,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.tone = TilawaListItemTone.normal,
    this.showChevron = false,
    super.key,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final TilawaListItemTone tone;
  final bool showChevron;

  @override
  State<TilawaListItem> createState() => _TilawaListItemState();
}

class _TilawaListItemState extends State<TilawaListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final c = theme.tokens.colors;
    final danger = widget.tone == TilawaListItemTone.danger;

    final iconBg = danger
        ? const Color(0x1AB04545)
        : const Color(0x142D5C3F);
    final iconFg = danger ? c.danger : TilawaPalette.green700;
    final labelColor = danger ? c.danger : c.fg1;

    final trailing = widget.trailing ??
        (widget.showChevron
            ? Icon(Icons.chevron_right, size: 18, color: c.fg2)
            : null);

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
            color: _hovered ? const Color(0x0A2D5C3F) : Colors.transparent,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(
              horizontal: TilawaSpacing.s4,
              vertical: 12,
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(widget.icon, size: 16, color: iconFg),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: theme.typography.bodyMobile.copyWith(
                          color: labelColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((widget.subtitle ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontFamily: TilawaFontFamily.ui,
                            fontSize: 11,
                            color: c.fg2,
                            height: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A rounded card grouping multiple [TilawaListItem]s with hairlines between
/// them. Mirrors `.tw-listgroup`.
class TilawaListGroup extends StatelessWidget {
  const TilawaListGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = TilawaTheme.of(context).tokens.colors;
    final items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(Container(height: 1, color: c.hairline));
      }
      items.add(children[i]);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TilawaSpacing.padX),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgCard,
          borderRadius: TilawaRadii.brLg,
          border: Border.all(color: c.hairline),
          boxShadow: TilawaShadows.el1,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items,
        ),
      ),
    );
  }
}
