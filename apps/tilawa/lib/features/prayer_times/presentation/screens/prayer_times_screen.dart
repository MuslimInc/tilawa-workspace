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
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.prayerTimes),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            onPressed: () => context.push('/qibla'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.l10n.today),
            Tab(text: context.l10n.monthly),
          ],
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
                      child: const Text('Retry'),
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 8).copyWith(bottom: 120),
        child: Column(
          children: [
            // Location header
            PrayerTimesLocationHeader(
              locationName: state.locationName,
              onUpdateLocation: () {
                context.read<PrayerTimesBloc>().add(
                  const PrayerTimesEvent.updateLocation(),
                );
              },
              isLoading: state.isLoadingLocation,
            ),

            // Next prayer countdown
            const _CountdownCardSection(),

            // Prayer times grid
            PrayerTimesGrid(
              prayerTimes: state.todayPrayerTimes!,
              currentPrayer: state.currentOrNextPrayer,
              use24HourFormat: state.settings.use24HourFormat,
            ),

            // Fasting hours summary
            FastingHoursStrip(prayerTimes: state.todayPrayerTimes!),
          ],
        ),
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
