import 'package:flutter/material.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../features/athkar/presentation/widgets/athkar_categories_screen_scope.dart';
import '../../features/prayer_times/presentation/widgets/prayer_times_screen_scope.dart';
import '../../features/reciters/presentation/screens/reciters_screen.dart';
import '../../features/settings/presentation/widgets/settings_screen_scope.dart';

/// Lazily constructs and caches all main-tab screens, then manages the
/// [Offstage] / [TickerMode] stack so only the active tab renders.
///
/// Stateful so that [_screenCache] survives rebuilds triggered by cubit
/// state changes (e.g. audio binding, offline indicator).
class MainTabViewport extends StatefulWidget {
  const MainTabViewport({
    super.key,
    required this.currentIndex,
    required this.builtTabIndexes,
    required this.contentBottomPadding,
  });

  /// Index of the currently active tab.
  final int currentIndex;

  /// Set of tab indexes that have been visited at least once and therefore
  /// have a live (possibly offstage) subtree.
  final Set<int> builtTabIndexes;

  /// Bottom padding to apply below the tab content (nav bar + player height).
  final double contentBottomPadding;

  @override
  State<MainTabViewport> createState() => _MainTabViewportState();
}

class _MainTabViewportState extends State<MainTabViewport> {
  // Screen instances are cached so that tab subtrees survive the parent
  // rebuilds that occur as cubit startup flags change.
  final Map<int, Widget> _screenCache = <int, Widget>{};

  Widget _buildScreenForIndex(int index) {
    return _screenCache.putIfAbsent(index, () {
      return switch (index) {
        0 => RecitersScreen(),
        1 => const PrayerTimesScreenScope(),
        2 => const AthkarCategoriesScreenScope(),
        3 => const SettingsScreenScope(),
        _ => const SizedBox.shrink(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    // TilawaShellPadding is an InheritedWidget that publishes the bottom
    // padding value so any descendant can call TilawaShellPadding.of(context).
    // The explicit Padding widget below it applies the actual visual inset.
    return RecitersRootBackScope(
      child: TilawaShellPadding(
        padding: widget.contentBottomPadding,
        child: Stack(
          children: List<Widget>.generate(4, (int index) {
            if (!widget.builtTabIndexes.contains(index)) {
              return const SizedBox.shrink();
            }
            final bool isActive = widget.currentIndex == index;
            return Offstage(
              offstage: !isActive,
              child: TickerMode(
                enabled: isActive,
                child: _buildScreenForIndex(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}
