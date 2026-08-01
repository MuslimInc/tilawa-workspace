import 'package:flutter/material.dart';
import 'package:tilawa/core/app_social_urls.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/legal_url_launcher.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Settings cluster linking to MeMuslim public social channels.
class SettingsSocialLinksSection extends StatelessWidget {
  const SettingsSocialLinksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return TilawaSettingsSection(
      title: l10n.settingsFollowUsSection,
      children: [
        _SettingsSocialLinkTile(
          title: l10n.settingsFacebookTile,
          icon: Icons.facebook,
          url: AppSocialUrls.facebook,
        ),
        _SettingsSocialLinkTile(
          title: l10n.settingsInstagramTile,
          icon: Icons.camera_alt_outlined,
          url: AppSocialUrls.instagram,
        ),
        _SettingsSocialLinkTile(
          title: l10n.settingsYoutubeTile,
          icon: Icons.smart_display_outlined,
          url: AppSocialUrls.youtube,
          showDivider: false,
        ),
      ],
    );
  }
}

class _SettingsSocialLinkTile extends StatelessWidget {
  const _SettingsSocialLinkTile({
    required this.title,
    required this.icon,
    required this.url,
    this.showDivider = true,
  });

  final String title;
  final IconData icon;
  final String url;
  final bool showDivider;

  Future<void> _open(BuildContext context) async {
    final bool launched = await openLegalUrl(url);
    if (!launched && context.mounted) {
      TilawaFeedback.showToast(
        context,
        message: context.l10n.settingsOpenSocialLinkFailed,
        variant: TilawaFeedbackVariant.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TilawaSettingsTile(
      icon: icon,
      title: title,
      showDivider: showDivider,
      onTap: () => _open(context),
    );
  }
}
