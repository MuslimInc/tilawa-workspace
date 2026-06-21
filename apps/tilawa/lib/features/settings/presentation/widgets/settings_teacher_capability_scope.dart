import 'package:flutter/material.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/quran_sessions/presentation/quran_sessions_user.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_feature_flags.dart';

/// Loads [TeacherCapability] once for Settings profile + teaching section.
class SettingsTeacherCapabilityScope extends StatefulWidget {
  const SettingsTeacherCapabilityScope({super.key, required this.child});

  final Widget child;

  static TeacherCapability? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedTeacherCapability>()
        ?.capability;
  }

  static bool isLoadingOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_InheritedTeacherCapability>()
            ?.isLoading ??
        false;
  }

  @override
  State<SettingsTeacherCapabilityScope> createState() =>
      _SettingsTeacherCapabilityScopeState();
}

class _SettingsTeacherCapabilityScopeState
    extends State<SettingsTeacherCapabilityScope> {
  TeacherCapability? _capability;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = quranSessionsFeatureConfig();
    if (!config.showProfileTeacherEntry) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    final userId = quranSessionsCurrentUserId(getIt);
    if (userId == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    final result = await getIt<GetCurrentUserTeacherCapabilityUseCase>()(
      userId,
    );
    if (!mounted) return;

    setState(() {
      _loading = false;
      _capability = result.fold(
        (_) => const TeacherCapability(state: TeacherCapabilityState.none),
        (capability) => capability,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedTeacherCapability(
      capability: _capability,
      isLoading: _loading,
      child: widget.child,
    );
  }
}

class _InheritedTeacherCapability extends InheritedWidget {
  const _InheritedTeacherCapability({
    required this.capability,
    required this.isLoading,
    required super.child,
  });

  final TeacherCapability? capability;
  final bool isLoading;

  @override
  bool updateShouldNotify(_InheritedTeacherCapability oldWidget) {
    return oldWidget.capability != capability ||
        oldWidget.isLoading != isLoading;
  }
}
