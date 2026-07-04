import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Builds the in-call media surface (e.g. Agora tiles) for non-external sessions.
typedef InAppCallSurfaceBuilder =
    Widget? Function(
      BuildContext context, {
      required String sessionId,
      required SessionCallType callType,
      required SessionCallProviderKind callProviderKind,
    });

SystemUiOverlayStyle _callShellSystemUiOverlayStyle(
  ThemeData theme, {
  required bool hasCallSurface,
}) {
  final Color statusBackground = hasCallSurface
      ? theme.colorScheme.scrim.withValues(alpha: 1)
      : theme.colorScheme.surfaceContainerHigh;
  final Brightness statusBarBrightness = ThemeData.estimateBrightnessForColor(
    statusBackground,
  );
  final Brightness statusIconBrightness = statusBarBrightness == Brightness.dark
      ? Brightness.light
      : Brightness.dark;

  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: statusIconBrightness,
    statusBarBrightness: statusBarBrightness,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: statusIconBrightness,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );
}

/// Approximates [AppSystemChromeStyle.buildDefaultAppStyle] when leaving call.
SystemUiOverlayStyle _restoreRouteSystemUiOverlayStyle(ThemeData theme) {
  final Color statusBackground = theme.scaffoldBackgroundColor;
  final Color navigationBarColor =
      theme.componentTokens.adaptiveShell.bottomNavBackgroundColor;

  final Brightness statusBarBrightness = ThemeData.estimateBrightnessForColor(
    statusBackground,
  );
  final Brightness statusIconBrightness = statusBarBrightness == Brightness.dark
      ? Brightness.light
      : Brightness.dark;
  final Brightness navBarBrightness = ThemeData.estimateBrightnessForColor(
    navigationBarColor,
  );
  final Brightness navIconBrightness = navBarBrightness == Brightness.dark
      ? Brightness.light
      : Brightness.dark;

  return SystemUiOverlayStyle(
    statusBarColor: statusBackground.withValues(alpha: 1),
    statusBarIconBrightness: statusIconBrightness,
    statusBarBrightness: statusBarBrightness,
    systemNavigationBarColor: navigationBarColor.withValues(alpha: 1),
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: navIconBrightness,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );
}

/// In-app call surface for mock/Agora/WebRTC joins.
///
/// Host app pushes this after [JoinSessionUseCase] succeeds for non-external
/// sessions. Media controls delegate to [SessionCallControlGateway] via cubit.
class InAppCallShellScreen extends StatefulWidget {
  const InAppCallShellScreen({
    super.key,
    required this.sessionId,
    this.callType,
    this.callProviderKind,
    this.participantName,
    this.participantSubtitle,
    this.callSurface,
    this.callControlGateway,
    this.callTelemetry,
  });

  final String sessionId;
  final SessionCallType? callType;
  final SessionCallProviderKind? callProviderKind;
  final String? participantName;
  final String? participantSubtitle;
  final Widget? callSurface;
  final SessionCallControlGateway? callControlGateway;
  final QuranSessionCallTelemetryCoordinator? callTelemetry;

  @override
  State<InAppCallShellScreen> createState() => _InAppCallShellScreenState();
}

class _InAppCallShellScreenState extends State<InAppCallShellScreen> {
  QuranSessionCallControlCubit? _callControlCubit;
  InAppCallConnectionPhase _connectionPhase =
      InAppCallConnectionPhase.connecting;
  SystemUiOverlayStyle? _restoreOverlayStyle;

  bool get _isVideoCall => widget.callType == SessionCallType.videoCall;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restoreOverlayStyle = _restoreRouteSystemUiOverlayStyle(Theme.of(context));
  }

  @override
  void initState() {
    super.initState();
    final gateway = widget.callControlGateway;
    if (gateway != null) {
      final providerKind =
          widget.callProviderKind ?? SessionCallProviderKind.mock;
      final callType = widget.callType ?? SessionCallType.voiceCall;
      _callControlCubit = QuranSessionCallControlCubit(
        gateway: gateway,
        isVideoCall: _isVideoCall,
        capabilities: SessionCallControlCapabilities.forSession(
          providerKind: providerKind,
          callType: callType,
        ),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyCallShellSystemUiOverlay();
    });
  }

  void _applyCallShellSystemUiOverlay() {
    if (!mounted) {
      return;
    }
    SystemChrome.setSystemUIOverlayStyle(
      _callShellSystemUiOverlayStyle(
        Theme.of(context),
        hasCallSurface: widget.callSurface != null,
      ),
    );
  }

  @override
  void dispose() {
    final restoreStyle = _restoreOverlayStyle;
    if (restoreStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(restoreStyle);
    }
    final cubit = _callControlCubit;
    final gateway = widget.callControlGateway;
    final ended = cubit?.state.hasEndedCall ?? false;
    cubit?.close();
    _callControlCubit = null;
    if (gateway != null && !ended) {
      unawaited(gateway.leave());
    }
    widget.callTelemetry?.unbindSession();
    super.dispose();
  }

  Future<void> _endCall() async {
    final cubit = _callControlCubit;
    if (cubit != null) {
      await cubit.endCall();
      if (!mounted || cubit.state.isEndCallLoading) {
        return;
      }
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onConnectionPhaseChanged(InAppCallConnectionPhase phase) {
    if (_connectionPhase == phase) {
      return;
    }
    setState(() => _connectionPhase = phase);
  }

  @override
  Widget build(BuildContext context) {
    final shell = _InAppCallShellView(
      sessionId: widget.sessionId,
      callProviderKind: widget.callProviderKind,
      participantName: widget.participantName,
      participantSubtitle: widget.participantSubtitle,
      callSurface: widget.callSurface,
      connectionPhase: _connectionPhase,
      isVideoCall: _isVideoCall,
      onConnectionPhaseChanged: _onConnectionPhaseChanged,
      onEndCall: _endCall,
    );

    final cubit = _callControlCubit;
    if (cubit == null) {
      return shell;
    }

    return BlocProvider.value(
      value: cubit,
      child:
          BlocListener<
            QuranSessionCallControlCubit,
            QuranSessionCallControlState
          >(
            listenWhen: (previous, current) =>
                current.feedback == CallControlFeedback.actionFailed,
            listener: (context, state) {
              final l10n = context.quranSessionsL10n;
              TilawaFeedback.showToast(
                context,
                message: l10n.inAppCallShellControlActionFailed,
                variant: TilawaFeedbackVariant.error,
              );
              context.read<QuranSessionCallControlCubit>().clearFeedback();
            },
            child: shell,
          ),
    );
  }
}

class _InAppCallShellView extends StatelessWidget {
  const _InAppCallShellView({
    required this.sessionId,
    required this.connectionPhase,
    required this.isVideoCall,
    required this.onConnectionPhaseChanged,
    required this.onEndCall,
    this.callProviderKind,
    this.participantName,
    this.participantSubtitle,
    this.callSurface,
  });

  final String sessionId;
  final SessionCallProviderKind? callProviderKind;
  final String? participantName;
  final String? participantSubtitle;
  final Widget? callSurface;
  final InAppCallConnectionPhase connectionPhase;
  final bool isVideoCall;
  final ValueChanged<InAppCallConnectionPhase> onConnectionPhaseChanged;
  final Future<void> Function() onEndCall;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final hasCallSurface = callSurface != null;

    final statusSubtitle = _resolveStatusSubtitle(l10n);
    final displayName = participantName ?? l10n.inAppCallShellTitle;
    final overlayStyle = _callShellSystemUiOverlayStyle(
      Theme.of(context),
      hasCallSurface: hasCallSurface,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        unawaited(onEndCall());
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        sized: false,
        value: overlayStyle,
        child: Scaffold(
          backgroundColor: colorScheme.scrim,
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (hasCallSurface)
                InAppCallConnectionReporter(
                  onPhaseChanged: onConnectionPhaseChanged,
                  remoteParticipantDisplayName: displayName,
                  child: callSurface!,
                )
              else
                _MockCallBackground(statusSubtitle: statusSubtitle),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: tokens.spaceMedium,
                        top: tokens.spaceSmall,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _CallEndGuard(
                          onEndCall: onEndCall,
                          builder: (context, canEndCall) {
                            return _CallChromeIconButton(
                              key: const Key('call_shell_back'),
                              iconWidget: const BackButtonIcon(),
                              label: l10n.inAppCallShellEndCall,
                              onPressed: canEndCall
                                  ? () => unawaited(onEndCall())
                                  : null,
                            );
                          },
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_readCallControlCubit(context) != null)
                      BlocBuilder<
                        QuranSessionCallControlCubit,
                        QuranSessionCallControlState
                      >(
                        builder: (context, state) {
                          final cubit = context
                              .read<QuranSessionCallControlCubit>();
                          return _CallControlsRow(
                            state: state,
                            muteLabel: state.isMuted
                                ? l10n.inAppCallShellUnmute
                                : l10n.inAppCallShellMute,
                            endCallLabel: l10n.inAppCallShellEndCall,
                            speakerLabel: l10n.inAppCallShellSpeaker,
                            switchCameraLabel: l10n.inAppCallShellFlipCamera,
                            turnVideoOnLabel: l10n.inAppCallShellTurnVideoOn,
                            turnVideoOffLabel: l10n.inAppCallShellTurnVideoOff,
                            onToggleMute: () =>
                                unawaited(cubit.toggleMicrophone()),
                            onToggleVideo: () =>
                                unawaited(cubit.toggleCamera()),
                            onToggleSpeaker: () =>
                                unawaited(cubit.toggleSpeaker()),
                            onSwitchCamera: () =>
                                unawaited(cubit.switchCamera()),
                            onEndCall: () => unawaited(onEndCall()),
                          );
                        },
                      )
                    else
                      _CallControlsRow(
                        state: QuranSessionCallControlState(
                          isVideoCall: isVideoCall,
                          capabilities: const SessionCallControlCapabilities(
                            microphone: false,
                            camera: false,
                            speaker: false,
                            switchCamera: false,
                          ),
                        ),
                        muteLabel: l10n.inAppCallShellMute,
                        endCallLabel: l10n.inAppCallShellEndCall,
                        speakerLabel: l10n.inAppCallShellSpeaker,
                        switchCameraLabel: l10n.inAppCallShellFlipCamera,
                        turnVideoOnLabel: l10n.inAppCallShellTurnVideoOn,
                        turnVideoOffLabel: l10n.inAppCallShellTurnVideoOff,
                        onToggleMute: () {},
                        onToggleVideo: () {},
                        onToggleSpeaker: () {},
                        onSwitchCamera: () {},
                        onEndCall: () => unawaited(onEndCall()),
                      ),
                    SizedBox(height: tokens.spaceMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveStatusSubtitle(QuranSessionsLocalizations l10n) {
    if (connectionPhase == InAppCallConnectionPhase.participantJoined &&
        participantSubtitle != null) {
      return participantSubtitle!;
    }

    return switch (connectionPhase) {
      InAppCallConnectionPhase.connecting => l10n.inAppCallShellConnecting,
      InAppCallConnectionPhase.waitingForParticipant =>
        l10n.inAppCallShellWaitingForParticipant,
      InAppCallConnectionPhase.participantJoined =>
        l10n.inAppCallShellConnected,
    };
  }
}

class _MockCallBackground extends StatelessWidget {
  const _MockCallBackground({required this.statusSubtitle});

  final String statusSubtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.surfaceContainerHigh,
                  colorScheme.surfaceContainerHighest,
                ],
              ),
            ),
          ),
          Center(
            child: _CallWaitingPlaceholder(
              icon: Icons.hourglass_top_outlined,
              message: statusSubtitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _CallControlsRow extends StatelessWidget {
  const _CallControlsRow({
    required this.state,
    required this.muteLabel,
    required this.endCallLabel,
    required this.speakerLabel,
    required this.switchCameraLabel,
    required this.turnVideoOnLabel,
    required this.turnVideoOffLabel,
    required this.onToggleMute,
    required this.onEndCall,
    required this.onToggleVideo,
    required this.onToggleSpeaker,
    required this.onSwitchCamera,
  });

  final QuranSessionCallControlState state;
  final String muteLabel;
  final String endCallLabel;
  final String speakerLabel;
  final String switchCameraLabel;
  final String turnVideoOnLabel;
  final String turnVideoOffLabel;
  final VoidCallback onToggleMute;
  final VoidCallback onEndCall;
  final VoidCallback onToggleVideo;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onSwitchCamera;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    final controls = <Widget>[
      if (state.capabilities.microphone)
        _CallChromeIconButton(
          key: const Key('call_shell_mute'),
          icon: state.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: muteLabel,
          onPressed: state.canToggleMicrophone ? onToggleMute : null,
          isLoading: state.isMicrophoneLoading,
          isActive: state.isMicrophoneEnabled,
        ),
      if (state.isVideoCall && state.capabilities.camera)
        _CallChromeIconButton(
          key: const Key('call_shell_video'),
          icon: state.isCameraEnabled
              ? Icons.videocam_rounded
              : Icons.videocam_off_rounded,
          label: state.isCameraEnabled ? turnVideoOffLabel : turnVideoOnLabel,
          onPressed: state.canToggleCamera ? onToggleVideo : null,
          isLoading: state.isCameraLoading,
          isActive: state.isCameraEnabled,
        ),
      _CallEndButton(
        key: const Key('call_shell_end'),
        label: endCallLabel,
        onPressed: state.canEndCall ? onEndCall : null,
        isLoading: state.isEndCallLoading,
      ),
      if (state.capabilities.speaker)
        _CallChromeIconButton(
          key: const Key('call_shell_speaker'),
          icon: state.isSpeakerEnabled
              ? Icons.volume_up_rounded
              : Icons.hearing_rounded,
          label: speakerLabel,
          onPressed: state.canToggleSpeaker ? onToggleSpeaker : null,
          isLoading: state.isSpeakerLoading,
          isActive: state.isSpeakerEnabled,
        ),
      if (state.isVideoCall &&
          state.capabilities.switchCamera &&
          state.capabilities.hasMultipleCameras)
        _SwitchCameraButton(
          key: const Key('call_shell_flip'),
          icon: Icons.cameraswitch,
          label: switchCameraLabel,
          cameraFacing: state.cameraFacing,
          onPressed: state.canSwitchCamera ? onSwitchCamera : null,
          isLoading: state.isSwitchCameraLoading,
        ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: controls,
      ),
    );
  }
}

class _CallWaitingPlaceholder extends StatelessWidget {
  const _CallWaitingPlaceholder({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;
    final avatarRadius = tokens.iconSizeLargePlus + tokens.spaceMedium;

    return Padding(
      padding: EdgeInsets.all(tokens.spaceLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              icon,
              size: tokens.iconSizeLargePlus,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          SizedBox(height: tokens.spaceLarge),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CallChromeIconButton extends StatelessWidget {
  const _CallChromeIconButton({
    super.key,
    this.icon,
    this.iconWidget,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isActive = false,
    this.iconColorOverride,
    this.highlightWhenActive = true,
    this.useToggleSemantics = true,
  }) : assert(icon != null || iconWidget != null);

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isActive;
  final Color? iconColorOverride;

  /// When false, [isActive] only drives semantics — surface stays neutral
  /// (e.g. flip camera is a secondary action, not an on/off toggle).
  final bool highlightWhenActive;

  /// When false, semantics omit [Semantics.toggled] (non-toggle actions).
  final bool useToggleSemantics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final composerTokens = theme.componentTokens.immersiveComposer;
    final toggleTokens = theme.componentTokens.iconToggle;
    final size = composerTokens.headerButtonSize;
    final showActiveHighlight = isActive && highlightWhenActive;
    final fillColor = showActiveHighlight
        ? colorScheme.primary
        : toggleTokens.inactiveBackgroundColor;
    final iconColor =
        iconColorOverride ??
        (showActiveHighlight
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant);

    return Semantics(
      button: true,
      toggled: useToggleSemantics ? isActive : null,
      label: label,
      enabled: onPressed != null,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: tokens.minInteractiveDimension,
          minHeight: tokens.minInteractiveDimension,
        ),
        child: Material(
          color: fillColor,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: isLoading
                  ? Padding(
                      padding: EdgeInsets.all(tokens.spaceSmall),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    )
                  : iconWidget != null
                  ? IconTheme(
                      data: IconThemeData(
                        color: onPressed == null
                            ? iconColor.withValues(alpha: 0.38)
                            : iconColor,
                        size: tokens.iconSizeMedium,
                      ),
                      child: iconWidget!,
                    )
                  : Icon(
                      icon!,
                      color: onPressed == null
                          ? iconColor.withValues(alpha: 0.38)
                          : iconColor,
                      size: tokens.iconSizeMedium,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _switchCameraIconColor(
  ColorScheme colorScheme,
  SessionCallCameraFacing cameraFacing,
) {
  return switch (cameraFacing) {
    SessionCallCameraFacing.front => colorScheme.onSurface,
    SessionCallCameraFacing.back => colorScheme.onSurfaceVariant,
  };
}

/// Switch-camera control — always neutral styling with tap rotation feedback.
class _SwitchCameraButton extends StatefulWidget {
  const _SwitchCameraButton({
    super.key,
    required this.icon,
    required this.label,
    required this.cameraFacing,
    required this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final SessionCallCameraFacing cameraFacing;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<_SwitchCameraButton> createState() => _SwitchCameraButtonState();
}

class _SwitchCameraButtonState extends State<_SwitchCameraButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void didUpdateWidget(covariant _SwitchCameraButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      unawaited(_rotationController.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _CallChromeIconButton(
      iconWidget: RotationTransition(
        turns: Tween<double>(begin: 0, end: 0.5).animate(
          CurvedAnimation(
            parent: _rotationController,
            curve: Curves.easeInOut,
          ),
        ),
        child: Icon(widget.icon),
      ),
      label: widget.label,
      onPressed: widget.onPressed,
      isLoading: widget.isLoading,
      iconColorOverride: _switchCameraIconColor(
        colorScheme,
        widget.cameraFacing,
      ),
      highlightWhenActive: false,
      useToggleSemantics: false,
    );
  }
}

class _CallEndButton extends StatelessWidget {
  const _CallEndButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final composerTokens = Theme.of(context).componentTokens.immersiveComposer;
    final size = composerTokens.headerButtonSize * 1.25;

    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: Material(
        color: onPressed == null
            ? colorScheme.error.withValues(alpha: 0.38)
            : colorScheme.error,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: isLoading
                ? Padding(
                    padding: EdgeInsets.all(tokens.spaceSmall),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onError,
                    ),
                  )
                : Icon(
                    Icons.call_end_rounded,
                    color: colorScheme.onError,
                    size: tokens.iconSizeLarge,
                  ),
          ),
        ),
      ),
    );
  }
}

QuranSessionCallControlCubit? _readCallControlCubit(BuildContext context) {
  try {
    return context.read<QuranSessionCallControlCubit>();
  } on ProviderNotFoundException {
    return null;
  }
}

class _CallEndGuard extends StatelessWidget {
  const _CallEndGuard({
    required this.onEndCall,
    required this.builder,
  });

  final Future<void> Function() onEndCall;
  final Widget Function(BuildContext context, bool canEndCall) builder;

  @override
  Widget build(BuildContext context) {
    final cubit = _readCallControlCubit(context);
    if (cubit == null) {
      return builder(context, true);
    }

    return BlocBuilder<
      QuranSessionCallControlCubit,
      QuranSessionCallControlState
    >(
      builder: (context, state) => builder(context, state.canEndCall),
    );
  }
}
