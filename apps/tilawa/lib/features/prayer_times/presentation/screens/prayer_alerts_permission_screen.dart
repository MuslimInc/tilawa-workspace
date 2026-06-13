import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_alerts_permission_onboarding_repository.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/prayer_alerts_permission_nav_extra.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../bloc/prayer_permissions_cubit.dart';
import '../bloc/prayer_times_bloc.dart';
import '../prayer_alerts_setup_pending_steps.dart';
import '../widgets/prayer_alerts_permission_flow.dart';

/// GoRouter destination for the prayer-alerts permission wizard.
class PrayerAlertsPermissionScreenScope extends StatelessWidget {
  const PrayerAlertsPermissionScreenScope({
    super.key,
    this.navExtra,
  });

  final PrayerAlertsPermissionNavExtra? navExtra;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PrayerPermissionsCubit>()..checkCapability(),
      child: PrayerAlertsPermissionScreen(navExtra: navExtra),
    );
  }
}

class PrayerAlertsPermissionScreen extends StatefulWidget {
  const PrayerAlertsPermissionScreen({super.key, this.navExtra});

  final PrayerAlertsPermissionNavExtra? navExtra;

  @override
  State<PrayerAlertsPermissionScreen> createState() =>
      _PrayerAlertsPermissionScreenState();
}

class _PrayerAlertsPermissionScreenState
    extends State<PrayerAlertsPermissionScreen> {
  /// Steps passed at navigation time; kept for the whole wizard session so a
  /// later [PrayerPermissionsCubit] refresh cannot collapse the flow early.
  List<PrayerAlertsPermissionStep>? _pinnedSteps;

  @override
  void initState() {
    super.initState();
    _pinnedSteps = widget.navExtra?.steps;
  }

  @override
  void didUpdateWidget(covariant PrayerAlertsPermissionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pinnedSteps == null && widget.navExtra?.steps != null) {
      _pinnedSteps = widget.navExtra!.steps;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerPermissionsCubit, PrayerPermissionsState>(
      buildWhen: (PrayerPermissionsState prev, PrayerPermissionsState next) =>
          _pinnedSteps == null &&
          (prev.capability != next.capability ||
              prev.hasLocationPermission != next.hasLocationPermission),
      builder: (BuildContext context, PrayerPermissionsState state) {
        final List<PrayerAlertsPermissionStep> steps =
            _pinnedSteps ??
            prayerAlertsSetupPendingSteps(
              hasLocationPermission: state.hasLocationPermission,
              capability: state.capability,
            );

        if (steps.isEmpty) {
          if (state.capability == null && _pinnedSteps == null) {
            return const _PrayerAlertsPermissionLoadingScaffold();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _exitFlow(context);
            }
          });
          return const _PrayerAlertsPermissionLoadingScaffold(
            showProgress: false,
          );
        }

        return PrayerAlertsPermissionFlow(
          steps: steps,
          // Nullable read: the wizard can open outside the prayer-times
          // scope (e.g. onboarding), where no PrayerTimesBloc is provided.
          prayerTimesBloc: context.read<PrayerTimesBloc?>(),
          onFinished: () => _exitFlow(context),
        );
      },
    );
  }

  void _exitFlow(BuildContext context) {
    if (widget.navExtra?.continueToLoginOnFinish ?? false) {
      unawaited(
        getIt<PrayerAlertsPermissionOnboardingRepository>().markFlowCompleted(),
      );
      const LoginRoute().go(context);
      return;
    }
    context.pop();
  }
}

class _PrayerAlertsPermissionLoadingScaffold extends StatelessWidget {
  const _PrayerAlertsPermissionLoadingScaffold({this.showProgress = true});

  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: showProgress
            ? CircularProgressIndicator(
                color: context.colorScheme.primary,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
