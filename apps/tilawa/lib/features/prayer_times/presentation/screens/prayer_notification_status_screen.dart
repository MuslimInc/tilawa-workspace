import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/load_prayer_settings_use_case.dart';
import 'package:tilawa/features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../cubit/prayer_status_cubit.dart';

class PrayerNotificationStatusScreen extends StatelessWidget {
  final String? payloadJson;

  const PrayerNotificationStatusScreen({super.key, this.payloadJson});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PrayerStatusCubit(
        getIt<IAdhanAlarmPlayer>(),
        getIt<LoadPrayerSettingsUseCase>(),
      )..init(payloadJson),
      // Builder gives us a context that has PrayerStatusCubit for the guards.
      child: Builder(
        builder: (innerContext) => PopScope(
          // Always intercept — _handleBack decides whether to actually pop.
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _handleBack(innerContext);
          },
          child: Scaffold(
            appBar: TilawaCatalogAppBar(
              preferredHeight: TilawaAppBarConfig.catalogTitleOnlyHeight(
                innerContext,
              ),
              title: innerContext.l10n.prayerNotificationReceived,
              automaticallyImplyLeading: true,
              onBackPressed: () => _handleBack(innerContext),
            ),
            body: _PrayerNotificationStatusView(
              onClose: () => _handleClose(innerContext),
            ),
          ),
        ),
      ),
    );
  }

  /// Pops the route, but first asks the user to stop the adhan if it is
  /// still playing.
  Future<void> _handleBack(BuildContext context) async {
    final bool playing = context.read<PrayerStatusCubit>().state.maybeWhen(
      loaded: (_, _, isAdhanPlaying, _, _, _, _) => isAdhanPlaying,
      orElse: () => false,
    );

    if (!playing) {
      if (context.mounted) context.pop();
      return;
    }

    final choice = await showDialog<_ExitChoice>(
      context: context,
      builder: (_) => const _AdhanExitDialog(),
    );

    if (!context.mounted) return;
    switch (choice) {
      case _ExitChoice.stop:
        await context.read<PrayerStatusCubit>().stopAdhan();
        if (context.mounted) context.pop();
      case null:
        // Dialog dismissed — stay on screen.
        break;
    }
  }

  /// Navigates to the home screen, but first asks the user to stop the adhan
  /// if it is still playing.
  Future<void> _handleClose(BuildContext context) async {
    final bool playing = context.read<PrayerStatusCubit>().state.maybeWhen(
      loaded: (_, _, isAdhanPlaying, _, _, _, _) => isAdhanPlaying,
      orElse: () => false,
    );

    if (!playing) {
      if (context.mounted) const HomeRoute().go(context);
      return;
    }

    final choice = await showDialog<_ExitChoice>(
      context: context,
      builder: (_) => const _AdhanExitDialog(),
    );

    if (!context.mounted) return;
    switch (choice) {
      case _ExitChoice.stop:
        await context.read<PrayerStatusCubit>().stopAdhan();
        if (context.mounted) const HomeRoute().go(context);
      case null:
        break;
    }
  }
}

class _PrayerNotificationStatusView extends StatelessWidget {
  const _PrayerNotificationStatusView({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerStatusCubit, PrayerStatusState>(
      builder: (context, state) {
        return state.when(
          initial: () => const Center(child: TilawaLoadingIndicator()),
          loading: () => const Center(child: TilawaLoadingIndicator()),
          error: (failure) => _ErrorView(failure: failure),
          loaded:
              (
                prayerName,
                scheduledTime,
                isAdhanPlaying,
                adhanEnabled,
                soundName,
                notificationId,
                locationName,
              ) {
                return _StatusContent(
                  prayerName: prayerName,
                  scheduledTime: scheduledTime,
                  isAdhanPlaying: isAdhanPlaying,
                  adhanEnabled: adhanEnabled,
                  soundName: soundName,
                  locationName: locationName,
                  onClose: onClose,
                );
              },
        );
      },
    );
  }
}

// ── Main content ──────────────────────────────────────────────────────────────

class _StatusContent extends StatelessWidget {
  const _StatusContent({
    required this.prayerName,
    required this.scheduledTime,
    required this.isAdhanPlaying,
    required this.adhanEnabled,
    required this.onClose,
    this.soundName,
    this.locationName,
  });

  final String prayerName;
  final DateTime scheduledTime;
  final bool isAdhanPlaying;
  final bool adhanEnabled;
  final VoidCallback onClose;
  final String? soundName;
  final String? locationName;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;
    final timeStr = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(scheduledTime));

    return TilawaContentBounds(
      kind: TilawaContentKind.form,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceExtraLarge,
          vertical: tokens.spaceLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: tokens.spaceExtraLarge),

            // ── Animated bell icon ────────────────────────────────────────
            _PulsingBellIcon(isPlaying: isAdhanPlaying),
            SizedBox(height: tokens.spaceExtraLarge),

            // ── Prayer name ───────────────────────────────────────────────
            Text(
              _localizePrayerName(context, prayerName),
              style: context.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spaceExtraSmall),

            // ── Time ──────────────────────────────────────────────────────
            Text(
              l10n.prayerTimeAt(timeStr),
              style: context.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            // ── Location badge ────────────────────────────────────────────
            if (locationName != null) ...[
              SizedBox(height: tokens.spaceMedium),
              _LocationBadge(locationName: locationName!),
            ],

            SizedBox(height: tokens.spaceExtraLarge * 2),

            // ── Status panel ──────────────────────────────────────────────
            TilawaGlassPanel(
              enableBackdropBlur: true,
              child: Column(
                children: [
                  _StatusRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: l10n.notificationStatus,
                    iconColor: colorScheme.primary,
                    iconBackgroundColor: colorScheme.primaryContainer,
                    value: TilawaStatusChip(
                      label: l10n.received,
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  TilawaDivider(indent: tokens.spaceLarge),
                  _StatusRow(
                    icon: isAdhanPlaying
                        ? Icons.music_note_rounded
                        : Icons.music_note_outlined,
                    label: l10n.adhanStatus,
                    iconColor: isAdhanPlaying
                        ? colorScheme.secondary
                        : colorScheme.onSurfaceVariant,
                    iconBackgroundColor: isAdhanPlaying
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerHigh,
                    value: TilawaStatusChip(
                      label: isAdhanPlaying
                          ? l10n.playing
                          : (adhanEnabled ? l10n.enabled : l10n.disabled),
                      backgroundColor: isAdhanPlaying
                          ? colorScheme.secondaryContainer
                          : colorScheme.surfaceContainerHigh,
                      foregroundColor: isAdhanPlaying
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (soundName != null) ...[
                    TilawaDivider(indent: tokens.spaceLarge),
                    _StatusRow(
                      icon: Icons.volume_up_outlined,
                      label: l10n.sound,
                      value: TilawaStatusChip(label: soundName!),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: tokens.spaceExtraLarge * 2),

            // ── Actions ───────────────────────────────────────────────────
            if (isAdhanPlaying) ...[
              SizedBox(
                width: double.infinity,
                child: TilawaButton(
                  text: l10n.stopAdhan,
                  variant: TilawaButtonVariant.danger,
                  leadingIcon: const Icon(Icons.stop_rounded),
                  onPressed: () =>
                      context.read<PrayerStatusCubit>().stopAdhan(),
                  isFullWidth: true,
                ),
              ),
              SizedBox(height: tokens.spaceMedium),
            ],
            SizedBox(
              width: double.infinity,
              child: TilawaButton(
                text: l10n.viewAllPrayerTimes,
                variant: TilawaButtonVariant.outline,
                leadingIcon: const Icon(Icons.calendar_today_outlined),
                onPressed: () => const PrayerTimesRoute().go(context),
                isFullWidth: true,
              ),
            ),
            SizedBox(height: tokens.spaceMedium),
            Center(
              child: TilawaButton(
                text: l10n.close,
                variant: TilawaButtonVariant.ghost,
                onPressed: onClose,
              ),
            ),
            SizedBox(height: tokens.spaceLarge),
          ],
        ),
      ),
    );
  }

  String _localizePrayerName(BuildContext context, String raw) {
    final r = raw.toLowerCase();
    if (r == 'fajr') return context.l10n.fajr;
    if (r == 'dhuhr') return context.l10n.dhuhr;
    if (r == 'asr') return context.l10n.asr;
    if (r == 'maghrib') return context.l10n.maghrib;
    if (r == 'isha') return context.l10n.isha;
    if (r == 'sunrise') return context.l10n.sunrise;
    return raw;
  }
}

// ── Pulsing bell icon (animated when adhan is playing) ────────────────────────

class _PulsingBellIcon extends StatefulWidget {
  const _PulsingBellIcon({required this.isPlaying});

  final bool isPlaying;

  @override
  State<_PulsingBellIcon> createState() => _PulsingBellIconState();
}

class _PulsingBellIconState extends State<_PulsingBellIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isPlaying) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingBellIcon old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying == old.isPlaying) return;
    if (widget.isPlaying) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.animateTo(0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final tokens = context.tokens;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Transform.scale(
          scale: widget.isPlaying ? _scale.value : 1.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft glow ring shown only while playing
              if (widget.isPlaying)
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.12),
                  ),
                ),
              TilawaIconBox(
                icon: widget.isPlaying
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_rounded,
                size: tokens.iconSizeExtraLarge,
                iconColor: widget.isPlaying
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                backgroundColor: widget.isPlaying
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHigh,
                borderRadius: tokens.radiusExtraLarge,
                padding: tokens.spaceLarge,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Location badge ────────────────────────────────────────────────────────────

class _LocationBadge extends StatelessWidget {
  const _LocationBadge({required this.locationName});

  final String locationName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final label = PrayerLocationLabelFormatter.abbreviatedLocationLabel(
      locationName: locationName,
      l10n: context.l10n,
    );
    final double badgeHeight =
        tokens.spaceTiny * 2 + (theme.textTheme.labelSmall?.fontSize ?? 12);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: tokens.spaceTiny,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(
            family: TilawaRadiusFamily.pill,
            height: badgeHeight,
          ),
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: tokens.opacityMedium,
          ),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 13,
            color: colorScheme.primary,
          ),
          SizedBox(width: tokens.spaceTiny),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status row ────────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.iconBackgroundColor,
  });

  final IconData icon;
  final String label;
  final Widget value;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colorScheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceMedium,
      ),
      child: Row(
        children: [
          TilawaIconBox(
            icon: icon,
            size: tokens.iconSizeMedium,
            backgroundColor:
                iconBackgroundColor ?? colorScheme.surfaceContainerHigh,
            iconColor: iconColor ?? colorScheme.onSurfaceVariant,
            borderRadius: tokens.radiusMedium,
            padding: tokens.spaceExtraSmall,
          ),
          SizedBox(width: tokens.spaceMedium),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          value,
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TilawaEmptyState(
        title: context.l10n.error,
        subtitle:
            failure.localizedMessage(context) ?? context.l10n.unexpectedError,
        icon: Icons.error_outline,
        action: TilawaButton(
          text: context.l10n.close,
          variant: TilawaButtonVariant.outline,
          onPressed: () => const HomeRoute().go(context),
        ),
      ),
    );
  }
}

// ── Exit guard ────────────────────────────────────────────────────────────────

enum _ExitChoice { stop }

class _AdhanExitDialog extends StatelessWidget {
  const _AdhanExitDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.adhanIsPlaying),
      content: Text(l10n.adhanStillPlayingMessage),
      actions: [
        // Stay on this screen — adhan keeps playing.
        TilawaButton(
          text: l10n.continueListening,
          variant: TilawaButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(null),
        ),
        // Stop the adhan and navigate away.
        TilawaButton(
          text: l10n.stopAdhan,
          variant: TilawaButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(_ExitChoice.stop),
        ),
      ],
    );
  }
}
