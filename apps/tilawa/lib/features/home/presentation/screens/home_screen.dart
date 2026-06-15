import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/presentation/extensions/prayer_type_ui.dart';
import 'package:tilawa/features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart';
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
              HomeDashboardRefreshRequested(
                localeIdentifier: Localizations.localeOf(context).languageCode,
              ),
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
                          HomeDashboardLoaded(
                            :final dashboard,
                            :final isRefreshingLocation,
                          ) =>
                            _NextPrayerPanel(
                              dashboard: dashboard,
                              isRefreshingLocation: isRefreshingLocation,
                              onOpenPrayer: onOpenPrayer,
                              onRefreshLocation: () {
                                context.read<HomeDashboardBloc>().add(
                                  HomeDashboardLocationRefreshRequested(
                                    localeIdentifier: Localizations.localeOf(
                                      context,
                                    ).languageCode,
                                  ),
                                );
                              },
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
    required this.isRefreshingLocation,
    required this.onOpenPrayer,
    required this.onRefreshLocation,
  });

  final HomeDashboard dashboard;
  final bool isRefreshingLocation;
  final VoidCallback onOpenPrayer;
  final VoidCallback onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final nextPrayer = dashboard.nextPrayer;
    final Color onGradient = colorScheme.onPrimary;

    return _HomeNextPrayerHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: tokens.spaceSmall,
            children: [
              Expanded(
                child: _HomeGradientLocationChip(
                  locationName: dashboard.locationLabel,
                  isLoading: isRefreshingLocation,
                  onTap: isRefreshingLocation ? null : onRefreshLocation,
                ),
              ),
              _HomeGradientActionButton(
                label: context.l10n.homePrayerTimesAction,
                onPressed: onOpenPrayer,
              ),
            ],
          ),
          SizedBox(height: tokens.spaceLarge),
          if (nextPrayer == null)
            Text(
              context.l10n.homeNextPrayerUnavailable,
              style: theme.textTheme.titleLarge?.copyWith(
                color: onGradient,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spaceMedium,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: tokens.spaceExtraSmall,
                    children: [
                      Text(
                        context.l10n.nextPrayer,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: onGradient.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        _localizedPrayerName(context, nextPrayer.type),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: onGradient,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: tokens.spaceTiny),
                      _HomeCountdownBadge(
                        label: _formatCountdown(
                          context,
                          nextPrayer.timeUntil,
                        ),
                      ),
                    ],
                  ),
                ),
                _HomePrayerVisual(icon: nextPrayer.type.icon),
              ],
            ),
          if (nextPrayer != null) ...[
            SizedBox(height: tokens.spaceMedium),
            Text(
              _formatTime(context, nextPrayer.time),
              style: theme.textTheme.displaySmall?.copyWith(
                color: onGradient,
                fontWeight: FontWeight.w800,
                height: 1.0,
                fontFeatures: const [FontFeature.tabularFigures()],
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
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final Color onGradient = theme.colorScheme.onPrimary;

    return _HomeNextPrayerHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spaceMedium,
        children: [
          Row(
            spacing: tokens.spaceSmall,
            children: [
              Expanded(
                child: _HomeGradientLocationChip(
                  locationName: null,
                  isLoading: true,
                  onTap: null,
                ),
              ),
              _HomeGradientActionButton(
                label: context.l10n.homePrayerTimesAction,
                onPressed: onOpenPrayer,
              ),
            ],
          ),
          Text(
            context.l10n.homeNextPrayerUnavailable,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onGradient.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero next-prayer surface with a brand-derived linear gradient.
class _HomeNextPrayerHeroCard extends StatelessWidget {
  const _HomeNextPrayerHeroCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final BorderRadius borderRadius = BorderRadius.circular(
      tokens.radiusExtraLarge,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(
              alpha: tokens.opacityShadowStrong,
            ),
            blurRadius: tokens.blurShadow * 1.35,
            offset: tokens.shadowOffsetMedium,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _homeNextPrayerGradient(colorScheme),
                ),
              ),
            ),
            Positioned(
              top: -tokens.spaceLarge,
              right: -tokens.spaceSmall,
              child: Container(
                width: tokens.iconSizeLargePlus * 3.2,
                height: tokens.iconSizeLargePlus * 3.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.onPrimary.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -tokens.spaceLarge,
              left: -tokens.spaceMedium,
              child: Container(
                width: tokens.iconSizeLargePlus * 2.4,
                height: tokens.iconSizeLargePlus * 2.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.tertiary.withValues(alpha: 0.14),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(tokens.spaceLarge),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

LinearGradient _homeNextPrayerGradient(ColorScheme colorScheme) {
  final bool isLight = colorScheme.brightness == Brightness.light;
  final Color topStop = Color.lerp(
    colorScheme.primary,
    colorScheme.tertiary,
    isLight ? 0.24 : 0.14,
  )!;
  final Color bottomStop = Color.lerp(
    colorScheme.primary,
    colorScheme.shadow,
    isLight ? 0.22 : 0.42,
  )!;

  return LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [topStop, colorScheme.primary, bottomStop],
    stops: const [0.0, 0.48, 1.0],
  );
}

/// Frosted location pill for the gradient hero card.
class _HomeGradientLocationChip extends StatelessWidget {
  const _HomeGradientLocationChip({
    required this.locationName,
    required this.isLoading,
    required this.onTap,
  });

  final String? locationName;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final Color onGradient = colorScheme.onPrimary;
    final String label = PrayerLocationLabelFormatter.abbreviatedLocationLabel(
      locationName: locationName,
      l10n: context.l10n,
    );
    final BorderRadius borderRadius = BorderRadius.circular(
      tokens.resolveRadius(
        family: TilawaRadiusFamily.pill,
        height: kTilawaMinInteractiveDimension,
      ),
    );

    return Material(
      color: onGradient.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: onGradient.withValues(alpha: 0.22),
          width: tokens.borderWidthThin,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: onGradient.withValues(alpha: 0.08),
        highlightColor: onGradient.withValues(alpha: 0.04),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kTilawaMinInteractiveDimension,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceSmall,
              vertical: tokens.spaceExtraSmall,
            ),
            child: Row(
              mainAxisSize: .min,
              mainAxisAlignment: .spaceBetween,
              spacing: tokens.spaceExtraSmall,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: tokens.iconSizeSmall,
                          height: tokens.iconSizeSmall,
                          child: TilawaLoadingIndicator(
                            centered: false,
                            strokeWidth: 2,
                            color: onGradient,
                          ),
                        )
                      else
                        Icon(
                          FluentIcons.location_24_regular,
                          size: tokens.iconSizeSmall,
                          color: onGradient,
                        ),
                      SizedBox(width: tokens.spaceExtraSmall),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: onGradient,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLoading)
                  Icon(
                    Icons.gps_fixed_rounded,
                    size: tokens.iconSizeSmall,
                    color: onGradient.withValues(alpha: 0.88),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeGradientActionButton extends StatelessWidget {
  const _HomeGradientActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final Color onGradient = theme.colorScheme.onPrimary;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: onGradient,
        backgroundColor: onGradient.withValues(alpha: 0.1),
        side: BorderSide(
          color: onGradient.withValues(alpha: 0.34),
          width: tokens.borderWidthThin,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: tokens.spaceSmall,
        ),
        minimumSize: const Size(0, kTilawaMinInteractiveDimension),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: onGradient,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HomeCountdownBadge extends StatelessWidget {
  const _HomeCountdownBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final Color onGradient = theme.colorScheme.onPrimary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: onGradient.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(
            family: TilawaRadiusFamily.pill,
            height: kTilawaMinInteractiveDimension,
          ),
        ),
        border: Border.all(
          color: onGradient.withValues(alpha: 0.2),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceSmall,
          vertical: tokens.spaceExtraSmall,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: onGradient,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HomePrayerVisual extends StatelessWidget {
  const _HomePrayerVisual({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Container(
      width: tokens.iconSizeLargePlus,
      height: tokens.iconSizeLargePlus,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.onPrimary.withValues(alpha: 0.16),
        border: Border.all(
          color: colorScheme.onPrimary.withValues(alpha: 0.28),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Icon(
        icon,
        size: tokens.iconSizeLarge,
        color: colorScheme.onPrimary,
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
