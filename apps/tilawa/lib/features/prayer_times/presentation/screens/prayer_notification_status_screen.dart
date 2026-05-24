import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/core/di/injection.dart';
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
      create: (context) =>
          PrayerStatusCubit(getIt<IAdhanAlarmPlayer>())..init(payloadJson),
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: TilawaCatalogAppBar(
          preferredHeight: TilawaAppBarConfig.catalogTitleOnlyHeight(context),
          title: context.l10n.prayerNotificationReceived,
          automaticallyImplyLeading: true,
          onBackPressed: () => context.pop(),
        ),
        body: const _PrayerNotificationStatusView(),
      ),
    );
  }
}

class _PrayerNotificationStatusView extends StatelessWidget {
  const _PrayerNotificationStatusView();

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
              ) {
                return _StatusContent(
                  prayerName: prayerName,
                  scheduledTime: scheduledTime,
                  isAdhanPlaying: isAdhanPlaying,
                  adhanEnabled: adhanEnabled,
                  soundName: soundName,
                );
              },
        );
      },
    );
  }
}

class _StatusContent extends StatelessWidget {
  final String prayerName;
  final DateTime scheduledTime;
  final bool isAdhanPlaying;
  final bool adhanEnabled;
  final String? soundName;

  const _StatusContent({
    required this.prayerName,
    required this.scheduledTime,
    required this.isAdhanPlaying,
    required this.adhanEnabled,
    this.soundName,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final timeStr = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(scheduledTime));

    return TilawaContentBounds(
      kind: TilawaContentKind.form,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.spaceExtraLarge),
        child: Column(
          children: [
            SizedBox(height: tokens.spaceLarge),
            TilawaIconBox(
              icon: isAdhanPlaying
                  ? Icons.notifications_active
                  : Icons.notifications,
              size: tokens.iconSizeExtraLarge * 1.5,
              iconColor: isAdhanPlaying
                  ? context.colorScheme.primary
                  : context.colorScheme.outline,
            ),
            SizedBox(height: tokens.spaceExtraLarge),
            Text(
              _localizePrayerName(context, prayerName),
              style: context.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              l10n.prayerTimeAt(timeStr),
              style: context.textTheme.titleLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spaceExtraLarge * 2),
            TilawaGlassPanel(
              enableBackdropBlur: true,
              child: Column(
                children: [
                  _StatusRow(
                    icon: Icons.info_outline,
                    label: l10n.notificationStatus,
                    value: TilawaStatusChip(
                      label: l10n.received,
                      backgroundColor: context.colorScheme.primaryContainer,
                      foregroundColor: context.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  TilawaDivider(indent: tokens.spaceLarge),
                  _StatusRow(
                    icon: Icons.music_note_outlined,
                    label: l10n.adhanStatus,
                    value: TilawaStatusChip(
                      label: isAdhanPlaying
                          ? l10n.playing
                          : (adhanEnabled ? l10n.enabled : l10n.disabled),
                      backgroundColor: isAdhanPlaying
                          ? context.colorScheme.secondaryContainer
                          : context.colorScheme.surfaceContainerHigh,
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
            if (isAdhanPlaying)
              SizedBox(
                width: double.infinity,
                child: TilawaButton(
                  text: l10n.stopAdhan,
                  variant: TilawaButtonVariant.danger,
                  leadingIcon: const Icon(Icons.stop),
                  onPressed: () =>
                      context.read<PrayerStatusCubit>().stopAdhan(),
                  isFullWidth: true,
                ),
              ),
            SizedBox(height: tokens.spaceLarge),
            SizedBox(
              width: double.infinity,
              child: TilawaButton(
                text: l10n.viewAllPrayerTimes,
                variant: TilawaButtonVariant.outline,
                leadingIcon: const Icon(Icons.calendar_today),
                onPressed: () => const PrayerTimesRoute().go(context),
                isFullWidth: true,
              ),
            ),
            SizedBox(height: tokens.spaceLarge),
            Center(
              child: TilawaButton(
                text: l10n.close,
                variant: TilawaButtonVariant.ghost,
                onPressed: () => const HomeRoute().go(context),
              ),
            ),
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

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget value;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceMedium,
      ),
      child: Row(
        children: [
          TilawaIconBox(
            icon: icon,
            size: tokens.iconSizeMedium * 1.5,
            backgroundColor: Colors.transparent,
            iconColor: context.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: tokens.spaceMedium),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
          value,
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Failure failure;

  const _ErrorView({required this.failure});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TilawaEmptyState(
        title: context.l10n.error,
        subtitle: failure.localizedMessage(context) ??
            context.l10n.unexpectedError,
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
