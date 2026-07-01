import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/quran_sessions/presentation/teacher_application_entry.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'settings_widgets.dart';

/// Settings/Profile entry for experienced Quran teachers to apply via Google Form.
class SettingsTeacherApplicationEntrySection extends StatelessWidget {
  const SettingsTeacherApplicationEntrySection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!quranSessionsFeatureConfig().showTeacherApplicationEntry) {
      return const SizedBox.shrink();
    }

    final tokens = Theme.of(context).tokens;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: tokens.spaceLarge,
        bottom: tokens.spaceXXL,
      ),
      child: const TilawaSettingsGroupHorizontalInset(
        child: TilawaSettingsGroupPanel(
          children: [SettingsTeacherApplicationEntryTile(showDivider: false)],
        ),
      ),
    );
  }
}

class SettingsTeacherApplicationEntryTile extends StatelessWidget {
  const SettingsTeacherApplicationEntryTile({
    super.key,
    this.showDivider = true,
  });

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    if (!quranSessionsFeatureConfig().showTeacherApplicationEntry) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    return TilawaSettingsTile(
      title: l10n.settingsTeacherApplicationEntryTitle,
      subtitle: l10n.settingsTeacherApplicationEntrySubtitle,
      trailing: settingsPickerTrailing(
        context,
        value: l10n.teacherApplicationOpenFormCta,
      ),
      onTap: () => showTeacherApplicationEntrySheet(context),
      showDivider: showDivider,
    );
  }
}
