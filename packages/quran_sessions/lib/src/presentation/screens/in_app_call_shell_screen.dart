import 'dart:async';
import 'dart:ui';

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

  bool get _isVideoCall => widget.callType == SessionCallType.videoCall;

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
  }

  @override
  void dispose() {
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
                current.feedback != null &&
                current.feedback != previous.feedback,
            listener: (context, state) {
              final message = _feedbackMessage(
                context.quranSessionsL10n,
                state.feedback,
              );
              if (message == null) {
                return;
              }
              TilawaFeedback.showToast(
                context,
                message: message,
                variant: state.feedback == CallControlFeedback.actionFailed
                    ? TilawaFeedbackVariant.error
                    : TilawaFeedbackVariant.info,
              );
              context.read<QuranSessionCallControlCubit>().clearFeedback();
            },
            child: shell,
          ),
    );
  }

  String? _feedbackMessage(
    QuranSessionsLocalizations l10n,
    CallControlFeedback? feedback,
  ) {
    return switch (feedback) {
      CallControlFeedback.microphoneMuted => l10n.inAppCallShellMicrophoneMuted,
      CallControlFeedback.microphoneUnmuted =>
        l10n.inAppCallShellMicrophoneUnmuted,
      CallControlFeedback.cameraOff => l10n.inAppCallShellCameraOff,
      CallControlFeedback.cameraOn => l10n.inAppCallShellCameraOn,
      CallControlFeedback.switchCameraBlocked =>
        l10n.inAppCallShellSwitchCameraBlocked,
      CallControlFeedback.speakerOn => l10n.inAppCallShellSpeakerOn,
      CallControlFeedback.speakerOff => l10n.inAppCallShellSpeakerOff,
      CallControlFeedback.actionFailed =>
        l10n.inAppCallShellControlActionFailed,
      null => null,
    };
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
    final isMockPreview = callProviderKind == SessionCallProviderKind.mock;

    final statusSubtitle = _resolveStatusSubtitle(l10n);
    final displayName = participantName ?? l10n.inAppCallShellTitle;
    final cubit = _readCallControlCubit(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        unawaited(onEndCall());
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: colorScheme.scrim,
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (hasCallSurface)
                InAppCallConnectionReporter(
                  onPhaseChanged: onConnectionPhaseChanged,
                  child: callSurface!,
                )
              else
                _MockCallBackground(
                  isMockPreview: isMockPreview,
                  mockBetaMessage: l10n.inAppCallShellMockBetaBody,
                  statusSubtitle: statusSubtitle,
                ),
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
                        child: _CallChromeIconButton(
                          key: const Key('call_shell_back'),
                          icon: Icons.arrow_back_rounded,
                          label: l10n.inAppCallShellEndCall,
                          onPressed: cubit?.state.canEndCall ?? true
                              ? () => unawaited(onEndCall())
                              : null,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spaceMedium,
                      ),
                      child: _CallParticipantBar(
                        name: displayName,
                        subtitle: statusSubtitle,
                      ),
                    ),
                    SizedBox(height: tokens.spaceMedium),
                    if (cubit != null)
                      _CallControlsRow(
                        state: cubit.state,
                        muteLabel: cubit.state.isMuted
                            ? l10n.inAppCallShellUnmute
                            : l10n.inAppCallShellMute,
                        endCallLabel: l10n.inAppCallShellEndCall,
                        speakerLabel: l10n.inAppCallShellSpeaker,
                        flipCameraLabel: l10n.inAppCallShellFlipCamera,
                        turnVideoOnLabel: l10n.inAppCallShellTurnVideoOn,
                        turnVideoOffLabel: l10n.inAppCallShellTurnVideoOff,
                        onToggleMute: () => unawaited(cubit.toggleMicrophone()),
                        onToggleVideo: () => unawaited(cubit.toggleCamera()),
                        onToggleSpeaker: () => unawaited(cubit.toggleSpeaker()),
                        onSwitchCamera: () => unawaited(cubit.switchCamera()),
                        onEndCall: () => unawaited(onEndCall()),
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
                        flipCameraLabel: l10n.inAppCallShellFlipCamera,
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
  const _MockCallBackground({
    required this.isMockPreview,
    required this.mockBetaMessage,
    required this.statusSubtitle,
  });

  final bool isMockPreview;
  final String mockBetaMessage;
  final String statusSubtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;

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
          if (isMockPreview)
            PositionedDirectional(
              top: tokens.spaceXXL * 2,
              start: tokens.spaceMedium,
              end: tokens.spaceMedium,
              child: _CallGlassPanel(
                child: Padding(
                  padding: EdgeInsets.all(tokens.spaceMedium),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.onSurface,
                        size: tokens.iconSizeMedium,
                      ),
                      SizedBox(width: tokens.spaceSmall),
                      Expanded(
                        child: Text(
                          mockBetaMessage,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CallParticipantBar extends StatelessWidget {
  const _CallParticipantBar({
    required this.name,
    required this.subtitle,
  });

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final composerTokens = Theme.of(context).componentTokens.immersiveComposer;

    return _CallGlassPanel(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: tokens.spaceSmall,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: tokens.iconSizeLarge,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.person_outline,
                color: colorScheme.onPrimaryContainer,
                size: tokens.iconSizeLarge,
              ),
            ),
            SizedBox(width: tokens.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: composerTokens.topBarSubtitleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _CallControlsRow extends StatelessWidget {
  const _CallControlsRow({
    required this.state,
    required this.muteLabel,
    required this.endCallLabel,
    required this.speakerLabel,
    required this.flipCameraLabel,
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
  final String flipCameraLabel;
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
          icon: state.isMuted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
          label: muteLabel,
          onPressed: state.canToggleMicrophone ? onToggleMute : null,
          isLoading: state.isMicrophoneLoading,
          isActive: !state.isMuted,
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
      if (state.isVideoCall && state.capabilities.switchCamera)
        _CallChromeIconButton(
          key: const Key('call_shell_flip'),
          icon: Icons.flip_camera_ios_rounded,
          label: flipCameraLabel,
          onPressed: state.canSwitchCamera && state.isCameraEnabled
              ? onSwitchCamera
              : null,
          isLoading: state.isSwitchCameraLoading,
          isActive: state.isCameraEnabled,
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

class _CallGlassPanel extends StatelessWidget {
  const _CallGlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final composerTokens = Theme.of(context).componentTokens.immersiveComposer;
    final radius = BorderRadius.circular(
      tokens.resolveRadius(family: TilawaRadiusFamily.chrome),
    );

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: tokens.blurGlass * composerTokens.backgroundBlurScale,
          sigmaY: tokens.blurGlass * composerTokens.backgroundBlurScale,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: composerTokens.overlayPanelTranslucentFillColor,
            borderRadius: radius,
            border: Border.all(color: composerTokens.panelBorderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CallChromeIconButton extends StatelessWidget {
  const _CallChromeIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final composerTokens = Theme.of(context).componentTokens.immersiveComposer;
    final size = composerTokens.headerButtonSize;
    final fillColor = isActive
        ? colorScheme.primaryContainer
        : composerTokens.headerIconButtonFillColor;
    final iconColor = isActive
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
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
                : Icon(
                    icon,
                    color: onPressed == null
                        ? iconColor.withValues(alpha: 0.38)
                        : iconColor,
                    size: tokens.iconSizeMedium,
                  ),
          ),
        ),
      ),
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
    return context.watch<QuranSessionCallControlCubit>();
  } on ProviderNotFoundException {
    return null;
  }
}
