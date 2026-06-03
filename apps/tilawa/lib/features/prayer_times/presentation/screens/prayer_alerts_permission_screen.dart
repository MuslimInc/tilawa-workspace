import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/router/prayer_alerts_permission_nav_extra.dart';

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
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerPermissionsCubit, PrayerPermissionsState>(
      buildWhen: (PrayerPermissionsState prev, PrayerPermissionsState next) =>
          prev.capability != next.capability ||
          prev.hasLocationPermission != next.hasLocationPermission,
      builder: (BuildContext context, PrayerPermissionsState state) {
        final List<PrayerAlertsPermissionStep> steps =
            widget.navExtra?.steps ??
            prayerAlertsSetupPendingSteps(
              hasLocationPermission: state.hasLocationPermission,
              capability: state.capability,
            );

        if (steps.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.pop();
            }
          });
          return const SizedBox.shrink();
        }

        return PrayerAlertsPermissionFlow(
          steps: steps,
          prayerTimesBloc: _tryReadPrayerTimesBloc(),
          onFinished: () => context.pop(),
        );
      },
    );
  }

  PrayerTimesBloc? _tryReadPrayerTimesBloc() {
    try {
      return context.read<PrayerTimesBloc>();
    } on Object {
      return null;
    }
  }
}
