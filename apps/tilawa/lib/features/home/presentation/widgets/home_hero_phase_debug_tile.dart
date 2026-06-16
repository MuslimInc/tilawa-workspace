import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/features/home/debug/home_hero_gradient_debug.dart';
import 'package:tilawa/features/home/domain/home_hero_gradient_resolver.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Developer settings control to preview home hero gradient phases.
class HomeHeroPhaseDebugTile extends StatelessWidget {
  const HomeHeroPhaseDebugTile({super.key, this.isLast = false});

  final bool isLast;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<HomeHeroDayPhase?>(
      valueListenable: HomeHeroGradientDebug.phaseOverride,
      builder: (BuildContext context, HomeHeroDayPhase? phase, Widget? child) {
        return TilawaSettingsTile(
          icon: FluentIcons.color_24_regular,
          title: 'Home hero phase',
          subtitle: HomeHeroGradientDebug.labelFor(phase),
          showDivider: !isLast,
          onTap: HomeHeroGradientDebug.cyclePhase,
        );
      },
    );
  }
}
