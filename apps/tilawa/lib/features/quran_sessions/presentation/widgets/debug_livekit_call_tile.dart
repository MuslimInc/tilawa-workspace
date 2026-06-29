import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/core/bootstrap/app_launch_config.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tilawa/features/quran_sessions/debug/join_debug_livekit_call.dart';
import 'package:tilawa/features/quran_sessions/debug/quran_sessions_debug_tools.dart';
import 'package:tilawa/features/quran_sessions/quran_sessions_launch_policy.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Settings entry to join the fixed debug LiveKit room for QA smoke tests.
class DebugLiveKitCallTile extends StatefulWidget {
  const DebugLiveKitCallTile({
    super.key,
    this.isLast = false,
    @visibleForTesting this.visibilityGate,
    @visibleForTesting this.liveKitEnabled,
  });

  final bool isLast;

  /// Overrides [isQuranSessionsDebugToolsVisible] in tests.
  @visibleForTesting
  final bool Function()? visibilityGate;

  /// Overrides LiveKit launch-config lookup in tests.
  @visibleForTesting
  final bool? liveKitEnabled;

  @override
  State<DebugLiveKitCallTile> createState() => _DebugLiveKitCallTileState();
}

class _DebugLiveKitCallTileState extends State<DebugLiveKitCallTile> {
  bool _joinInProgress = false;

  @override
  Widget build(BuildContext context) {
    final visible =
        widget.visibilityGate?.call() ?? isQuranSessionsDebugToolsVisible();
    if (!visible) {
      return const SizedBox.shrink();
    }

    final liveKitEnabled =
        widget.liveKitEnabled ??
        resolveRtcLaunchConfig(getIt<AppLaunchConfig>()).isLiveKitEnabled;
    if (!liveKitEnabled) {
      return const SizedBox.shrink();
    }

    final isGuest = context.watch<AuthBloc>().state is! AuthAuthenticated;
    if (isGuest) {
      return const SizedBox.shrink();
    }

    return TilawaSettingsTile(
      icon: FluentIcons.video_24_regular,
      title: 'Test LiveKit video call',
      subtitle: 'Join room $kDebugLiveKitRoomName (debug/staging only)',
      showDivider: !widget.isLast,
      onTap: () {
        if (_joinInProgress) {
          return;
        }
        unawaited(_startJoin(context));
      },
      trailing: _joinInProgress
          ? SizedBox(
              width: Theme.of(context).tokens.iconSizeMedium,
              height: Theme.of(context).tokens.iconSizeMedium,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }

  Future<void> _startJoin(BuildContext context) async {
    setState(() => _joinInProgress = true);
    try {
      await joinDebugLiveKitVideoCall(context);
    } on RtcCallJoinFailure catch (failure) {
      if (!context.mounted) {
        return;
      }
      final message = failure.reasonCode == 'debug_callable_not_deployed'
          ? kDebugLiveKitCallableNotDeployedMessage
          : failure.toLocalizedMessage(context);
      TilawaFeedback.showToast(
        context,
        message: message,
        variant: TilawaFeedbackVariant.error,
      );
    } on QuranSessionsFailure catch (failure) {
      if (!context.mounted) {
        return;
      }
      TilawaFeedback.showToast(
        context,
        message: failure.toLocalizedMessage(context),
        variant: TilawaFeedbackVariant.error,
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      TilawaFeedback.showToast(
        context,
        message: error.toString(),
        variant: TilawaFeedbackVariant.error,
      );
    } finally {
      if (mounted) {
        setState(() => _joinInProgress = false);
      }
    }
  }
}
