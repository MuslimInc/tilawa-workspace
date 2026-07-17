import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/prayer_times/domain/services/adhan_alarm_player_interface.dart';
import 'package:tilawa/features/prayer_times/domain/usecases/load_prayer_settings_use_case.dart';
import 'package:tilawa/features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../router/app_router_config.dart';
import '../cubit/prayer_status_cubit.dart';

class PrayerNotificationStatusScreen extends StatelessWidget {
  const PrayerNotificationStatusScreen({super.key, this.payloadJson});

  final String? payloadJson;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PrayerStatusCubit(
        getIt<IAdhanAlarmPlayer>(),
        getIt<LoadPrayerSettingsUseCase>(),
      )..init(payloadJson),
      child: Builder(
        builder: (innerContext) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _handleBack(innerContext);
          },
          child: _PrayerNotificationImmersiveScaffold(
            onBack: () => _handleBack(innerContext),
            onClose: () => _handleClose(innerContext),
          ),
        ),
      ),
    );
  }

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
        break;
    }
  }

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

class _PrayerNotificationImmersiveScaffold extends StatelessWidget {
  const _PrayerNotificationImmersiveScaffold({
    required this.onBack,
    required this.onClose,
  });

  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final heroTokens = Theme.of(context).componentTokens.homeNextPrayerHero;

    return TilawaShellChildScaffold(
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: heroTokens.backgroundGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Container(
                width: tokens.iconSizeLargePlus * 5.5,
                height: tokens.iconSizeLargePlus * 5.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: heroTokens.foregroundColor.withValues(alpha: 0.08),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ImmersiveTopBar(onClose: onBack),
                  Expanded(
                    child: _PrayerNotificationStatusView(onClose: onClose),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImmersiveTopBar extends StatelessWidget {
  const _ImmersiveTopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMedium,
        vertical: tokens.spaceSmall,
      ),
      child: Row(
        children: [
          _ImmersiveIconButton(
            icon: Icons.close_rounded,
            onTap: onClose,
            semanticLabel: context.l10n.close,
          ),
          const Spacer(),
          BlocBuilder<PrayerStatusCubit, PrayerStatusState>(
            builder: (context, state) {
              final bool isPlaying = state.maybeWhen(
                loaded: (_, _, playing, _, _, _, _) => playing,
                orElse: () => false,
              );
              if (!isPlaying) {
                return const SizedBox.shrink();
              }
              return _ImmersiveIconButton(
                icon: Icons.volume_up_rounded,
                onTap: () => context.read<PrayerStatusCubit>().stopAdhan(),
                semanticLabel: context.l10n.stopAdhan,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ImmersiveIconButton extends StatelessWidget {
  const _ImmersiveIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final heroTokens = Theme.of(context).componentTokens.homeNextPrayerHero;
    final Color foreground = heroTokens.foregroundColor;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: foreground.withValues(alpha: heroTokens.locationChipFillOpacity),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: kMeMuslimMinInteractiveDimension,
            height: kMeMuslimMinInteractiveDimension,
            child: Icon(
              icon,
              color: foreground,
              size: tokens.iconSizeMedium,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerNotificationStatusView extends StatelessWidget {
  const _PrayerNotificationStatusView({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final heroTokens = Theme.of(context).componentTokens.homeNextPrayerHero;

    return BlocBuilder<PrayerStatusCubit, PrayerStatusState>(
      builder: (context, state) {
        return state.when(
          initial: () => Center(
            child: TilawaLoadingIndicator(color: heroTokens.foregroundColor),
          ),
          loading: () => Center(
            child: TilawaLoadingIndicator(color: heroTokens.foregroundColor),
          ),
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
    final heroTokens = Theme.of(context).componentTokens.homeNextPrayerHero;
    final Color onHero = heroTokens.foregroundColor;
    final localizedPrayerName = _localizePrayerName(context, prayerName);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
      child: Column(
        children: [
          SizedBox(height: tokens.spaceLarge),
          _PulsingBellIcon(isPlaying: isAdhanPlaying),
          SizedBox(height: tokens.spaceMedium),
          Text(
            localizedPrayerName,
            style: context.textTheme.titleLarge?.copyWith(
              color: onHero.withValues(
                alpha: heroTokens.mutedForegroundOpacity,
              ),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spaceSmall),
          _HeroTimeDisplay(time: scheduledTime),
          if (locationName != null) ...[
            SizedBox(height: tokens.spaceMedium),
            _LocationBadge(locationName: locationName!),
          ],
          SizedBox(height: tokens.spaceExtraLarge),
          _ImmersiveStatusPanel(
            isAdhanPlaying: isAdhanPlaying,
            adhanEnabled: adhanEnabled,
            soundName: soundName,
          ),
          SizedBox(height: tokens.spaceLarge),
          if (isAdhanPlaying) ...[
            _ImmersiveGradientButton(
              label: l10n.stopAdhan,
              icon: Icons.stop_rounded,
              onPressed: () => context.read<PrayerStatusCubit>().stopAdhan(),
            ),
            SizedBox(height: tokens.spaceSmall),
          ],
          _ImmersiveGlassButton(
            label: l10n.viewAllPrayerTimes,
            icon: Icons.calendar_today_outlined,
            onPressed: () => const PrayerTimesRoute().go(context),
          ),
          SizedBox(height: tokens.spaceSmall),
          Row(
            spacing: tokens.spaceSmall,
            children: [
              Expanded(
                child: _ImmersiveGlassButton(
                  label: l10n.homeQuickQuran,
                  icon: Icons.menu_book_rounded,
                  onPressed: () => const QuranLastReadRoute().go(context),
                ),
              ),
              Expanded(
                child: _ImmersiveGlassButton(
                  label: l10n.homeQuickQibla,
                  icon: Icons.explore_outlined,
                  onPressed: () => const QiblaRoute().go(context),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceSmall),
          Center(
            child: TilawaButton(
              text: l10n.close,
              variant: TilawaButtonVariant.ghost,
              shrinkWrapTapTarget: true,
              foregroundColor: onHero.withValues(
                alpha: heroTokens.footerForegroundOpacity,
              ),
              textStyle: context.textTheme.labelLarge?.copyWith(
                color: onHero.withValues(
                  alpha: heroTokens.footerForegroundOpacity,
                ),
                fontWeight: FontWeight.w700,
              ),
              onPressed: onClose,
            ),
          ),
          SizedBox(height: tokens.spaceMedium),
        ],
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

class _HeroTimeDisplay extends StatelessWidget {
  const _HeroTimeDisplay({required this.time});

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final heroTokens = Theme.of(context).componentTokens.homeNextPrayerHero;
    final Color onHero = heroTokens.foregroundColor;
    final TimeOfDay timeOfDay = TimeOfDay.fromDateTime(time);
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    final String timeText = localizations.formatTimeOfDay(
      timeOfDay,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

    return Text(
      timeText,
      style: context.textTheme.displayLarge?.copyWith(
        color: onHero,
        fontWeight: FontWeight.w800,
        height: 1.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _ImmersiveStatusPanel extends StatelessWidget {
  const _ImmersiveStatusPanel({
    required this.isAdhanPlaying,
    required this.adhanEnabled,
    this.soundName,
  });

  final bool isAdhanPlaying;
  final bool adhanEnabled;
  final String? soundName;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    final heroTokens = Theme.of(context).componentTokens.homeNextPrayerHero;
    final Color onHero = heroTokens.foregroundColor;
    final BorderRadius radius = BorderRadius.circular(tokens.radiusExtraLarge);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: tokens.blurGlass,
          sigmaY: tokens.blurGlass,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: onHero.withValues(alpha: heroTokens.locationChipFillOpacity),
            borderRadius: radius,
            border: Border.all(
              color: onHero.withValues(
                alpha: heroTokens.locationChipBorderOpacity,
              ),
              width: tokens.borderWidthThin,
            ),
          ),
          child: Column(
            children: [
              _StatusRow(
                icon: Icons.check_circle_outline_rounded,
                label: l10n.notificationStatus,
                value: TilawaStatusChip(
                  label: l10n.received,
                  backgroundColor: onHero.withValues(alpha: 0.18),
                  foregroundColor: onHero,
                ),
              ),
              _ImmersiveDivider(),
              _StatusRow(
                icon: isAdhanPlaying
                    ? Icons.music_note_rounded
                    : Icons.music_note_outlined,
                label: l10n.adhanStatus,
                value: TilawaStatusChip(
                  label: isAdhanPlaying
                      ? l10n.playing
                      : (adhanEnabled ? l10n.enabled : l10n.disabled),
                  backgroundColor: onHero.withValues(
                    alpha: isAdhanPlaying ? 0.22 : 0.12,
                  ),
                  foregroundColor: onHero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImmersiveDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final heroTokens = Theme.of(context).componentTokens.homeNextPrayerHero;

    return Divider(
      height: 1,
      thickness: context.tokens.borderWidthThin,
      color: heroTokens.foregroundColor.withValues(
        alpha: heroTokens.locationChipBorderOpacity * 0.6,
      ),
    );
  }
}

class _ImmersiveGradientButton extends StatelessWidget {
  const _ImmersiveGradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final heroTokens = Theme.of(context).componentTokens.homeNextPrayerHero;
    final BorderRadius radius = BorderRadius.circular(
      tokens.resolveRadius(family: TilawaRadiusFamily.card),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: heroTokens.backgroundGradient,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: heroTokens.gradientBottomEnd.withValues(
                  alpha: tokens.opacityShadowStrong,
                ),
                blurRadius: tokens.blurShadow,
                offset: tokens.shadowOffsetMedium,
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kMeMuslimMinInteractiveDimension,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: tokens.spaceSmall,
                children: [
                  Icon(
                    icon,
                    color: heroTokens.foregroundColor,
                    size: tokens.iconSizeMedium,
                  ),
                  Text(
                    label,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: heroTokens.foregroundColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImmersiveGlassButton extends StatelessWidget {
  const _ImmersiveGlassButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final heroTokens = Theme.of(context).componentTokens.homeNextPrayerHero;
    final Color onHero = heroTokens.foregroundColor;
    final BorderRadius radius = BorderRadius.circular(
      tokens.resolveRadius(family: TilawaRadiusFamily.card),
    );

    return Material(
      color: onHero.withValues(alpha: heroTokens.locationChipFillOpacity),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: onHero.withValues(alpha: heroTokens.locationChipBorderOpacity),
          width: tokens.borderWidthThin,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMeMuslimMinInteractiveDimension,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceMedium,
              vertical: tokens.spaceSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: tokens.spaceExtraSmall,
              children: [
                Icon(icon, color: onHero, size: tokens.iconSizeSmall),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: onHero,
                      fontWeight: FontWeight.w700,
                    ),
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
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
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
    final tokens = context.tokens;
    final heroTokens = Theme.of(context).componentTokens.homeNextPrayerHero;
    final Color onHero = heroTokens.foregroundColor;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Transform.scale(
          scale: widget.isPlaying ? _scale.value : 1.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isPlaying)
                Container(
                  width: tokens.iconSizeLargePlus * 2.4,
                  height: tokens.iconSizeLargePlus * 2.4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: onHero.withValues(alpha: 0.14),
                  ),
                ),
              Container(
                width: tokens.iconSizeLargePlus * 1.6,
                height: tokens.iconSizeLargePlus * 1.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: onHero.withValues(
                    alpha: heroTokens.locationChipFillOpacity,
                  ),
                  border: Border.all(
                    color: onHero.withValues(
                      alpha: heroTokens.locationChipBorderOpacity,
                    ),
                    width: tokens.borderWidthThin,
                  ),
                ),
                child: Icon(
                  widget.isPlaying
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_rounded,
                  size: tokens.iconSizeLarge,
                  color: onHero,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationBadge extends StatelessWidget {
  const _LocationBadge({required this.locationName});

  final String locationName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final heroTokens = theme.componentTokens.homeNextPrayerHero;
    final Color onHero = heroTokens.foregroundColor;

    final label = PrayerLocationLabelFormatter.abbreviatedLocationLabel(
      locationName: locationName,
      l10n: context.l10n,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: onHero.withValues(alpha: heroTokens.locationChipFillOpacity),
        borderRadius: BorderRadius.circular(
          tokens.resolveRadius(
            family: TilawaRadiusFamily.pill,
            height: kMeMuslimMinInteractiveDimension,
          ),
        ),
        border: Border.all(
          color: onHero.withValues(alpha: heroTokens.locationChipBorderOpacity),
          width: tokens.borderWidthThin,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceSmall,
          vertical: tokens.spaceExtraSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: tokens.iconSizeSmall,
              color: onHero,
            ),
            SizedBox(width: tokens.spaceExtraSmall),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: onHero,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final heroTokens = Theme.of(context).componentTokens.homeNextPrayerHero;
    final Color onHero = heroTokens.foregroundColor;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLarge,
        vertical: tokens.spaceMedium,
      ),
      child: Row(
        children: [
          Container(
            width: tokens.iconSizeExtraLarge,
            height: tokens.iconSizeExtraLarge,
            decoration: BoxDecoration(
              color: onHero.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(tokens.radiusMedium),
            ),
            child: Icon(
              icon,
              size: tokens.iconSizeMedium,
              color: onHero,
            ),
          ),
          SizedBox(width: tokens.spaceMedium),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyLarge?.copyWith(
                color: onHero,
                fontWeight: FontWeight.w600,
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
        TilawaButton(
          text: l10n.continueListening,
          variant: TilawaButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(null),
        ),
        TilawaButton(
          text: l10n.stopAdhan,
          variant: TilawaButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(_ExitChoice.stop),
        ),
      ],
    );
  }
}
