import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/quran_sessions.dart';

import '../cubit/teacher_capability_cubit.dart';

/// Loads [TeacherCapability] for Settings profile + teaching section.
///
/// Refreshes when the settings route becomes visible again (e.g. after popping
/// back from teacher application status), when the app resumes, and when an FCM
/// `teacher_application_reviewed` push arrives while this scope is mounted.
class SettingsTeacherCapabilityScope extends StatelessWidget {
  const SettingsTeacherCapabilityScope({super.key, required this.child});

  final Widget child;

  static TeacherCapability? maybeOf(BuildContext context) {
    return context.select(
      (TeacherCapabilityCubit cubit) => cubit.state.capability,
    );
  }

  static bool isLoadingOf(BuildContext context) {
    return context.select(
      (TeacherCapabilityCubit cubit) => cubit.state.isLoading,
    );
  }

  /// Reloads capability from Firestore (e.g. after admin approval).
  static void refreshOf(BuildContext context) {
    context.read<TeacherCapabilityCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TeacherCapabilityCubit()..load(),
      child: _SettingsTeacherCapabilityLifecycleListener(child: child),
    );
  }
}

/// Observes app resume and route visibility; delegates refresh to the cubit.
class _SettingsTeacherCapabilityLifecycleListener extends StatefulWidget {
  const _SettingsTeacherCapabilityLifecycleListener({required this.child});

  final Widget child;

  @override
  State<_SettingsTeacherCapabilityLifecycleListener> createState() =>
      _SettingsTeacherCapabilityLifecycleListenerState();
}

class _SettingsTeacherCapabilityLifecycleListenerState
    extends State<_SettingsTeacherCapabilityLifecycleListener>
    with WidgetsBindingObserver {
  bool _wasRouteCurrent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<TeacherCapabilityCubit>().refresh();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    final cubit = context.read<TeacherCapabilityCubit>();
    if (isCurrent && cubit.state.hasLoaded && !_wasRouteCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final stillCurrent = ModalRoute.of(context)?.isCurrent ?? false;
        if (stillCurrent) {
          context.read<TeacherCapabilityCubit>().refresh();
        }
      });
    }
    _wasRouteCurrent = isCurrent;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
