import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';

import '../../domain/entities/entities.dart';
import '../bloc/prayer_times_bloc.dart';
import '../widgets/widgets.dart';

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

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        titleSpacing: 20,
        title: Text(
          context.l10n.prayerTimes,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actionsPadding: const EdgeInsets.only(right: 12),
        actions: [
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surface.withValues(alpha: 0.30),
              foregroundColor: colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.explore_outlined),
            onPressed: () => context.push('/qibla'),
          ),
          const SizedBox(width: 8),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surface.withValues(alpha: 0.30),
              foregroundColor: colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.surface.withValues(alpha: 0.34),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(6),
                indicator: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                labelColor: colorScheme.onSurface,
                unselectedLabelColor: colorScheme.onPrimary.withValues(
                  alpha: 0.82,
                ),
                labelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                splashBorderRadius: BorderRadius.circular(16),
                tabs: [
                  Tab(text: context.l10n.today),
                  Tab(text: context.l10n.monthly),
                ],
              ),
            ),
          ),
        ),
      ),
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
          top: 12,
          bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
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
    final ColorScheme colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.prayerTimesTodaySchedule,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.prayerTimesTodayScheduleSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
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
