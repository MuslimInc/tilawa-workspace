import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';

import '../cubit/teacher_application_access_cubit.dart';
import '../cubit/teacher_capability_cubit.dart';

/// Loads [TeacherCapability] and remote apply access for Settings teaching UI.
///
/// Refreshes on auth changes, app resume, route visibility, and FCM review push.
class SettingsTeacherCapabilityScope extends StatelessWidget {
  const SettingsTeacherCapabilityScope({super.key, required this.child});

  final Widget child;

  static TeacherCapability? maybeCapabilityOf(BuildContext context) {
    return context.select(
      (TeacherCapabilityCubit cubit) => cubit.state.capability,
    );
  }

  static bool capabilityLoadedOf(BuildContext context) {
    return context.select(
      (TeacherCapabilityCubit cubit) => cubit.state.hasLoaded,
    );
  }

  static bool canApplyAsTeacherOf(BuildContext context) {
    return context.select(
      (TeacherApplicationAccessCubit cubit) => cubit.state.canApplyAsTeacher,
    );
  }

  static bool accessResolvedOf(BuildContext context) {
    return context.select(
      (TeacherApplicationAccessCubit cubit) => cubit.state.hasResolved,
    );
  }

  static bool shouldShowTeachingSectionOf(BuildContext context) {
    final capabilityState = context.watch<TeacherCapabilityCubit>().state;
    return SettingsTeachingVisibility.shouldShowSection(
      capabilityLoaded: capabilityState.hasLoaded,
      capability: capabilityState.capability,
    );
  }

  static bool isTeachingSectionLoadingOf(BuildContext context) {
    final capabilityState = context.watch<TeacherCapabilityCubit>().state;
    return SettingsTeachingVisibility.isLoading(
      capabilityLoaded: capabilityState.hasLoaded,
    );
  }

  /// Reloads capability + access (e.g. after admin approval).
  static void refreshOf(BuildContext context) {
    context.read<TeacherCapabilityCubit>().refresh();
    context.read<TeacherApplicationAccessCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => TeacherCapabilityCubit()..load(),
        ),
        BlocProvider(
          create: (_) => TeacherApplicationAccessCubit()..load(),
        ),
      ],
      child: _SettingsTeacherCapabilityLifecycleListener(child: child),
    );
  }
}

/// Observes auth, app resume, and route visibility.
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

  void _refreshAll() {
    if (!mounted) return;
    context.read<TeacherCapabilityCubit>().refresh();
    context.read<TeacherApplicationAccessCubit>().refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    final capabilityCubit = context.read<TeacherCapabilityCubit>();
    if (isCurrent && capabilityCubit.state.hasLoaded && !_wasRouteCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final stillCurrent = ModalRoute.of(context)?.isCurrent ?? false;
        if (stillCurrent) {
          _refreshAll();
        }
      });
    }
    _wasRouteCurrent = isCurrent;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      listener: (context, state) => _refreshAll(),
      child: widget.child,
    );
  }
}
