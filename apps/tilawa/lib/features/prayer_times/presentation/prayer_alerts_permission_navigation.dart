import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/prayer_times/domain/repositories/prayer_alerts_permission_onboarding_repository.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_permissions_cubit.dart';
import 'package:tilawa/features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import 'package:tilawa/features/prayer_times/presentation/prayer_alerts_setup_pending_steps.dart';
import 'package:tilawa/features/prayer_times/presentation/widgets/prayer_alerts_permission_flow.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa/router/prayer_alerts_permission_nav_extra.dart';

/// Navigates to [PrayerAlertsPermissionRoute] via GoRouter.
abstract final class PrayerAlertsPermissionNavigation {
  /// Shown once after the first-run onboarding carousel, before sign-in.
  static Future<void> showAfterOnboarding(BuildContext context) async {
    await _showWhenPending(
      context,
      markCompletedWhenDone: true,
      refreshPrayerSchedule: false,
    );
  }

  /// Shown once for logged-in users on first home shell activation.
  static Future<void> showIfNeededAfterLaunch(BuildContext context) async {
    await showIfNeeded(context, refreshPrayerSchedule: true);
  }

  /// Auto-prompt once per install before prayer notification settings.
  static Future<void> showIfNeeded(
    BuildContext context, {
    bool refreshPrayerSchedule = true,
  }) async {
    final PrayerAlertsPermissionOnboardingRepository onboarding =
        getIt<PrayerAlertsPermissionOnboardingRepository>();
    if (await onboarding.wasFlowCompleted()) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    await _showWhenPending(
      context,
      markCompletedWhenDone: true,
      refreshPrayerSchedule: refreshPrayerSchedule,
    );
  }

  /// Opens the permission wizard for pending (or explicit) steps.
  static Future<void> show(
    BuildContext context, {
    List<PrayerAlertsPermissionStep>? steps,
  }) async {
    await _showWhenPending(
      context,
      explicitSteps: steps,
      markCompletedWhenDone: false,
      refreshPrayerSchedule: true,
    );
  }

  static Future<void> _showWhenPending(
    BuildContext context, {
    List<PrayerAlertsPermissionStep>? explicitSteps,
    required bool markCompletedWhenDone,
    required bool refreshPrayerSchedule,
  }) async {
    final PrayerAlertsPermissionOnboardingRepository onboarding =
        getIt<PrayerAlertsPermissionOnboardingRepository>();

    final PrayerPermissionsCubit cubit = _permissionsCubitFor(context);
    await cubit.checkCapability();
    if (!context.mounted) {
      return;
    }

    final List<PrayerAlertsPermissionStep> steps =
        explicitSteps ??
        prayerAlertsSetupPendingSteps(
          hasLocationPermission: cubit.state.hasLocationPermission,
          capability: cubit.state.capability,
        );

    if (steps.isEmpty) {
      if (markCompletedWhenDone) {
        await onboarding.markFlowCompleted();
      }
      return;
    }

    await PrayerAlertsPermissionRoute(
      $extra: PrayerAlertsPermissionNavExtra(steps: steps),
    ).push(context);
    if (!context.mounted) {
      return;
    }

    if (refreshPrayerSchedule) {
      await _refreshAfterFlow(context);
    }

    if (markCompletedWhenDone) {
      await onboarding.markFlowCompleted();
    }
  }

  static PrayerPermissionsCubit _permissionsCubitFor(BuildContext context) {
    // Nullable reads here and below: callers may sit outside the
    // prayer-times scope (e.g. onboarding), where neither bloc is provided.
    return context.read<PrayerPermissionsCubit?>() ??
        getIt<PrayerPermissionsCubit>();
  }

  static Future<void> _refreshAfterFlow(BuildContext context) async {
    if (!context.mounted) {
      return;
    }

    final PrayerPermissionsCubit? permissionsCubit =
        context.read<PrayerPermissionsCubit?>();
    await permissionsCubit?.checkCapability();
    if (!context.mounted) {
      return;
    }

    final PrayerTimesBloc? prayerTimesBloc =
        context.read<PrayerTimesBloc?>();
    prayerTimesBloc?.add(
      const PrayerTimesEvent.loadPrayerTimes(forceReschedule: true),
    );
  }
}
