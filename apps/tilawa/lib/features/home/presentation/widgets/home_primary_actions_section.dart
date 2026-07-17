import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/presentation/widgets/home_dashboard_section.dart';
import 'package:tilawa/features/home/presentation/widgets/home_feature_pastel.dart';
import 'package:tilawa/features/home/presentation/widgets/home_primary_action_tile.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Two primary daily-action tiles under the Sliver Prayer Hero.
class HomePrimaryActionsSection extends StatelessWidget {
  const HomePrimaryActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final product = Theme.of(context).productColors;
    final Color quranAccent = HomeFeaturePastel.accentFor(
      HomeExploreFeature.quran,
      product,
    );
    final Color athkarAccent = HomeFeaturePastel.accentFor(
      HomeExploreFeature.athkar,
      product,
    );
    final double iconSize = tokens.iconSizeLarge;

    return HomeDashboardSection(
      title: context.l10n.homeMainActionsTitle,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceMedium,
          children: [
            Expanded(
              child: HomePrimaryActionTile(
                goldAccentOnStart: true,
                accent: quranAccent,
                icon: TilawaIcons.quran.svg(
                  size: iconSize,
                  color: quranAccent,
                ),
                label: context.l10n.homeQuickQuranReader,
                subtitle: context.l10n.homeContinueQuranSubtitle,
                // Last-read route continues progress; opens index when fresh.
                onTap: () => const QuranLastReadRoute().push<void>(context),
              ),
            ),
            Expanded(
              child: HomePrimaryActionTile(
                goldAccentOnStart: false,
                accent: athkarAccent,
                icon: Icon(
                  Icons.brightness_5_outlined,
                  size: iconSize,
                  color: athkarAccent,
                ),
                label: context.l10n.homeQuickAthkar,
                subtitle: context.l10n.homeQuickAthkarSubtitle,
                onTap: () => const AthkarCategoriesRoute().push<void>(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
