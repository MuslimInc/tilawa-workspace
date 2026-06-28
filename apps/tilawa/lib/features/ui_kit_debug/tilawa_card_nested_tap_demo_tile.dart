import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/features/ui_kit_debug/tilawa_card_demo_semantics_ids.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Developer settings entry for the TilawaCard nested-tap Maestro demo.
class TilawaCardNestedTapDemoTile extends StatelessWidget {
  const TilawaCardNestedTapDemoTile({super.key, this.isLast = false});

  final bool isLast;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return TilawaSettingsTile(
      icon: FluentIcons.card_ui_24_regular,
      title: 'TilawaCard nested tap demo',
      showDivider: !isLast,
      semanticsIdentifier: TilawaCardDemoSemanticsIds.settingsTile,
      onTap: () => const TilawaCardNestedTapDemoRoute().push(context),
    );
  }
}
