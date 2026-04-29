import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';
import '../../domain/services/prayer_adhan_notification_service_interface.dart';
import '../bloc/prayer_times_bloc.dart';
import '../prayer_notification_semantics_ids.dart';
import '../widgets/widgets.dart';
import '../../../../shared/widgets/tilawa_back_button.dart';

/// Screen for displaying prayer times.
///
/// NOTE: This screen expects a [PrayerTimesBloc] to be provided in the widget tree.
/// The bloc is provided by [PrayerTimesRoute] in the router configuration.
class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Note: The PrayerTimesRoute already dispatches loadPrayerTimes event when creating the bloc.
    // No need to dispatch it again here.
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final tokens = theme.tokens;

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop() ? const TilawaBackButton() : null,
        title: Text(context.l10n.prayerTimes),
        actionsPadding: EdgeInsets.only(right: tokens.spaceMedium),
        actions: [
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surface.withValues(alpha: 0.30),
              foregroundColor: colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.explore_outlined, size: 22),
            onPressed: () => context.push('/qibla'),
          ),
          SizedBox(width: tokens.spaceSmall),
          Semantics(
            identifier: PrayerNotificationSemanticsIds.prayerSettingsButton,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surface.withValues(alpha: 0.30),
                foregroundColor: colorScheme.onPrimary,
              ),
              icon: const Icon(Icons.settings, size: 22),
              onPressed: () => _showSettingsDialog(context),
            ),
          ),
          SizedBox(width: tokens.spaceExtraSmall),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLarge,
              0,
              tokens.spaceLarge,
              tokens.spaceMedium,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(tokens.radiusLarge),
                border: Border.all(
                  color: colorScheme.surface.withValues(alpha: 0.34),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                indicator: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(tokens.radiusLarge - 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: colorScheme.onSurface,
                unselectedLabelColor: colorScheme.onPrimary.withValues(
                  alpha: 0.82,
                ),
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                splashBorderRadius: BorderRadius.circular(tokens.radiusLarge),
                tabs: [
                  Tab(text: context.l10n.today),
                  Tab(text: context.l10n.monthly),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: kDebugMode ? const _DebugNotificationFab() : null,
      body: BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
        buildWhen: (previous, current) {
          return previous.status != current.status ||
              previous.todayPrayerTimes != current.todayPrayerTimes ||
              previous.monthlyPrayerTimes != current.monthlyPrayerTimes ||
              previous.settings != current.settings ||
              previous.latitude != current.latitude ||
              previous.longitude != current.longitude ||
              previous.locationName != current.locationName ||
              previous.errorMessage != current.errorMessage ||
              previous.isLoadingLocation != current.isLoadingLocation ||
              previous.currentOrNextPrayer?.type !=
                  current.currentOrNextPrayer?.type;
        },
        builder: (context, state) {
          switch (state.status) {
            case PrayerTimesStatus.initial:
            case PrayerTimesStatus.loading:
              return const Center(child: CircularProgressIndicator());

            case PrayerTimesStatus.error:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(state.errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PrayerTimesBloc>().add(
                          const PrayerTimesEvent.loadPrayerTimes(),
                        );
                      },
                      child: Text(context.l10n.retry),
                    ),
                  ],
                ),
              );

            case PrayerTimesStatus.locationRequired:
              return _buildLocationRequiredView(context, state);

            case PrayerTimesStatus.loaded:
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildTodayView(context, state),
                  _buildMonthlyView(context, state),
                ],
              );
          }
        },
      ),
    );
  }

  Widget _buildLocationRequiredView(
    BuildContext context,
    PrayerTimesState state,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.locationRequired,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.locationRequiredDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (state.errorMessage.isNotEmpty) ...[
              Text(
                state.errorMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              onPressed: state.isLoadingLocation
                  ? null
                  : () {
                      context.read<PrayerTimesBloc>().add(
                        const PrayerTimesEvent.updateLocation(),
                      );
                    },
              icon: state.isLoadingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(context.l10n.enableLocation),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayView(BuildContext context, PrayerTimesState state) {
    if (state.todayPrayerTimes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final tokens = Theme.of(context).tokens;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PrayerTimesBloc>().add(
          const PrayerTimesEvent.loadPrayerTimes(),
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          top: tokens.spaceMedium,
          bottom: tokens.spaceExtraLarge,
        ),
        children: [
          PrayerTimesLocationHeader(
            locationName: state.locationName,
            onUpdateLocation: () {
              context.read<PrayerTimesBloc>().add(
                const PrayerTimesEvent.updateLocation(),
              );
            },
            isLoading: state.isLoadingLocation,
          ),
          const _CountdownCardSection(),
          const _TodaySectionHeader(),
          PrayerTimesGrid(
            prayerTimes: state.todayPrayerTimes!,
            currentPrayer: state.currentOrNextPrayer,
            use24HourFormat: state.settings.use24HourFormat,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyView(BuildContext context, PrayerTimesState state) {
    if (state.latitude == null || state.longitude == null) {
      return Center(child: Text(context.l10n.locationRequired));
    }

    return MonthlyPrayerTimesView(
      latitude: state.latitude!,
      longitude: state.longitude!,
      settings: state.settings,
    );
  }

  void _showSettingsDialog(BuildContext context) {
    // Capture the bloc before opening the modal bottom sheet
    // because the modal's context doesn't have access to the bloc
    final PrayerTimesBloc bloc = context.read<PrayerTimesBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) =>
          BlocProvider.value(value: bloc, child: const PrayerSettingsSheet()),
    );
  }
}

class _CountdownCardSection extends StatelessWidget {
  const _CountdownCardSection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      PrayerTimesBloc,
      PrayerTimesState,
      ({
        PrayerTimeItem? nextPrayer,
        Duration? timeUntilNextPrayer,
        bool use24HourFormat,
      })
    >(
      selector: (state) => (
        nextPrayer: state.currentOrNextPrayer,
        timeUntilNextPrayer: state.timeUntilNextPrayer,
        use24HourFormat: state.settings.use24HourFormat,
      ),
      builder: (context, countdown) {
        final PrayerTimeItem? nextPrayer = countdown.nextPrayer;
        final Duration? timeUntilNextPrayer = countdown.timeUntilNextPrayer;

        if (nextPrayer == null || timeUntilNextPrayer == null) {
          return const SizedBox.shrink();
        }

        return NextPrayerCountdownCard(
          nextPrayer: nextPrayer,
          timeUntil: timeUntilNextPrayer,
          use24HourFormat: countdown.use24HourFormat,
        );
      },
    );
  }
}

class _TodaySectionHeader extends StatelessWidget {
  const _TodaySectionHeader();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        tokens.spaceMedium,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(tokens.radiusMedium),
            ),
            child: Icon(
              Icons.schedule_rounded,
              size: 20,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          SizedBox(width: tokens.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.prayerTimesTodaySchedule,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.prayerTimesTodayScheduleSubtitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Debug-only FAB that fires an immediate test prayer notification.
/// Shown only in [kDebugMode] — stripped from release builds.
class _DebugNotificationFab extends StatefulWidget {
  const _DebugNotificationFab();

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
      await getIt<IPrayerAdhanNotificationService>().fireTestNotification(
        prayer: _selectedPrayer,
        playAdhan: _playAdhan,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔔 Test fired: ${_selectedPrayer.name} (adhan=$_playAdhan)',
            ),
            duration: const Duration(seconds: 2),
          ),
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
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
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
