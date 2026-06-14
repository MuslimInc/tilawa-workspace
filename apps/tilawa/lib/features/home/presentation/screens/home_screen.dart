import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/today_plan/today_plan.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/home_dashboard.dart';
import '../bloc/home_dashboard_bloc.dart';
import '../bloc/home_dashboard_event.dart';
import '../bloc/home_dashboard_state.dart';

/// Main daily dashboard for the app shell.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenReciters,
    required this.onOpenPrayer,
    required this.onOpenAthkar,
    required this.onOpenSettings,
  });

  final VoidCallback onOpenReciters;
  final VoidCallback onOpenPrayer;
  final VoidCallback onOpenAthkar;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldCanvasColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<HomeDashboardBloc>().add(
              const HomeDashboardRefreshRequested(),
            );
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  context.tokens.spaceMedium,
                  context.tokens.spaceSmall,
                  context.tokens.spaceMedium,
                  TilawaShellPadding.of(context) + context.tokens.spaceLarge,
                ),
                sliver: SliverList.list(
                  children: [
                    BlocBuilder<HomeDashboardBloc, HomeDashboardState>(
                      builder: (context, state) {
                        return switch (state) {
                          HomeDashboardLoaded(:final dashboard) =>
                            _HomeDashboardHeader(dashboard: dashboard),
                          HomeDashboardFailure() => const _HomeHeaderFallback(),
                          _ => const _HomeHeaderLoading(),
                        };
                      },
                    ),
                    SizedBox(height: context.tokens.spaceMedium),
                    BlocBuilder<HomeDashboardBloc, HomeDashboardState>(
                      builder: (context, state) {
                        return switch (state) {
                          HomeDashboardLoaded(:final dashboard) =>
                            _NextPrayerPanel(
                              dashboard: dashboard,
                              onOpenPrayer: onOpenPrayer,
                            ),
                          _ => _NextPrayerSkeleton(onOpenPrayer: onOpenPrayer),
                        };
                      },
                    ),
                    SizedBox(height: context.tokens.spaceMedium),
                    const TodayPlanCard(),
                    SizedBox(height: context.tokens.spaceLarge),
                    _SectionTitle(text: context.l10n.homeExploreTitle),
                    SizedBox(height: context.tokens.spaceSmall),
                    _QuickActionsGrid(
                      actions: [
                        _HomeQuickAction(
                          label: context.l10n.homeQuickQuran,
                          icon: Icons.menu_book_rounded,
                          onTap: () => const QuranLastReadRoute().push(context),
                        ),
                        _HomeQuickAction(
                          label: context.l10n.homeQuickReciters,
                          icon: FluentIcons.person_voice_24_regular,
                          onTap: onOpenReciters,
                        ),
                        _HomeQuickAction(
                          label: context.l10n.homeQuickPrayer,
                          icon: FluentIcons.clock_24_regular,
                          onTap: onOpenPrayer,
                        ),
                        _HomeQuickAction(
                          label: context.l10n.homeQuickQibla,
                          icon: FluentIcons.compass_northwest_24_regular,
                          onTap: () => const QiblaRoute().push(context),
                        ),
                        _HomeQuickAction(
                          label: context.l10n.homeQuickAthkar,
                          icon: FluentIcons.book_open_24_regular,
                          onTap: onOpenAthkar,
                        ),
                        _HomeQuickAction(
                          label: context.l10n.homeQuickSettings,
                          icon: FluentIcons.settings_24_regular,
                          onTap: onOpenSettings,
                        ),
                      ],
                    ),
                    SizedBox(height: context.tokens.spaceLarge),
                    _DailyContentCard(
                      label: context.l10n.homeDailyAyahLabel,
                      body: context.l10n.homeDailyAyahBody,
                      footer: context.l10n.homeDailyAyahReference,
                    ),
                    SizedBox(height: context.tokens.spaceSmall),
                    _DailyContentCard(
                      label: context.l10n.homeDailyDuaLabel,
                      body: context.l10n.homeDailyDuaBody,
                      footer: context.l10n.homeDailyDuaReference,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeDashboardHeader extends StatelessWidget {
  const _HomeDashboardHeader({required this.dashboard});

  final HomeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final displayName = dashboard.displayName;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.homeTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: tokens.spaceExtraSmall),
              Text(
                displayName == null
                    ? context.l10n.homeGreeting
                    : context.l10n.homeGreetingName(displayName),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: tokens.spaceMedium),
        _ProfileMark(displayName: displayName),
      ],
    );
  }
}

class _HomeHeaderFallback extends StatelessWidget {
  const _HomeHeaderFallback();

  @override
  Widget build(BuildContext context) {
    return _HomeDashboardHeader(
      dashboard: HomeDashboard(generatedAt: DateTime.now()),
    );
  }
}

class _HomeHeaderLoading extends StatelessWidget {
  const _HomeHeaderLoading();

  @override
  Widget build(BuildContext context) {
    return _HomeDashboardHeader(
      dashboard: HomeDashboard(generatedAt: DateTime.now()),
    );
  }
}

class _ProfileMark extends StatelessWidget {
  const _ProfileMark({required this.displayName});

  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String initial = _initialFor(displayName);

    return Semantics(
      label: context.l10n.homeProfileLabel,
      child: Container(
        width: kTilawaMinInteractiveDimension,
        height: kTilawaMinInteractiveDimension,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Text(
          initial,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  String _initialFor(String? value) {
    final String? name = value?.trim();
    if (name == null || name.isEmpty) {
      return 'T';
    }
    return name.characters.first.toUpperCase();
  }
}

class _NextPrayerPanel extends StatelessWidget {
  const _NextPrayerPanel({
    required this.dashboard,
    required this.onOpenPrayer,
  });

  final HomeDashboard dashboard;
  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final nextPrayer = dashboard.nextPrayer;

    return _HomePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _LocationChip(
                  label:
                      dashboard.locationLabel ??
                      context.l10n.homeLocationUnavailable,
                ),
              ),
              SizedBox(width: tokens.spaceSmall),
              OutlinedButton(
                onPressed: onOpenPrayer,
                child: Text(context.l10n.homePrayerTimesAction),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceLarge),
          Text(
            context.l10n.nextPrayer,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.spaceExtraSmall),
          if (nextPrayer == null)
            Text(
              context.l10n.homeNextPrayerUnavailable,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    _localizedPrayerName(context, nextPrayer.type),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _formatTime(context, nextPrayer.time),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          if (nextPrayer != null) ...[
            SizedBox(height: tokens.spaceSmall),
            Text(
              _formatCountdown(context, nextPrayer.timeUntil),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NextPrayerSkeleton extends StatelessWidget {
  const _NextPrayerSkeleton({required this.onOpenPrayer});

  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    return _HomePanel(
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.homeNextPrayerUnavailable,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          OutlinedButton(
            onPressed: onOpenPrayer,
            child: Text(context.l10n.homePrayerTimesAction),
          ),
        ],
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Container(
      constraints: const BoxConstraints(
        minHeight: kTilawaMinInteractiveDimension,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: tokens.spaceExtraSmall,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(
            family: TilawaRadiusFamily.pill,
            height: kTilawaMinInteractiveDimension,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FluentIcons.location_24_regular,
            size: tokens.iconSizeSmall,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          SizedBox(width: tokens.spaceExtraSmall),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.actions});

  final List<_HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = constraints.maxWidth >= 520 ? 3 : 2;
        final double gap = tokens.spaceSmall;
        final double tileWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final action in actions)
              SizedBox(
                width: tileWidth,
                child: _QuickActionTile(action: action),
              ),
          ],
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _HomeQuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    final ColorScheme colorScheme = theme.colorScheme;
    final Color tileFill = colorScheme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLow;

    return Material(
      color: tileFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(family: TilawaRadiusFamily.card),
        ),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: tokens.borderWidthThin,
        ),
      ),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(family: TilawaRadiusFamily.card),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 104),
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  action.icon,
                  color: colorScheme.primary,
                  size: tokens.iconSizeLarge,
                ),
                Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeQuickAction {
  const _HomeQuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _DailyContentCard extends StatelessWidget {
  const _DailyContentCard({
    required this.label,
    required this.body,
    required this.footer,
  });

  final String label;
  final String body;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return _HomePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
          Text(
            body,
            textAlign: TextAlign.start,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.55,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              footer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _HomePanel extends StatelessWidget {
  const _HomePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TilawaCard(
      surface: TilawaCardSurface.raised,
      child: child,
    );
  }
}

String _localizedPrayerName(BuildContext context, PrayerType type) {
  return switch (type) {
    PrayerType.fajr => context.l10n.fajr,
    PrayerType.sunrise => context.l10n.sunrise,
    PrayerType.dhuhr => context.l10n.dhuhr,
    PrayerType.asr => context.l10n.asr,
    PrayerType.maghrib => context.l10n.maghrib,
    PrayerType.isha => context.l10n.isha,
    PrayerType.midnight => context.l10n.midnight,
    PrayerType.lastThird => context.l10n.lastThird,
  };
}

String _formatTime(BuildContext context, DateTime time) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(time),
  );
}

String _formatCountdown(BuildContext context, Duration duration) {
  if (duration.inMinutes < 1) {
    return context.l10n.homePrayerNow;
  }
  final int totalMinutes = duration.inMinutes;
  final int hours = totalMinutes ~/ 60;
  final int minutes = totalMinutes % 60;
  if (hours == 0) {
    return context.l10n.homePrayerInMinutes(minutes);
  }
  return context.l10n.homePrayerInHoursMinutes(hours, minutes);
}
