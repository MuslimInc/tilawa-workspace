import 'dart:ui';

import 'package:flutter/material.dart';

import '../foundation/foundation.dart';

class TilawaTabItem {
  const TilawaTabItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Floating glassy bottom tab bar with an iOS-26-style active pill.
/// Mirrors `.tw-tabbar`.
class TilawaBottomTabBar extends StatelessWidget {
  const TilawaBottomTabBar({
    required this.items,
    required this.currentIndex,
    required this.onChanged,
    super.key,
  });

  final List<TilawaTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = TilawaTheme.of(context).tokens.colors;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 78,
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
          decoration: BoxDecoration(
            color: const Color(0xEBFFFFFF),
            border: Border(
              top: BorderSide(color: c.hairline, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(child: _Tab(
                  item: items[i],
                  active: i == currentIndex,
                  onTap: () => onChanged(i),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final TilawaTabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = TilawaTheme.of(context);
    final activeColor = TilawaPalette.green700;
    final inactiveColor = theme.tokens.colors.fg2;

    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: TilawaMotion.base,
                curve: TilawaMotion.standard,
                width: 36,
                height: 26,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0x1A2D5C3F)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  item.icon,
                  size: 18,
                  color: active ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  fontFamily: TilawaFontFamily.ui,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
