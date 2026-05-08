import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_core/di/injection.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../shared/widgets/tilawa_back_button.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/prayer_adhan_notification_service_interface.dart';
import '../bloc/prayer_permissions_cubit.dart';
import '../bloc/prayer_times_bloc.dart';
import '../prayer_notification_semantics_ids.dart';
import '../widgets/prayer_notification_settings_sheet.dart';
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

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  int _selectedIndex = 0;

  void _onSegmentChanged(String value) {
    setState(() {
      _selectedIndex = value == 'today' ? 0 : 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop() ? const TilawaBackButton() : null,
        title: Text(context.l10n.prayerTimes),
        actionsPadding: EdgeInsetsDirectional.only(end: tokens.spaceMedium),
        actions: [
          Semantics(
            identifier: PrayerNotificationSemanticsIds.prayerSettingsButton,
            child: TilawaIconActionButton(
              icon: Icons.settings,
              onTap: () => _showSettingsDialog(context),
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
            child: TilawaSegmentedControl<String>(
              segments: [
                TilawaSegment(value: 'today', label: context.l10n.today),
                TilawaSegment(value: 'monthly', label: context.l10n.monthly),
              ],
              selectedValue: _selectedIndex == 0 ? 'today' : 'monthly',
              onValueChanged: _onSegmentChanged,
            ),
          ),
        ),
      ),
      // floatingActionButton: kDebugMode ? const _DebugNotificationFab() : null,
      body: BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
        buildWhen: (previous, current) {
          return previous.status != current.status ||
              previous.todayPrayerTimes != current.todayPrayerTimes ||
              previous.monthlyPrayerTimes != current.monthlyPrayerTimes ||
              previous.settings.use24HourFormat !=
                  current.settings.use24HourFormat ||
              previous.settings.showSunrise != current.settings.showSunrise ||
              previous.latitude != current.latitude ||
              previous.longitude != current.longitude ||
              previous.locationName != current.locationName ||
              previous.errorMessage != current.errorMessage ||
              previous.isLoadingLocation != current.isLoadingLocation;
        },
        builder: (context, state) {
          switch (state.status) {
            case PrayerTimesStatus.initial:
            case PrayerTimesStatus.loading:
              return const TilawaLoadingIndicator();

            case PrayerTimesStatus.error:
              return TilawaErrorState(
                icon: Icons.error_outline_rounded,
                title: state.errorMessage,
                retryLabel: context.l10n.retry,
                onRetry: () {
                  context.read<PrayerTimesBloc>().add(
                    const PrayerTimesEvent.loadPrayerTimes(),
                  );
                },
              );

            case PrayerTimesStatus.locationRequired:
              return _buildLocationRequiredView(context, state);

            case PrayerTimesStatus.loaded:
              return IndexedStack(
                index: _selectedIndex,
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
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return TilawaEmptyState(
      icon: Icons.location_off_rounded,
      iconColor: theme.colorScheme.outline,
      title: context.l10n.locationRequired,
      subtitle: context.l10n.locationRequiredDescription,
      action: Column(
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
          FilledButton.icon(
            onPressed: state.isLoadingLocation
                ? null
                : () {
                    context.read<PrayerTimesBloc>().add(
                      const PrayerTimesEvent.updateLocation(),
                    );
                  },
            icon: state.isLoadingLocation
                ? SizedBox.square(
                    dimension: tokens.iconSizeSmall,
                    child: TilawaLoadingIndicator(
                      centered: false,
                      strokeWidth: tokens.borderWidthThin * 4,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(context.l10n.enableLocation),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayView(BuildContext context, PrayerTimesState state) {
    if (state.todayPrayerTimes == null) {
      return const TilawaLoadingIndicator();
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
            onOpenQibla: () => context.push('/qibla'),
          ),
          _CountdownCardSection(
            onPrayerNotificationsTap: () => _showNotificationDialog(context),
          ),
          _TodayPrayerGrid(
            prayerTimes: state.todayPrayerTimes!,
            use24HourFormat: state.settings.use24HourFormat,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyView(BuildContext context, PrayerTimesState state) {
    if (state.latitude == null || state.longitude == null) {
      return TilawaEmptyState(
        icon: Icons.location_off_rounded,
        title: context.l10n.locationRequired,
        subtitle: context.l10n.locationRequiredDescription,
      );
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
    final PrayerPermissionsCubit permissionsCubit = context
        .read<PrayerPermissionsCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
  const _CountdownCardSection({required this.onPrayerNotificationsTap});

  final VoidCallback onPrayerNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
      buildWhen: (previous, current) =>
          previous.todayPrayerTimes != current.todayPrayerTimes ||
          previous.settings.use24HourFormat !=
              current.settings.use24HourFormat ||
          _hasEnabledPrayerNotifications(previous.settings) !=
              _hasEnabledPrayerNotifications(current.settings),
      builder: (context, state) {
        final todayTimes = state.todayPrayerTimes;
        if (todayTimes == null) return const SizedBox.shrink();

        return _CountdownTicker(
          prayerTimes: todayTimes,
          use24HourFormat: state.settings.use24HourFormat,
          dateMetaLabel: _buildDateMetaLabel(context),
          prayerNotificationsEnabled: _hasEnabledPrayerNotifications(
            state.settings,
          ),
          onPrayerNotificationsTap: onPrayerNotificationsTap,
        );
      },
    );
  }

  static bool _hasEnabledPrayerNotifications(PrayerSettingsEntity settings) {
    return settings.fajrNotification.enabled ||
        settings.dhuhrNotification.enabled ||
        settings.asrNotification.enabled ||
        settings.maghribNotification.enabled ||
        settings.ishaNotification.enabled;
  }

  static String _buildDateMetaLabel(BuildContext context) {
    final isArabic = context.isArabic;
    final locale = isArabic ? 'ar' : 'en';
    final now = DateTime.now();
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

/// Rebuilds itself every second using a single owned [Timer.periodic].
///
/// Replaces an earlier `StreamBuilder` + inline `Stream.periodic` that crashed
/// with "Stream has already been listened to" on rebuilds, since
/// `Stream.periodic` is single-subscription and was being recreated each build.
class _CountdownTicker extends StatefulWidget {
  const _CountdownTicker({
    required this.prayerTimes,
    required this.use24HourFormat,
    required this.dateMetaLabel,
    required this.prayerNotificationsEnabled,
    required this.onPrayerNotificationsTap,
  });

  final PrayerTimeEntity prayerTimes;
  final bool use24HourFormat;
  final String dateMetaLabel;
  final bool prayerNotificationsEnabled;
  final VoidCallback onPrayerNotificationsTap;

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

    return NextPrayerCountdownCard(
      nextPrayer: nextPrayer,
      timeUntil: timeUntil,
      use24HourFormat: widget.use24HourFormat,
      dateMetaLabel: widget.dateMetaLabel,
      prayerNotificationsEnabled: widget.prayerNotificationsEnabled,
      onPrayerNotificationsTap: widget.onPrayerNotificationsTap,
    );
  }
}

/// Wraps [PrayerTimesGrid] with a low-frequency timer that only rebuilds when
/// the "current prayer" changes (checked once per minute — current prayer can
/// only change a handful of times a day, so a 1s tick was wasteful).
class _TodayPrayerGrid extends StatefulWidget {
  const _TodayPrayerGrid({
    required this.prayerTimes,
    required this.use24HourFormat,
  });

  final PrayerTimeEntity prayerTimes;
  final bool use24HourFormat;

  @override
  State<_TodayPrayerGrid> createState() => _TodayPrayerGridState();
}

class _TodayPrayerGridState extends State<_TodayPrayerGrid> {
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
  void didUpdateWidget(covariant _TodayPrayerGrid oldWidget) {
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
    return PrayerTimesGrid(
      prayerTimes: widget.prayerTimes,
      currentPrayer: _currentPrayer,
      use24HourFormat: widget.use24HourFormat,
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

  // ignore: unused_element
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
        // FloatingActionButton.extended(
        //   onPressed: _firing ? null : _fire,
        //   label: _firing
        //       ? const SizedBox(
        //           width: 18,
        //           height: 18,
        //           child: CircularProgressIndicator(strokeWidth: 2),
        //         )
        //       : const Text('Fire'),
        //   icon: const Icon(Icons.notifications_active_outlined),
        //   backgroundColor: theme.colorScheme.errorContainer,
        //   foregroundColor: theme.colorScheme.onErrorContainer,
        // ),
      ],
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
