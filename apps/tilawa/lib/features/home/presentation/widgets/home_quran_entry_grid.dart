import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/screens/cubit/main_screen_cubit.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'home_dashboard_card.dart';

/// Two primary Quran entry points: Reciters (tab switch) + Read Quran (push).
class HomeQuranEntryGrid extends StatelessWidget {
  const HomeQuranEntryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Row(
      spacing: tokens.spaceSmall,
      children: [
        Expanded(
          child: _QuranEntryTile(
            icon: FluentIcons.headphones_sound_wave_24_regular,
            title: context.l10n.homeQuickReciters,
            subtitle: context.l10n.homeQuickRecitersSubtitle,
            onTap: () => context.read<MainScreenCubit>().selectTab(1),
          ),
        ),
        Expanded(
          child: _QuranEntryTile(
            icon: FluentIcons.book_open_24_regular,
            title: context.l10n.homeQuickQuran,
            subtitle: context.l10n.homeStartQuranSubtitle,
            onTap: () => const QuranIndexRoute().push(context),
          ),
        ),
      ],
    );
  }
}

class _QuranEntryTile extends StatelessWidget {
  const _QuranEntryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final TextStyle subtitleStyle = theme.textTheme.bodySmall!.copyWith(
      color: colorScheme.onSurfaceVariant,
      height: 1.3,
    );

    return HomeDashboardCard(
      surface: TilawaCardSurface.raised,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spaceExtraSmall,
        children: [
          TilawaIconBox(
            icon: icon,
            size: tokens.iconSizeMedium,
            padding: tokens.spaceSmall,
            variant: TilawaIconBoxVariant.tinted,
            semanticTint: TilawaSemanticTint.ink,
          ),
          SizedBox(height: tokens.spaceExtraSmall),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(
            height: _homeQuranEntrySubtitleBlockHeight(subtitleStyle),
            width: double.infinity,
            child: Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: subtitleStyle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed two-line subtitle block height (no [IntrinsicHeight] — expensive and
/// incompatible with [HomeDashboardCard]'s [LayoutBuilder]).
double _homeQuranEntrySubtitleBlockHeight(TextStyle style) {
  final double fontSize = style.fontSize ?? 12;
  final double lineHeight = style.height ?? 1.3;
  return fontSize * lineHeight * 2;
}
