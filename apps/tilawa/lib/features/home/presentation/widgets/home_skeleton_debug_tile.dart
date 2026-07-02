import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/features/home/debug/home_skeleton_debug.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Developer settings switch that forces the Home skeleton loading state.
///
/// Debug builds only — renders nothing in release. See [HomeSkeletonDebug].
class HomeSkeletonDebugTile extends StatelessWidget {
  const HomeSkeletonDebugTile({super.key, this.isLast = false});

  final bool isLast;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: HomeSkeletonDebug.forceSkeleton,
      builder: (context, forced, _) {
        return TilawaSettingsSwitchTile(
          title: 'Force Home skeleton',
          subtitle: 'Pin the Home dashboard to its shimmer loading state',
          value: forced,
          showDivider: !isLast,
          onChanged: (value) => HomeSkeletonDebug.forceSkeleton.value = value,
        );
      },
    );
  }
}
