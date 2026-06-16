import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa/features/prayer_times/presentation/extensions/prayer_type_ui.dart';
import 'package:tilawa/features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart';
import 'package:tilawa/features/smart_khatma/smart_khatma.dart';
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
                    if (isSmartKhatmaEnabled()) ...[
                      const SmartKhatmaCard(),
                      SizedBox(height: context.tokens.spaceMedium),
                    ],
                    if (isTodayPlanEnabled()) ...[
                      const TodayPlanCard(),
                      SizedBox(height: context.tokens.spaceLarge),
                    ],
                    _SectionTitle(text: context.l10n.homeExploreTitle),
                    SizedBox(height: context.tokens.spaceSmall),
                    _QuickActionsGrid(
                      actions: [
                        _HomeQuickAction(
                          label: context.l10n.homeQuickQuran,
                          icon: Icons.menu_book_rounded,
                          onTap: () => _openReaderAndRefreshPlans(context),
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

  Future<void> _openReaderAndRefreshPlans(BuildContext context) async {
    await const QuranLastReadRoute().push(context);
    if (!context.mounted) {
      return;
    }
    if (isSmartKhatmaEnabled()) {
      context.read<KhatmaPlanBloc>().add(const KhatmaPlanStarted());
    }
    if (isTodayPlanEnabled()) {
      context.read<TodayPlanBloc>().add(const TodayPlanSourceChanged());
    }
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
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final nextPrayer = dashboard.nextPrayer;
    final Color onGradient = heroTokens.foregroundColor;

    return _HomeNextPrayerHeroCard(
      onTap: onOpenPrayer,
      semanticLabel: nextPrayer == null
          ? context.l10n.homeNextPrayerUnavailable
          : _nextPrayerSemantics(context, nextPrayer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nextPrayer == null)
            Text(
              context.l10n.homeNextPrayerUnavailable,
              style: theme.textTheme.titleLarge?.copyWith(
                color: onGradient,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            )
          else ...[
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
                          color: onGradient.withValues(
                            alpha: heroTokens.mutedForegroundOpacity,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _localizedPrayerName(context, nextPrayer.type),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: onGradient,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
                _HomePrayerVisual(icon: nextPrayer.type.icon),
              ],
            ),
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
            SizedBox(height: tokens.spaceExtraSmall),
            _HomeNextPrayerRemainingText(prayerTime: nextPrayer.time),
          ],
          SizedBox(height: tokens.spaceLarge),
          _HomeNextPrayerFooter(
            locationName: dashboard.locationLabel,
            isRefreshingLocation: isRefreshingLocation,
            onRefreshLocation: onRefreshLocation,
          ),
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
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color onGradient = heroTokens.foregroundColor;

    return _HomeNextPrayerHeroCard(
      onTap: onOpenPrayer,
      semanticLabel: context.l10n.homeNextPrayerUnavailable,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.spaceLarge,
        children: [
          TilawaLoadingIndicator(
            centered: false,
            strokeWidth: 2,
            color: onGradient,
          ),
          Text(
            context.l10n.homeNextPrayerUnavailable,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onGradient.withValues(
                alpha: heroTokens.mutedForegroundOpacity,
              ),
            ),
          ),
          _HomeNextPrayerFooter(
            locationName: null,
            isRefreshingLocation: true,
            onRefreshLocation: null,
          ),
        ],
      ),
    );
  }
}

/// Tappable hero card for the next-prayer summary.
class _HomeNextPrayerHeroCard extends StatelessWidget {
  const _HomeNextPrayerHeroCard({
    required this.child,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final BorderRadius borderRadius = BorderRadius.circular(
      tokens.radiusExtraLarge,
    );

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: heroTokens.gradientBottomEnd.withValues(
                alpha: tokens.opacityShadowStrong,
              ),
              blurRadius: tokens.blurShadow * 1.35,
              offset: tokens.shadowOffsetMedium,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Material(
            color: heroTokens.gradientBottomEnd,
            child: InkWell(
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: heroTokens.backgroundGradient,
                ),
                child: Padding(
                  padding: EdgeInsets.all(tokens.spaceLarge),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Footer row: refresh location (nested tap) + schedule affordance.
class _HomeNextPrayerFooter extends StatelessWidget {
  const _HomeNextPrayerFooter({
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
  });

  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color onGradient = heroTokens.foregroundColor;
    final String locationLabel =
        PrayerLocationLabelFormatter.abbreviatedLocationLabel(
          locationName: locationName,
          l10n: context.l10n,
        );

    final BorderRadius locationRadius = BorderRadius.circular(
      tokens.resolveRadius(
        family: TilawaRadiusFamily.pill,
        height: kTilawaMinInteractiveDimension,
      ),
    );

    return Row(
      spacing: tokens.spaceSmall,
      mainAxisAlignment: .spaceBetween,
      children: [
        Material(
          color: onGradient.withValues(
            alpha: heroTokens.locationChipFillOpacity,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: locationRadius,
            side: BorderSide(
              color: onGradient.withValues(
                alpha: heroTokens.locationChipBorderOpacity,
              ),
              width: tokens.borderWidthThin,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isRefreshingLocation ? null : onRefreshLocation,
            borderRadius: locationRadius,
            splashColor: onGradient.withValues(
              alpha: heroTokens.locationChipSplashOpacity,
            ),
            highlightColor: onGradient.withValues(
              alpha: heroTokens.locationChipHighlightOpacity,
            ),
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
                  children: [
                    if (isRefreshingLocation)
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
                    Text(
                      locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: onGradient,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.spaceExtraSmall,
          children: [
            Text(
              context.l10n.homePrayerTimesAction,
              style: theme.textTheme.labelLarge?.copyWith(
                color: onGradient.withValues(
                  alpha: heroTokens.footerForegroundOpacity,
                ),
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: tokens.iconSizeMedium,
              color: onGradient.withValues(
                alpha: heroTokens.footerForegroundOpacity,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Keeps the human countdown fresh without a heavy live ticker UI.
class _HomeNextPrayerRemainingText extends StatefulWidget {
  const _HomeNextPrayerRemainingText({required this.prayerTime});

  final DateTime prayerTime;

  @override
  State<_HomeNextPrayerRemainingText> createState() =>
      _HomeNextPrayerRemainingTextState();
}

class _HomeNextPrayerRemainingTextState
    extends State<_HomeNextPrayerRemainingText> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _scheduleTicker();
  }

  @override
  void didUpdateWidget(covariant _HomeNextPrayerRemainingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prayerTime != widget.prayerTime) {
      _scheduleTicker();
    }
  }

  void _scheduleTicker() {
    _ticker?.cancel();
    final Duration remaining = _remaining;
    if (remaining <= Duration.zero) {
      return;
    }

    final Duration interval = remaining < const Duration(hours: 1)
        ? const Duration(seconds: 1)
        : const Duration(minutes: 1);

    _ticker = Timer.periodic(interval, (_) {
      if (!mounted) {
        return;
      }
      if (_remaining <= Duration.zero) {
        _ticker?.cancel();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration get _remaining {
    final Duration difference = widget.prayerTime.difference(DateTime.now());
    return difference.isNegative ? Duration.zero : difference;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color onGradient = heroTokens.foregroundColor;

    return Text(
      _formatCountdown(context, _remaining),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: onGradient.withValues(alpha: heroTokens.mutedForegroundOpacity),
        fontWeight: FontWeight.w600,
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
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color onGradient = heroTokens.foregroundColor;

    return Container(
      width: tokens.iconSizeLargePlus,
      height: tokens.iconSizeLargePlus,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onGradient.withValues(
          alpha: heroTokens.locationChipFillOpacity,
        ),
        border: Border.all(
          color: onGradient.withValues(
            alpha: heroTokens.locationChipBorderOpacity,
          ),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Icon(
        icon,
        size: tokens.iconSizeLarge,
        color: onGradient,
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

    final colorScheme = theme.colorScheme;
    final tileFill = colorScheme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surface;

    return TilawaCard(
      surface: TilawaCardSurface.raised,
      backgroundColor: tileFill,
      padding: EdgeInsets.zero,
      onTap: action.onTap,
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

String _nextPrayerSemantics(BuildContext context, HomeNextPrayer nextPrayer) {
  return '${context.l10n.nextPrayer}: '
      '${_localizedPrayerName(context, nextPrayer.type)}. '
      '${_formatTime(context, nextPrayer.time)}. '
      '${_formatCountdown(context, nextPrayer.timeUntil)}.';
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
