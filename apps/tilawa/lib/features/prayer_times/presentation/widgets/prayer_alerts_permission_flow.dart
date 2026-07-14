import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_permissions_cubit.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Steps shown in [PrayerAlertsPermissionFlow] when capability checks fail.
enum PrayerAlertsPermissionStep {
  location,
  notifications,
  exactAlarm,
  batteryOptimization,
  oemAutostart,
}

/// Full-screen permission setup (Sadiq-style) before prayer alert settings.
class PrayerAlertsPermissionFlow extends StatefulWidget {
  const PrayerAlertsPermissionFlow({
    super.key,
    required this.steps,
    required this.onFinished,
    this.prayerTimesBloc,
  });

  final List<PrayerAlertsPermissionStep> steps;
  final VoidCallback onFinished;
  final PrayerTimesBloc? prayerTimesBloc;

  @override
  State<PrayerAlertsPermissionFlow> createState() =>
      _PrayerAlertsPermissionFlowState();
}

class _PrayerAlertsPermissionFlowState
    extends State<PrayerAlertsPermissionFlow> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage >= widget.steps.length - 1;

  Future<void> _onAllow(PrayerAlertsPermissionStep step) async {
    if (_isRequesting) {
      return;
    }
    setState(() => _isRequesting = true);
    try {
      final PrayerPermissionsCubit cubit = context
          .read<PrayerPermissionsCubit>();
      switch (step) {
        case PrayerAlertsPermissionStep.location:
          await cubit.requestLocationPermission();
        case PrayerAlertsPermissionStep.notifications:
          await cubit.requestNotificationPermission();
        case PrayerAlertsPermissionStep.exactAlarm:
          await cubit.requestExactAlarmPermission();
        case PrayerAlertsPermissionStep.batteryOptimization:
          // Battery whitelist dialog disabled; step omitted from pending list.
          // await cubit.requestIgnoreBatteryOptimizations();
          break;
        case PrayerAlertsPermissionStep.oemAutostart:
          await cubit.checkCapability();
      }
      _reschedulePrayerNotifications();
      _advance();
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  void _reschedulePrayerNotifications() {
    // Nullable read: no PrayerTimesBloc is provided outside the
    // prayer-times scope (e.g. onboarding).
    final PrayerTimesBloc? bloc =
        widget.prayerTimesBloc ?? context.read<PrayerTimesBloc?>();
    bloc?.add(const PrayerTimesEvent.loadPrayerTimes(forceReschedule: true));
  }

  void _advance() {
    if (_isLastPage) {
      widget.onFinished();
      return;
    }
    final int next = _currentPage + 1;
    setState(() => _currentPage = next);
    unawaited(
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _onSkip() {
    _advance();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;

    return Scaffold(
      body: TilawaThumbReachLayout(
        useSafeArea: true,
        content: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.steps.length,
          itemBuilder: (BuildContext context, int index) {
            return _PermissionStepPage(
              step: widget.steps[index],
              tokens: tokens,
              theme: theme,
            );
          },
        ),
        actions: _PermissionStepFooter(
          step: widget.steps[_currentPage],
          isLoading: _isRequesting,
          onAllow: () => _onAllow(widget.steps[_currentPage]),
          onSkip: _onSkip,
          theme: theme,
        ),
      ),
    );
  }
}

class _PermissionStepPage extends StatelessWidget {
  const _PermissionStepPage({
    required this.step,
    required this.tokens,
    required this.theme,
  });

  final PrayerAlertsPermissionStep step;
  final MeMuslimDesignTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final _StepCopy copy = _stepCopy(context, step);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextStyle titleStyle =
        theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.25,
        ) ??
        const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 24,
          height: 1.25,
        );
    final TextStyle bodyStyle =
        theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.4,
        ) ??
        TextStyle(
          color: colorScheme.onSurfaceVariant,
          height: 1.4,
          fontSize: 16,
        );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
      child: TilawaContentBounds(
        kind: TilawaContentKind.form,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(
              copy.icon,
              size: tokens.iconSizeExtraLarge,
              color: colorScheme.primary,
            ),
            SizedBox(height: tokens.spaceLarge),
            TilawaReservedTextLines(
              text: copy.title,
              style: titleStyle,
              maxLines: 2,
              alignment: Alignment.bottomCenter,
            ),
            SizedBox(height: tokens.spaceMedium),
            TilawaReservedTextLines(
              text: copy.body,
              style: bodyStyle,
              maxLines: 5,
              alignment: Alignment.topCenter,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionStepFooter extends StatelessWidget {
  const _PermissionStepFooter({
    required this.step,
    required this.isLoading,
    required this.onAllow,
    required this.onSkip,
    required this.theme,
  });

  final PrayerAlertsPermissionStep step;
  final bool isLoading;
  final VoidCallback onAllow;
  final VoidCallback onSkip;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isInfoOnly = step == PrayerAlertsPermissionStep.oemAutostart;
    final String primaryLabel = isInfoOnly
        ? context.l10n.prayerAlertsPermissionContinue
        : context.l10n.prayerAlertsPermissionAllow;

    return TilawaThumbReachActions(
      primary: TilawaButton(
        text: primaryLabel,
        variant: TilawaButtonVariant.primary,
        foregroundColor: colorScheme.onPrimary,
        isLoading: isLoading,
        onPressed: isLoading ? null : onAllow,
        isFullWidth: true,
      ),
      secondary: TilawaButton(
        text: context.l10n.prayerAlertsPermissionSkip,
        variant: TilawaButtonVariant.ghost,
        onPressed: isLoading ? null : onSkip,
        isFullWidth: true,
      ),
    );
  }
}

class _StepCopy {
  const _StepCopy({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

_StepCopy _stepCopy(BuildContext context, PrayerAlertsPermissionStep step) {
  final l10n = context.l10n;
  return switch (step) {
    PrayerAlertsPermissionStep.location => _StepCopy(
      title: l10n.prayerAlertsPermissionLocationTitle,
      body: l10n.prayerAlertsPermissionLocationBody,
      icon: Icons.my_location_rounded,
    ),
    PrayerAlertsPermissionStep.notifications => _StepCopy(
      title: l10n.prayerAlertsPermissionNotificationsTitle,
      body: l10n.prayerAlertsPermissionNotificationsBody,
      icon: Icons.notifications_active_outlined,
    ),
    PrayerAlertsPermissionStep.exactAlarm => _StepCopy(
      title: l10n.prayerAlertsPermissionExactAlarmTitle,
      body: l10n.prayerAlertsPermissionExactAlarmBody,
      icon: Icons.alarm_rounded,
    ),
    // Battery optimization step disabled in [prayerAlertsSetupPendingSteps].
    PrayerAlertsPermissionStep.batteryOptimization => _StepCopy(
      title: l10n.prayerAlertsPermissionBatteryTitle,
      body: l10n.prayerAlertsPermissionBatteryBody,
      icon: Icons.battery_charging_full_rounded,
    ),
    PrayerAlertsPermissionStep.oemAutostart => _StepCopy(
      title: l10n.prayerAlertsPermissionOemAutostartTitle,
      body: l10n.prayerAlertsPermissionOemAutostartBody,
      icon: Icons.phonelink_setup_rounded,
    ),
  };
}
