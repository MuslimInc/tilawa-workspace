import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/home/debug/home_hero_variant_debug.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Developer settings control to compare home hero layout variants.
class HomeHeroVariantDebugTile extends StatefulWidget {
  const HomeHeroVariantDebugTile({super.key, this.isLast = false});

  final bool isLast;

  @override
  State<HomeHeroVariantDebugTile> createState() => _HomeHeroVariantDebugTileState();
}

class _HomeHeroVariantDebugTileState extends State<HomeHeroVariantDebugTile> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      HomeHeroVariantDebug.ensureLoaded(GetIt.I<SharedPreferencesAsync>());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<HomeHeroDesignVariant>(
      valueListenable: HomeHeroVariantDebug.variant,
      builder: (BuildContext context, HomeHeroDesignVariant value, Widget? _) {
        return TilawaSettingsTile(
          icon: FluentIcons.layout_column_two_24_regular,
          title: 'Home hero layout',
          subtitle: HomeHeroVariantDebug.labelFor(value),
          showDivider: !widget.isLast,
          onTap: () => HomeHeroVariantDebug.cycle(
            GetIt.I<SharedPreferencesAsync>(),
          ),
        );
      },
    );
  }
}
