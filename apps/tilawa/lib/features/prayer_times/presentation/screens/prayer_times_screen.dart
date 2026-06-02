import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/utils/toast_utils.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/fire_prayer_test_notification_use_case.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/entities.dart';
import '../../domain/prayer_times_clock.dart';
import '../../domain/services/adhan_alarm_player_interface.dart';
import '../bloc/prayer_permissions_cubit.dart';
import '../bloc/prayer_times_bloc.dart';
import '../config/prayer_times_screen_loading_preview.dart';
import '../formatters/prayer_location_label_formatter.dart';
import '../layout/prayer_times_layout.dart';
import '../mappers/prayer_row_view_data_mapper.dart';
import '../models/prayer_row_view_data.dart';
import '../prayer_notification_semantics_ids.dart';
import '../widgets/prayer_notification_settings_sheet.dart';
import '../widgets/widgets.dart';

/// Screen for displaying prayer times.
///
/// NOTE: This screen expects a [PrayerTimesBloc] to be provided in the widget tree.
/// The bloc is provided by [PrayerTimesRoute] in the router configuration.
class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({
    super.key,
    required this.adhanPlayer,
    required this.fireTestNotification,
  });

  final IAdhanAlarmPlayer adhanPlayer;
  final FirePrayerTestNotificationUseCase fireTestNotification;

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const int _tabCount = 2;

  late final TabController _tabController;
  Timer? _midnightRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightRefreshTimer();
  }

  @override
  void dispose() {
    _midnightRefreshTimer?.cancel();
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) {
      return;
    }

    _onAppResumed();
    _scheduleMidnightRefreshTimer();
  }

  /// After the system location dialog closes, retry a stuck load instead of
  /// [refreshIfStale], which is ignored while [PrayerTimesStatus.loading].
  void _onAppResumed() {
    if (!mounted) {
      return;
    }

    final PrayerTimesBloc bloc = context.read<PrayerTimesBloc>();
    final PrayerTimesStatus status = bloc.state.status;

    if (status == PrayerTimesStatus.loading ||
        status == PrayerTimesStatus.locationRequired) {
      bloc.add(const PrayerTimesEvent.loadPrayerTimes(forceReschedule: true));
      return;
    }

    _dispatchRefreshIfStale();
  }

  void _onSegmentChanged(String value) {
    final int index = value == 'today' ? 0 : 1;
    if (_tabController.index == index && !_tabController.indexIsChanging) {
      return;
    }
    _tabController.animateTo(index);
  }

  void _scheduleMidnightRefreshTimer() {
    _midnightRefreshTimer?.cancel();

    final now = PrayerTimesClock.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now);

    _midnightRefreshTimer = Timer(
      delay.isNegative || delay == Duration.zero
          ? const Duration(seconds: 1)
          : delay,
      () {
        if (!mounted) {
          return;
        }

        _dispatchRefreshIfStale();
        _scheduleMidnightRefreshTimer();
      },
    );
  }

  void _dispatchRefreshIfStale() {
    if (!mounted) {
      return;
    }

    context.read<PrayerTimesBloc>().add(
      const PrayerTimesEvent.refreshIfStale(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      // Parchment surface when opened as a standalone route (debug route list,
      // deep links). In the main tab the shell still paints behind us, but an
      // opaque surface avoids the black void from a transparent scaffold.
      backgroundColor: theme.colorScheme.surface,
      // floatingActionButton: kDebugMode ? const _DebugNotificationFab() : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _PrayerTimesAmbientBackground()),
          BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
            buildWhen: (previous, current) {
              return previous.status != current.status ||
                  previous.todayPrayerTimes != current.todayPrayerTimes ||
                  previous.monthlyPrayerTimes != current.monthlyPrayerTimes ||
                  previous.settings != current.settings ||
                  previous.latitude != current.latitude ||
                  previous.longitude != current.longitude ||
                  previous.locationName != current.locationName ||
                  previous.errorMessage != current.errorMessage ||
                  previous.isLoadingLocation != current.isLoadingLocation;
            },
            builder: (context, state) {
              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverOverlapAbsorber(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                      sliver: PrayerTimesAppBar(
                        tabController: _tabController,
                        onSegmentChanged: _onSegmentChanged,
                        onSettingsTap: () => _showSettingsDialog(context),
                      ),
                    ),
                  ];
                },
                body: _buildBody(context, state),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, PrayerTimesState state) {
    if (PrayerTimesScreenLoadingPreview.enabled) {
      return _nonScrollableBody(_prayerTimesLoadingIndicator(context));
    }

    switch (state.status) {
      case PrayerTimesStatus.initial:
      case PrayerTimesStatus.loading:
        return _nonScrollableBody(_prayerTimesLoadingIndicator(context));

      case PrayerTimesStatus.error:
        return _nonScrollableBody(
          TilawaIllustratedState(
            visual: const TilawaStateVisual(
              icon: Icons.event_busy_rounded,
              tone: TilawaStateVisualTone.error,
            ),
            title: state.errorMessage,
            semanticLabel: state.errorMessage,
            primaryAction: TilawaButton(
              text: context.l10n.retry,
              variant: TilawaButtonVariant.secondary,
              leadingIcon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                context.read<PrayerTimesBloc>().add(
                  const PrayerTimesEvent.loadPrayerTimes(),
                );
              },
            ),
          ),
        );

      case PrayerTimesStatus.locationRequired:
        return _nonScrollableBody(_buildLocationRequiredView(context, state));

      case PrayerTimesStatus.loaded:
        return TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(
            parent: PageScrollPhysics(),
          ),
          children: [
            _buildTodayView(context, state),
            _buildMonthlyView(context, state),
          ],
        );
    }
  }

  /// Wraps a non-scrollable body in a CustomScrollView so NestedScrollView's
  /// header overlap is properly absorbed even when there's nothing to scroll.
  Widget _nonScrollableBody(Widget child) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverFillRemaining(hasScrollBody: false, child: child),
          ],
        );
      },
    );
  }

  Widget _prayerTimesLoadingIndicator(BuildContext context) {
    return Semantics(
      label: context.l10n.prayerTimesLoading,
      child: TilawaLoadingIndicator(
        semanticsLabel: context.l10n.prayerTimesLoading,
      ),
    );
  }

  Widget _buildLocationRequiredView(
    BuildContext context,
    PrayerTimesState state,
  ) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return TilawaIllustratedState(
      visual: const TilawaStateVisual(
        icon: Icons.my_location_rounded,
        tone: TilawaStateVisualTone.tertiary,
      ),
      title: context.l10n.locationRequired,
      subtitle: context.l10n.locationRequiredDescription,
      semanticLabel: context.l10n.locationRequired,
      primaryAction: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.errorMessage.isNotEmpty) ...[
            Text(
              state.errorMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spaceMedium),
          ],
          TilawaButton(
            text: context.l10n.enableLocation,
            leadingIcon: const Icon(Icons.my_location_rounded),
            isLoading: state.isLoadingLocation,
            onPressed: state.isLoadingLocation
                ? null
                : () {
                    context.read<PrayerTimesBloc>().add(
                      const PrayerTimesEvent.updateLocation(),
                    );
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildTodayView(BuildContext context, PrayerTimesState state) {
    if (state.todayPrayerTimes == null) {
      return _nonScrollableBody(_prayerTimesLoadingIndicator(context));
    }

    final tokens = Theme.of(context).tokens;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PrayerTimesBloc>().add(
          const PrayerTimesEvent.loadPrayerTimes(),
        );
      },
      edgeOffset: prayerTimesRefreshIndicatorEdgeOffset(context),
      child: Builder(
        builder: (context) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.only(
                  top: tokens.spaceSmall,
                  bottom: prayerTimesScrollBottomPadding(context),
                ),
                sliver: SliverList.list(
                  children: [
                    _AdhanPlayingBanner(adhanPlayer: widget.adhanPlayer),
                    _LocationUtilityCard(
                      locationName: state.locationName,
                      onUpdateLocation: () {
                        context.read<PrayerTimesBloc>().add(
                          const PrayerTimesEvent.updateLocation(),
                        );
                      },
                      isLoading: state.isLoadingLocation,
                    ),
                    _CountdownCardSection(),
                    _TodayPrayerList(
                      prayerTimes: state.todayPrayerTimes!,
                      settings: state.settings,
                    ),
                    _BottomUtilitiesCard(
                      onOpenQibla: () => const QiblaRoute().push(context),
                      onManageAlertsTap: () => _showNotificationDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthlyView(BuildContext context, PrayerTimesState state) {
    if (state.latitude == null || state.longitude == null) {
      return TilawaIllustratedState(
        visual: const TilawaStateVisual(
          icon: Icons.my_location_rounded,
          tone: TilawaStateVisualTone.tertiary,
        ),
        title: context.l10n.locationRequired,
        subtitle: context.l10n.locationRequiredDescription,
        semanticLabel: context.l10n.locationRequired,
      );
    }

    return MonthlyPrayerTimesView(
      latitude: state.latitude!,
      longitude: state.longitude!,
    );
  }

  void _showSettingsDialog(BuildContext context) {
    // Capture the bloc before opening the modal bottom sheet
    // because the modal's context doesn't have access to the bloc
    final PrayerTimesBloc bloc = context.read<PrayerTimesBloc>();
    final PrayerPermissionsCubit permissionsCubit = context
        .read<PrayerPermissionsCubit>();

    showTilawaModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: TilawaBottomSheetScaffold.modalShape(context),
      builder: (modalContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: permissionsCubit),
        ],
        child: const PrayerSettingsSheet(),
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    final PrayerTimesBloc bloc = context.read<PrayerTimesBloc>();
    final PrayerPermissionsCubit permissionsCubit = context
        .read<PrayerPermissionsCubit>();

    showTilawaModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: TilawaBottomSheetScaffold.modalShape(context),
      builder: (modalContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: permissionsCubit),
        ],
        child: const PrayerNotificationSettingsSheet(),
      ),
    );
  }
}

class _CountdownCardSection extends StatelessWidget {
  const _CountdownCardSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
      buildWhen: (previous, current) =>
          previous.todayPrayerTimes != current.todayPrayerTimes ||
          previous.settings != current.settings,
      builder: (context, state) {
        final todayTimes = state.todayPrayerTimes;
        if (todayTimes == null) return const SizedBox.shrink();

        return _CountdownTicker(
          prayerTimes: todayTimes,
          settings: state.settings,
          dateMetaLabel: _buildDateMetaLabel(context),
        );
      },
    );
  }

  static String _buildDateMetaLabel(BuildContext context) {
    final isArabic = context.isArabic;
    final locale = isArabic ? 'ar' : 'en';
    final now = PrayerTimesClock.now();
    final dayName = DateFormat('EEEE', locale).format(now);
    var fullDate = DateFormat.yMMMMd(locale).format(now);

    if (isArabic) {
      fullDate = _normalizeArabicDigits(fullDate);
    }

    return '${context.l10n.today} · $dayName, $fullDate';
  }

  static String _normalizeArabicDigits(String value) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    var normalized = value;
    for (var i = 0; i < arabicNumbers.length; i++) {
      normalized = normalized.replaceAll(arabicNumbers[i], englishNumbers[i]);
    }
    return normalized;
  }
}

class _PrayerTimesAmbientBackground extends StatelessWidget {
  const _PrayerTimesAmbientBackground();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExcludeSemantics(
      child: CustomPaint(
        painter: _PrayerTimesAmbientPainter(
          colorScheme: theme.colorScheme,
          tokens: theme.tokens,
        ),
      ),
    );
  }
}

class _PrayerTimesAmbientPainter extends CustomPainter {
  const _PrayerTimesAmbientPainter({
    required this.colorScheme,
    required this.tokens,
  });

  final ColorScheme colorScheme;
  final TilawaDesignTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final firstCenter = Offset(size.width * 0.08, size.height * 0.18);
    final secondCenter = Offset(size.width * 0.92, size.height * 0.64);

    final primaryStroke = Paint()
      ..color = colorScheme.primary.withValues(
        alpha: tokens.opacitySubtle * 0.42,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.borderWidthThin;
    final tertiaryStroke = Paint()
      ..color = colorScheme.tertiary.withValues(
        alpha: tokens.opacitySubtle * 0.32,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.borderWidthThin;

    for (final radiusFactor in <double>[0.44, 0.68]) {
      final rect = Rect.fromCircle(
        center: firstCenter,
        radius: shortest * radiusFactor,
      );
      canvas.drawArc(
        rect,
        -math.pi * 0.08,
        math.pi * 0.54,
        false,
        primaryStroke,
      );
    }

    for (final radiusFactor in <double>[0.5, 0.76]) {
      final rect = Rect.fromCircle(
        center: secondCenter,
        radius: shortest * radiusFactor,
      );
      canvas.drawArc(
        rect,
        math.pi * 0.9,
        math.pi * 0.48,
        false,
        tertiaryStroke,
      );
    }
  }

  @override
  bool shouldRepaint(_PrayerTimesAmbientPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme ||
        oldDelegate.tokens != tokens;
  }
}

/// Rebuilds itself every second using a single owned [Timer.periodic].
///
/// Replaces an earlier `StreamBuilder` + inline `Stream.periodic` that crashed
/// with "Stream has already been listened to" on rebuilds, since
/// `Stream.periodic` is single-subscription and was being recreated each build.
class _CountdownTicker extends StatefulWidget {
  const _CountdownTicker({
    required this.prayerTimes,
    required this.settings,
    required this.dateMetaLabel,
  });

  final PrayerTimeEntity prayerTimes;
  final PrayerSettingsEntity settings;
  final String dateMetaLabel;

  @override
  State<_CountdownTicker> createState() => _CountdownTickerState();
}

class _CountdownTickerState extends State<_CountdownTicker> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayer = widget.prayerTimes.getCurrentOrNextPrayer();
    final timeUntil = widget.prayerTimes.getTimeUntilNextPrayer();

    if (nextPrayer == null || timeUntil == null) {
      return const SizedBox.shrink();
    }

    final showAlertChipLabels = context.select<SettingsCubit, bool>(
      (c) => c.state.showPrayerTimesAlertChipLabels,
    );

    final heroRow = PrayerRowViewDataMapper.rowForPrayerItem(
      prayerTimes: widget.prayerTimes,
      settings: widget.settings,
      item: nextPrayer,
      currentPrayer: nextPrayer,
      l10n: context.l10n,
      isArabic: context.isArabic,
    );

    return NextPrayerCountdownCard(
      nextPrayer: nextPrayer,
      timeUntil: timeUntil,
      use24HourFormat: widget.settings.use24HourFormat,
      dateMetaLabel: widget.dateMetaLabel,
      alert: heroRow.alert,
      showPrayerTimeChipLabels: showAlertChipLabels,
      onAlertTap: heroRow.alert.supportsAlerts
          ? () => _openPrayerAlertQuickSheet(
              context,
              settings: widget.settings,
              row: heroRow,
            )
          : null,
      alertTooltip: heroRow.alert.supportsAlerts
          ? context.l10n.prayerNotifications
          : null,
    );
  }
}

/// Wraps [PrayerTimesGrid] with a low-frequency timer that only rebuilds when
/// the "current prayer" changes (checked once per minute — current prayer can
/// only change a handful of times a day, so a 1s tick was wasteful).
class _TodayPrayerList extends StatefulWidget {
  const _TodayPrayerList({required this.prayerTimes, required this.settings});

  final PrayerTimeEntity prayerTimes;
  final PrayerSettingsEntity settings;

  @override
  State<_TodayPrayerList> createState() => _TodayPrayerListState();
}

class _TodayPrayerListState extends State<_TodayPrayerList> {
  Timer? _ticker;
  PrayerTimeItem? _currentPrayer;

  @override
  void initState() {
    super.initState();
    _currentPrayer = widget.prayerTimes.getCurrentOrNextPrayer();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      final next = widget.prayerTimes.getCurrentOrNextPrayer();
      if (next != _currentPrayer) {
        setState(() => _currentPrayer = next);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _TodayPrayerList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prayerTimes != widget.prayerTimes) {
      _currentPrayer = widget.prayerTimes.getCurrentOrNextPrayer();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _TodayPrayerListSection(
      prayerTimes: widget.prayerTimes,
      settings: widget.settings,
      currentPrayer: _currentPrayer,
    );
  }
}

class _LocationUtilityCard extends StatelessWidget {
  const _LocationUtilityCard({
    required this.locationName,
    required this.isLoading,
    required this.onUpdateLocation,
  });

  final String? locationName;
  final bool isLoading;
  final VoidCallback onUpdateLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        0,
        tokens.spaceLarge,
        0,
      ),
      child: TilawaCard(
        surface: TilawaCardSurface.raised,
        // docs/tilawa_brand.md §5 — `card` family.
        borderRadius: tokens.resolveRadius(family: TilawaRadiusFamily.card),
        backgroundColor: colorScheme.surface,
        onTap: isLoading ? null : onUpdateLocation,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceSmall,
          vertical: tokens.spaceSmall,
        ),
        child: _UtilityActionRow(
          icon: Icons.location_on_outlined,
          label: PrayerLocationLabelFormatter.abbreviatedLocationLabel(
            locationName: locationName,
            l10n: context.l10n,
          ),
          trailing: isLoading
              ? SizedBox(
                  width: tokens.iconSizeSmall,
                  height: tokens.iconSizeSmall,
                  child: TilawaLoadingIndicator(
                    centered: false,
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              : Icon(
                  Icons.gps_fixed_rounded,
                  size: tokens.iconSizeSmall,
                  color: colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }
}

class _BottomUtilitiesCard extends StatelessWidget {
  const _BottomUtilitiesCard({
    required this.onOpenQibla,
    required this.onManageAlertsTap,
  });

  final VoidCallback onOpenQibla;
  final VoidCallback onManageAlertsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        0,
      ),
      child: TilawaCard(
        surface: TilawaCardSurface.raised,
        // docs/tilawa_brand.md §5 — `card` family.
        borderRadius: tokens.resolveRadius(family: TilawaRadiusFamily.card),
        backgroundColor: colorScheme.surface,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceSmall,
          vertical: tokens.spaceExtraSmall,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = PrayerTimesLayout.isNarrowWidth(
              constraints.maxWidth,
            );
            if (narrow) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _UtilityInlineAction(
                    icon: Icons.explore_outlined,
                    label: context.l10n.qiblaDirection,
                    onTap: onOpenQibla,
                    labelMaxLines: 2,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: tokens.spaceExtraSmall,
                    ),
                    child: Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(
                        alpha: tokens.opacityMedium,
                      ),
                    ),
                  ),
                  _UtilityInlineAction(
                    semanticsId: PrayerNotificationSemanticsIds
                        .prayerNotificationsEntryPoint,
                    icon: Icons.tune_rounded,
                    label: context.l10n.manageAlerts,
                    onTap: onManageAlertsTap,
                    labelMaxLines: 2,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _UtilityInlineAction(
                    icon: Icons.explore_outlined,
                    label: context.l10n.qiblaDirection,
                    onTap: onOpenQibla,
                  ),
                ),
                SizedBox(
                  height: tokens.spaceExtraLarge,
                  child: VerticalDivider(
                    width: tokens.spaceMedium,
                    color: colorScheme.outlineVariant.withValues(
                      alpha: tokens.opacityMedium,
                    ),
                  ),
                ),
                Expanded(
                  child: _UtilityInlineAction(
                    semanticsId: PrayerNotificationSemanticsIds
                        .prayerNotificationsEntryPoint,
                    icon: Icons.tune_rounded,
                    label: context.l10n.manageAlerts,
                    onTap: onManageAlertsTap,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UtilityInlineAction extends StatelessWidget {
  const _UtilityInlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.semanticsId,
    this.labelMaxLines = 1,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? semanticsId;
  final int labelMaxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    // Concentric corner rule: row radius = card radius - card horizontal padding.
    // _BottomUtilitiesCard: cardRadius=radiusExtraLarge, hPad=spaceSmall.
    final double inkRadius = tokens.concentricInner(
      outerRadius: tokens.resolveRadius(family: TilawaRadiusFamily.card),
      padding: tokens.spaceSmall,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(inkRadius),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: context.minInteractiveDimension,
          ),
          child: _UtilityActionRow(
            semanticsId: semanticsId,
            icon: icon,
            label: label,
            labelMaxLines: labelMaxLines,
            trailing: Icon(
              Icons.chevron_right,
              size: tokens.iconSizeMedium,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _UtilityActionRow extends StatelessWidget {
  const _UtilityActionRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.semanticsId,
    this.labelMaxLines = 1,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final String? semanticsId;
  final int labelMaxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final rowContent = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: tokens.spaceExtraSmall,
      ),
      child: Row(
        spacing: tokens.spaceSmall,
        children: [
          Icon(
            icon,
            size: tokens.iconSizeSmall,
            color: colorScheme.onSurfaceVariant,
          ),
          Expanded(
            child: Text(
              label,
              maxLines: labelMaxLines,
              softWrap: labelMaxLines > 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );

    return Semantics(identifier: semanticsId, child: rowContent);
  }
}

void _openPrayerAlertQuickSheet(
  BuildContext context, {
  required PrayerSettingsEntity settings,
  required PrayerRowViewData row,
}) {
  final bloc = context.read<PrayerTimesBloc>();
  showTilawaModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    builder: (modalContext) => BlocProvider.value(
      value: bloc,
      child: _PrayerAlertQuickSheet(
        row: row,
        onModeSelected: (mode) {
          final updated = PrayerRowViewDataMapper.updatedAlertModeSettings(
            settings,
            row.type,
            mode,
          );
          if (updated == null) return;
          bloc.add(PrayerTimesEvent.updateSettings(updated));
          Navigator.of(modalContext).pop();
        },
      ),
    ),
  );
}

class _TodayPrayerListSection extends StatelessWidget {
  const _TodayPrayerListSection({
    required this.prayerTimes,
    required this.settings,
    required this.currentPrayer,
  });

  final PrayerTimeEntity prayerTimes;
  final PrayerSettingsEntity settings;
  final PrayerTimeItem? currentPrayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final bool isArabic = context.isArabic;
    final showAlertChipLabels = context.select<SettingsCubit, bool>(
      (c) => c.state.showPrayerTimesAlertChipLabels,
    );

    final rows = PrayerRowViewDataMapper.map(
      prayerTimes: prayerTimes,
      settings: settings,
      currentPrayer: currentPrayer,
      l10n: context.l10n,
      isArabic: isArabic,
      omitFromListWhenSameInstantAs: currentPrayer,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        0,
      ),
      child: TilawaCard(
        surface: TilawaCardSurface.raised,
        // docs/tilawa_brand.md §5 — `card` family.
        borderRadius: tokens.resolveRadius(family: TilawaRadiusFamily.card),
        backgroundColor: colorScheme.surface,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: tokens.spaceSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spaceTiny,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceExtraSmall,
                tokens.spaceTiny,
                tokens.spaceExtraSmall,
                tokens.spaceExtraSmall,
              ),
              child: Text(
                context.l10n.prayerTimesTodaySchedule,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...rows.map((row) {
              return _TodayPrayerListRow(
                row: row,
                prayerName: row.prayerName,
                prayerTime: row.prayerTime,
                statusText: row.statusText,
                isCurrent: row.isCurrent,
                hasPassed: row.hasPassed,
                isSecondary: row.isSecondary,
                showAlertIndicators: row.showAlertIndicators,
                showAlertChipLabels: showAlertChipLabels,
                onTap: row.alert.supportsAlerts
                    ? () => _showPrayerAlertSheet(context, row)
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showPrayerAlertSheet(BuildContext context, PrayerRowViewData row) {
    _openPrayerAlertQuickSheet(context, settings: settings, row: row);
  }
}

class _TodayPrayerListRow extends StatelessWidget {
  const _TodayPrayerListRow({
    required this.row,
    required this.prayerName,
    required this.prayerTime,
    required this.statusText,
    required this.isCurrent,
    required this.hasPassed,
    required this.isSecondary,
    required this.showAlertIndicators,
    required this.showAlertChipLabels,
    required this.onTap,
  });

  final PrayerRowViewData row;
  final String prayerName;
  final String prayerTime;
  final String statusText;
  final bool isCurrent;
  final bool hasPassed;
  final bool isSecondary;
  final bool showAlertIndicators;
  final bool showAlertChipLabels;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final Color emphasisColor = isCurrent
        ? colorScheme.primary
        : colorScheme.onSurface;
    final double rowAlpha = isSecondary
        ? tokens.opacityEmphasis
        : (hasPassed ? tokens.opacityEmphasis : 1);

    // Concentric corner rule: row radius = card radius - card horizontal padding.
    // _TodayPrayerListSection: cardRadius=radiusExtraLarge, hPad=spaceMedium.
    final double rowRadius = tokens.concentricInner(
      outerRadius: tokens.resolveRadius(family: TilawaRadiusFamily.card),
      padding: tokens.spaceMedium,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(rowRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(rowRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isCurrent
                ? colorScheme.primaryContainer.withValues(
                    alpha: tokens.opacityMedium,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(rowRadius),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: tokens.minInteractiveDimension,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: tokens.spaceExtraSmall + tokens.spaceTiny,
                horizontal: tokens.spaceSmall,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = PrayerTimesLayout.isNarrowWidth(
                    constraints.maxWidth,
                  );
                  final bool abbreviatedChipLabels =
                      showAlertChipLabels && !narrow;
                  final TextStyle nameStyle = theme.textTheme.titleSmall!
                      .copyWith(
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w600,
                        height: 1.2,
                        color: emphasisColor.withValues(alpha: rowAlpha),
                      );
                  final TextStyle statusStyle = theme.textTheme.labelSmall!
                      .copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                        color: isCurrent
                            ? colorScheme.primary.withValues(
                                alpha: rowAlpha * 0.92,
                              )
                            : colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.92,
                              ),
                      );
                  final TextStyle timeStyle = theme.textTheme.titleSmall!
                      .copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: emphasisColor.withValues(alpha: rowAlpha),
                      );

                  final Widget leftBlock = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(prayerName, style: nameStyle),
                      if (statusText.isNotEmpty)
                        Text(statusText, style: statusStyle),
                    ],
                  );

                  final Widget trailingBlock = Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        prayerTime,
                        style: timeStyle,
                        textAlign: TextAlign.end,
                      ),
                      if (showAlertIndicators) ...[
                        SizedBox(width: tokens.spaceSmall),
                        PrayerAlertStatusChip(
                          alert: row.alert,
                          showLabel: narrow
                              ? abbreviatedChipLabels
                              : showAlertChipLabels,
                          dense: true,
                          quiet: true,
                        ),
                      ],
                    ],
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: leftBlock),
                      SizedBox(width: tokens.spaceSmall),
                      trailingBlock,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerAlertQuickSheet extends StatelessWidget {
  const _PrayerAlertQuickSheet({
    required this.row,
    required this.onModeSelected,
  });

  final PrayerRowViewData row;
  final ValueChanged<PrayerAlertMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final bottomPadding = context.floatingBottomPadding;
    final currentMode = _modeForState(row.alert.state);
    final bp = TilawaBottomSheetScaffold.resolvedBodyPadding(context);
    final paddedBody = bp.copyWith(bottom: bp.bottom + bottomPadding);

    return SafeArea(
      top: false,
      child: TilawaBottomSheetScaffold(
        showHandle: true,
        children: [
          Padding(
            padding: paddedBody,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.spaceExtraSmall,
              children: [
                Text(
                  row.prayerName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${row.prayerTime} · ${context.l10n.prayerNotifications}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: tokens.spaceMedium),
                _AlertModeTile(
                  title: context.l10n.prayerAlertModeOff,
                  subtitle: context.l10n.prayerAlertModeOffDescription,
                  icon: Icons.notifications_off_outlined,
                  value: PrayerAlertMode.none,
                  groupValue: currentMode,
                  onChanged: onModeSelected,
                ),
                _AlertModeTile(
                  title: context.l10n.prayerAlertModeNotifyOnly,
                  subtitle: context.l10n.prayerAlertModeNotifyOnlyDescription,
                  icon: Icons.notifications_active_outlined,
                  value: PrayerAlertMode.notification,
                  groupValue: currentMode,
                  onChanged: onModeSelected,
                ),
                if (row.alert.supportsAdhan)
                  _AlertModeTile(
                    title: context.l10n.prayerAlertModeAdhan,
                    subtitle: context.l10n.prayerAlertModeAdhanDescription,
                    icon: Icons.volume_up_outlined,
                    value: PrayerAlertMode.adhan,
                    groupValue: currentMode,
                    onChanged: onModeSelected,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PrayerAlertMode _modeForState(PrayerAlertViewState state) {
    return switch (state) {
      PrayerAlertViewState.off => PrayerAlertMode.none,
      PrayerAlertViewState.notification => PrayerAlertMode.notification,
      PrayerAlertViewState.adhan => PrayerAlertMode.adhan,
    };
  }
}

class _AlertModeTile extends StatelessWidget {
  const _AlertModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final PrayerAlertMode value;
  final PrayerAlertMode groupValue;
  final ValueChanged<PrayerAlertMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final selected = value == groupValue;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceSmall),
      child: TilawaCard(
        surface: TilawaCardSurface.flat,
        backgroundColor: selected
            ? theme.colorScheme.primaryContainer.withValues(
                alpha: tokens.opacitySubtle,
              )
            : theme.colorScheme.surfaceContainerLowest,
        borderColor: selected
            ? theme.colorScheme.primary.withValues(alpha: tokens.opacityMedium)
            : theme.colorScheme.outlineVariant.withValues(
                alpha: tokens.opacityMedium,
              ),
        // docs/tilawa_brand.md §5 — `chrome` family: tile nested inside the sheet.
        borderRadius: tokens.resolveRadius(family: TilawaRadiusFamily.chrome),
        onTap: selected ? null : () => onChanged(value),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: tokens.spaceSmall,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: tokens.iconSizeMedium,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: tokens.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.spaceExtraSmall / 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: tokens.iconSizeMedium,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdhanPlayingBanner extends StatefulWidget {
  const _AdhanPlayingBanner({required this.adhanPlayer});

  final IAdhanAlarmPlayer adhanPlayer;

  @override
  State<_AdhanPlayingBanner> createState() => _AdhanPlayingBannerState();
}

class _AdhanPlayingBannerState extends State<_AdhanPlayingBanner>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  bool _isStopping = false;
  Timer? _pollTimer;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final playing = await widget.adhanPlayer.isAdhanPlaying();
      if (!mounted || playing == _isPlaying) return;
      setState(() => _isPlaying = playing);
      if (playing) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.animateTo(0.0);
      }
    } catch (_) {}
  }

  Future<void> _stop() async {
    if (_isStopping) return;
    setState(() => _isStopping = true);
    try {
      await widget.adhanPlayer.stopCurrentAdhan();
    } finally {
      if (mounted) {
        setState(() {
          _isStopping = false;
          _isPlaying = false;
        });
        _pulseController.animateTo(0.0);
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _isPlaying ? _buildBanner(context) : const SizedBox.shrink(),
    );
  }

  Widget _buildBanner(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        0,
        tokens.spaceLarge,
        tokens.spaceSmall,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(
            tokens.resolveRadius(family: TilawaRadiusFamily.card),
          ),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: tokens.opacityMedium),
            width: tokens.borderWidthThin,
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: tokens.spaceSmall,
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, child) =>
                  Transform.scale(scale: _pulseAnimation.value, child: child),
              child: Icon(
                Icons.notifications_active_rounded,
                size: tokens.iconSizeMedium,
                color: colorScheme.error,
              ),
            ),
            SizedBox(width: tokens.spaceSmall),
            Expanded(
              child: Text(
                context.l10n.adhanIsPlaying,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
            SizedBox(width: tokens.spaceSmall),
            TilawaButton(
              text: context.l10n.stopAdhan,
              variant: TilawaButtonVariant.danger,
              size: TilawaButtonSize.small,
              isLoading: _isStopping,
              onPressed: _isStopping ? null : _stop,
            ),
          ],
        ),
      ),
    );
  }
}

/// Debug-only FAB that fires an immediate test prayer notification.
/// Shown only in [kDebugMode] — stripped from release builds.
class _DebugNotificationFab extends StatefulWidget {
  const _DebugNotificationFab({required this.fireTestNotification});

  final FirePrayerTestNotificationUseCase fireTestNotification;

  @override
  State<_DebugNotificationFab> createState() => _DebugNotificationFabState();
}

class _DebugNotificationFabState extends State<_DebugNotificationFab> {
  PrayerType _selectedPrayer = PrayerType.isha;
  bool _playAdhan = true;
  bool _firing = false;

  static const List<PrayerType> _prayers = [
    PrayerType.fajr,
    PrayerType.dhuhr,
    PrayerType.asr,
    PrayerType.maghrib,
    PrayerType.isha,
  ];

  Future<void> _fire() async {
    if (_firing) return;
    setState(() => _firing = true);
    try {
      await widget.fireTestNotification(
        prayer: _selectedPrayer,
        playAdhan: _playAdhan,
      );
      if (mounted) {
        ToastUtils.showToast(
          msg: '🔔 Test fired: ${_selectedPrayer.name} (adhan=$_playAdhan)',
        );
      }
    } finally {
      if (mounted) setState(() => _firing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Options card
        Card(
          margin: const EdgeInsets.only(bottom: 8, right: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debug: Test Notification',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButton<PrayerType>(
                  value: _selectedPrayer,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: _prayers
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name, style: theme.textTheme.bodySmall),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPrayer = v);
                  },
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Adhan', style: theme.textTheme.bodySmall),
                    Switch(
                      value: _playAdhan,
                      onChanged: (v) => setState(() => _playAdhan = v),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        FloatingActionButton.extended(
          onPressed: _firing ? null : _fire,
          label: _firing
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: TilawaLoadingIndicator(
                    centered: false,
                    strokeWidth: 2,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                )
              : const Text('Fire'),
          icon: const Icon(Icons.notifications_active_outlined),
          backgroundColor: theme.colorScheme.errorContainer,
          foregroundColor: theme.colorScheme.onErrorContainer,
        ),
      ],
    );
  }
}
