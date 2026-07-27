import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';

/// Primary Support-section entry for Sadaqah Jariyah.
///
/// Uses a standard [TilawaSettingsTile] with a leading icon and subtitle so the
/// row reads as an important feature — taller and clearer than sibling Support
/// actions — without promotional chrome.
class SettingsSadaqahJariyahTile extends StatelessWidget {
  const SettingsSadaqahJariyahTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return TilawaSettingsTile(
      icon: TilawaIcons.heart,
      title: l10n.sadaqahJariyahDefaultTitle,
      subtitle: l10n.sadaqahJariyahSettingsSubtitle,
      onTap: () => const SadaqahJariyahRoute().push<void>(context),
    );
  }
}
