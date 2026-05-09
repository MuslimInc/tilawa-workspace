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
import '../formatters/prayer_location_label_formatter.dart';
import '../mappers/prayer_row_view_data_mapper.dart';
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
              selectedColor: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.92,
              ),
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
              previous.settings != current.settings ||
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
              return const PrayerTimesScreenSkeleton();

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
      return const PrayerTimesScreenSkeleton();
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
            onOpenQibla: () => context.push('/qibla'),
            onManageAlertsTap: () => _showNotificationDialog(context),
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
  const _CountdownCardSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
      buildWhen: (previous, current) =>
          previous.todayPrayerTimes != current.todayPrayerTimes ||
          previous.settings.use24HourFormat != current.settings.use24HourFormat,
      builder: (context, state) {
        final todayTimes = state.todayPrayerTimes;
        if (todayTimes == null) return const SizedBox.shrink();

        return _CountdownTicker(
          prayerTimes: todayTimes,
          use24HourFormat: state.settings.use24HourFormat,
          dateMetaLabel: _buildDateMetaLabel(context),
        );
      },
    );
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
  });

  final PrayerTimeEntity prayerTimes;
  final bool use24HourFormat;
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

    return NextPrayerCountdownCard(
      nextPrayer: nextPrayer,
      timeUntil: timeUntil,
      use24HourFormat: widget.use24HourFormat,
      dateMetaLabel: widget.dateMetaLabel,
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
        tokens.spaceSmall,
        tokens.spaceLarge,
        0,
      ),
      child: TilawaCard(
        flat: true,
        borderRadius: tokens.radiusLarge,
        backgroundColor: colorScheme.surfaceContainerLowest,
        borderColor: colorScheme.outlineVariant.withValues(
          alpha: tokens.opacityMedium,
        ),
        onTap: isLoading ? null : onUpdateLocation,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceSmall,
          vertical: tokens.spaceSmall,
        ),
        child: _UtilityActionRow(
          icon: Icons.location_on_outlined,
          label: PrayerLocationLabelFormatter.compactLabel(
            locationName: locationName,
            l10n: context.l10n,
          ),
          trailing: isLoading
              ? SizedBox(
                  width: tokens.iconSizeSmall,
                  height: tokens.iconSizeSmall,
                  child: CircularProgressIndicator(
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

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        0,
      ),
      child: Column(
        children: [
          _UtilityActionCard(
            icon: Icons.explore_outlined,
            label: context.l10n.qiblaDirection,
            onTap: onOpenQibla,
          ),
          SizedBox(height: tokens.spaceSmall),
          _UtilityActionCard(
            semanticsId:
                PrayerNotificationSemanticsIds.prayerNotificationsEntryPoint,
            icon: Icons.tune_rounded,
            label: context.l10n.manageAlerts,
            onTap: onManageAlertsTap,
          ),
        ],
      ),
    );
  }
}

class _UtilityActionCard extends StatelessWidget {
  const _UtilityActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.semanticsId,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return TilawaCard(
      flat: true,
      borderRadius: tokens.radiusLarge,
      backgroundColor: colorScheme.surfaceContainerLowest,
      borderColor: colorScheme.outlineVariant.withValues(
        alpha: tokens.opacityMedium,
      ),
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: tokens.spaceSmall,
      ),
      child: _UtilityActionRow(
        semanticsId: semanticsId,
        icon: icon,
        label: label,
        trailing: Icon(
          Icons.chevron_right,
          size: tokens.iconSizeMedium,
          color: colorScheme.onSurfaceVariant,
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
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final String? semanticsId;

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
        children: [
          Icon(
            icon,
            size: tokens.iconSizeSmall,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: tokens.spaceSmall),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: tokens.spaceSmall),
          trailing,
        ],
      ),
    );

    return Semantics(identifier: semanticsId, child: rowContent);
  }
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

    final rows = PrayerRowViewDataMapper.map(
      prayerTimes: prayerTimes,
      settings: settings,
      currentPrayer: currentPrayer,
      l10n: context.l10n,
      isArabic: isArabic,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLarge,
        tokens.spaceSmall,
        tokens.spaceLarge,
        0,
      ),
      child: TilawaCard(
        flat: true,
        borderRadius: tokens.radiusLarge,
        backgroundColor: colorScheme.surface,
        borderColor: colorScheme.outlineVariant.withValues(
          alpha: tokens.opacityMedium,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: tokens.spaceSmall,
        ),
        child: Column(
          children: rows.map((row) {
            return _TodayPrayerListRow(
              prayerName: row.prayerName,
              prayerTime: row.prayerTime,
              statusText: row.statusText,
              isCurrent: row.isCurrent,
              hasPassed: row.hasPassed,
              isSecondary: row.isSecondary,
              showAlertIndicators: row.showAlertIndicators,
              notificationEnabled: row.notificationEnabled,
              adhanEnabled: row.adhanEnabled,
              onTap: null,
              onNotificationToggle: row.showAlertIndicators
                  ? () => _onNotificationToggle(context, row.type)
                  : null,
              onAdhanToggle: row.showAlertIndicators && row.notificationEnabled
                  ? () => _onAdhanToggle(context, row.type)
                  : null,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _onNotificationToggle(BuildContext context, PrayerType type) {
    final updated = PrayerRowViewDataMapper.toggledNotificationSettings(
      settings,
      type,
    );
    if (updated == null) return;
    context.read<PrayerTimesBloc>().add(
      PrayerTimesEvent.updateSettings(updated),
    );
  }

  void _onAdhanToggle(BuildContext context, PrayerType type) {
    final updated = PrayerRowViewDataMapper.toggledAdhanSettings(
      settings,
      type,
    );
    if (updated == null) return;
    context.read<PrayerTimesBloc>().add(
      PrayerTimesEvent.updateSettings(updated),
    );
  }
}

class _TodayPrayerListRow extends StatelessWidget {
  const _TodayPrayerListRow({
    required this.prayerName,
    required this.prayerTime,
    required this.statusText,
    required this.isCurrent,
    required this.hasPassed,
    required this.isSecondary,
    required this.showAlertIndicators,
    required this.notificationEnabled,
    required this.adhanEnabled,
    required this.onTap,
    required this.onNotificationToggle,
    required this.onAdhanToggle,
  });

  final String prayerName;
  final String prayerTime;
  final String statusText;
  final bool isCurrent;
  final bool hasPassed;
  final bool isSecondary;
  final bool showAlertIndicators;
  final bool notificationEnabled;
  final bool adhanEnabled;
  final VoidCallback? onTap;
  final VoidCallback? onNotificationToggle;
  final VoidCallback? onAdhanToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final Color rowColor = isCurrent
        ? colorScheme.primary
        : colorScheme.onSurface;
    final double rowAlpha = isSecondary
        ? tokens.opacityEmphasis
        : (hasPassed ? tokens.opacityEmphasis : 1);

    return Material(
      color: isCurrent
          ? colorScheme.primaryContainer.withValues(alpha: 0.18)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(tokens.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: tokens.spaceExtraSmall,
            horizontal: tokens.spaceSmall,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prayerName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: isCurrent
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: rowColor.withValues(alpha: rowAlpha),
                      ),
                    ),
                    SizedBox(height: tokens.spaceExtraSmall / 2),
                    Text(
                      statusText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: rowColor.withValues(alpha: rowAlpha),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: tokens.spaceSmall),
              Text(
                prayerTime,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: rowColor.withValues(alpha: rowAlpha),
                ),
              ),
              if (showAlertIndicators) ...[
                SizedBox(width: tokens.spaceMedium),
                _PrayerAlertIndicators(
                  notificationEnabled: notificationEnabled,
                  adhanEnabled: adhanEnabled,
                  isSecondary: isSecondary,
                  onNotificationTap: onNotificationToggle,
                  onAdhanTap: onAdhanToggle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerAlertIndicators extends StatelessWidget {
  const _PrayerAlertIndicators({
    required this.notificationEnabled,
    required this.adhanEnabled,
    required this.isSecondary,
    required this.onNotificationTap,
    required this.onAdhanTap,
  });

  final bool notificationEnabled;
  final bool adhanEnabled;
  final bool isSecondary;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAdhanTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final iconAlpha = isSecondary ? tokens.opacityEmphasis : 1.0;
    final notificationColor =
        (notificationEnabled
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant)
            .withValues(alpha: iconAlpha);
    final adhanColor =
        (!notificationEnabled
                ? colorScheme.onSurfaceVariant
                : adhanEnabled
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant)
            .withValues(
              alpha: !notificationEnabled ? tokens.opacityEmphasis : iconAlpha,
            );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InlineAlertIcon(
          icon: notificationEnabled
              ? Icons.notifications_active_outlined
              : Icons.notifications_off_outlined,
          color: notificationColor,
          emphasisColor: colorScheme.primaryContainer,
          active: notificationEnabled,
          onTap: onNotificationTap,
          semanticLabel: context.l10n.prayerNotifications,
        ),
        SizedBox(width: tokens.spaceExtraSmall),
        _InlineAlertIcon(
          icon: !notificationEnabled
              ? Icons.volume_off_outlined
              : adhanEnabled
              ? Icons.volume_up_outlined
              : Icons.volume_mute_outlined,
          color: adhanColor,
          emphasisColor: colorScheme.primaryContainer,
          active: notificationEnabled && adhanEnabled,
          onTap: onAdhanTap,
          semanticLabel: context.l10n.playAdhan,
        ),
      ],
    );
  }
}

class _InlineAlertIcon extends StatelessWidget {
  const _InlineAlertIcon({
    required this.icon,
    required this.color,
    required this.emphasisColor,
    required this.active,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final Color color;
  final Color emphasisColor;
  final bool active;
  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final isEnabled = onTap != null;
    final backgroundColor = !isEnabled
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.16)
        : (active ? emphasisColor : colorScheme.surfaceContainerHighest)
              .withValues(alpha: active ? 0.35 : 0.28);

    return Semantics(
      button: isEnabled,
      enabled: isEnabled,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.radiusSmall),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: kMinInteractiveDimension,
              minHeight: kMinInteractiveDimension,
            ),
            child: Center(
              child: Container(
                width: tokens.iconSizeLarge,
                height: tokens.iconSizeLarge,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Tooltip(
                  message: semanticLabel,
                  child: Center(
                    child: Icon(icon, size: tokens.iconSizeSmall, color: color),
                  ),
                ),
              ),
            ),
          ),
        ),
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
