import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../boundaries/call/agora_rtc_engine_pool.dart';
import 'package:quran_sessions_rtc/quran_sessions_rtc.dart';

enum _AgoraCallConnectionPhase {
  connecting,
  waitingForParticipant,
  participantJoined,
  reconnecting,
}

/// Agora voice/video in-call surface backed by an active [AgoraRtcEnginePool] session.
class AgoraCallSurface extends StatefulWidget {
  const AgoraCallSurface({
    super.key,
    required this.sessionId,
    required this.callType,
    required this.enginePool,
    required this.labels,
    this.eventHub,
  });

  final String sessionId;
  final SessionCallType callType;
  final AgoraRtcEnginePool enginePool;
  final AgoraCallSurfaceLabels labels;
  final SessionCallProviderEventHub? eventHub;

  @override
  State<AgoraCallSurface> createState() => _AgoraCallSurfaceState();
}

class _AgoraCallSurfaceState extends State<AgoraCallSurface> {
  _AgoraCallConnectionPhase _phase = _AgoraCallConnectionPhase.connecting;
  int? _remoteUid;
  String? _channelId;
  bool _remoteVideoReady = false;
  bool _localVideoReady = false;
  RtcEngineEventHandler? _eventHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindEngineEvents());
  }

  @override
  void didUpdateWidget(covariant AgoraCallSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      _unbindEngineEvents(oldWidget.sessionId);
      _remoteUid = null;
      _channelId = null;
      _remoteVideoReady = false;
      _localVideoReady = false;
      _phase = _AgoraCallConnectionPhase.connecting;
      _bindEngineEvents();
      _reportConnectionPhase();
    }
  }

  @override
  void dispose() {
    _unbindEngineEvents();
    super.dispose();
  }

  RtcEngine? get _engine =>
      widget.enginePool.sessionFor(widget.sessionId)?.engine;

  void _bindEngineEvents() {
    final engine = _engine;
    if (engine == null) {
      return;
    }

    _eventHandler = RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        if (!mounted) return;
        setState(() {
          _channelId = connection.channelId;
          _phase = _AgoraCallConnectionPhase.waitingForParticipant;
        });
        _reportConnectionPhase();
      },
      onConnectionStateChanged: (connection, state, reason) {
        if (!mounted) return;
        // Map Agora connection state to provider-agnostic reconnect events
        // so the telemetry coordinator (already throttled) and the UI can
        // react to network flutter without the user seeing a frozen screen.
        switch (state) {
          case ConnectionStateType.connectionStateReconnecting:
            widget.eventHub?.emit(
              SessionCallReconnecting(sessionId: widget.sessionId),
            );
            if (_phase == _AgoraCallConnectionPhase.participantJoined ||
                _phase == _AgoraCallConnectionPhase.waitingForParticipant) {
              setState(() {
                _phase = _AgoraCallConnectionPhase.reconnecting;
              });
              _reportConnectionPhase();
            }
          case ConnectionStateType.connectionStateConnected:
            if (_phase == _AgoraCallConnectionPhase.reconnecting) {
              widget.eventHub?.emit(
                SessionCallReconnected(sessionId: widget.sessionId),
              );
              setState(() {
                _phase = _remoteUid != null
                    ? _AgoraCallConnectionPhase.participantJoined
                    : _AgoraCallConnectionPhase.waitingForParticipant;
              });
              _reportConnectionPhase();
            }
          default:
            break;
        }
      },
      onNetworkQuality: (connection, uid, txQuality, rxQuality) {
        if (!mounted) return;
        // Map Agora quality to coarse bucket; the telemetry coordinator
        // throttles to one network event per 60s.
        final level = _mapNetworkQuality(txQuality, rxQuality);
        widget.eventHub?.emit(
          SessionCallNetworkQualityChanged(
            sessionId: widget.sessionId,
            level: level,
          ),
        );
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        if (!mounted) return;
        widget.eventHub?.emit(
          SessionCallParticipantConnected(
            sessionId: widget.sessionId,
            remoteParticipantId: remoteUid.toString(),
          ),
        );
        setState(() {
          _remoteUid = remoteUid;
          _channelId = connection.channelId;
          _remoteVideoReady = false;
          _phase = _AgoraCallConnectionPhase.participantJoined;
        });
        _reportConnectionPhase();
      },
      onUserOffline: (connection, remoteUid, reason) {
        if (!mounted || _remoteUid != remoteUid) return;
        widget.eventHub?.emit(
          SessionCallParticipantDisconnected(
            sessionId: widget.sessionId,
            remoteParticipantId: remoteUid.toString(),
            reason: _mapDisconnectReason(reason),
          ),
        );
        setState(() {
          _remoteUid = null;
          _remoteVideoReady = false;
          _phase = _AgoraCallConnectionPhase.waitingForParticipant;
        });
        _reportConnectionPhase();
      },
      onRemoteVideoStateChanged:
          (connection, remoteUid, state, reason, elapsed) {
            if (!mounted || _remoteUid != remoteUid) return;
            setState(() {
              _remoteVideoReady = _isRemoteVideoRenderable(state);
            });
          },
      onUserMuteVideo: (connection, remoteUid, muted) {
        if (!mounted || _remoteUid != remoteUid) return;
        if (muted) {
          setState(() {
            _remoteVideoReady = false;
          });
        }
      },
      onLocalVideoStateChanged: (source, state, reason) {
        if (!mounted) return;
        setState(() {
          _localVideoReady = _isLocalVideoRenderable(state);
        });
      },
    );
    engine.registerEventHandler(_eventHandler!);
    _reportConnectionPhase();
  }

  void _reportConnectionPhase() {
    final reporter = InAppCallConnectionReporter.maybeOf(context);
    if (reporter == null) {
      return;
    }
    reporter.onPhaseChanged(switch (_phase) {
      _AgoraCallConnectionPhase.connecting =>
        InAppCallConnectionPhase.connecting,
      _AgoraCallConnectionPhase.waitingForParticipant =>
        InAppCallConnectionPhase.waitingForParticipant,
      _AgoraCallConnectionPhase.participantJoined =>
        InAppCallConnectionPhase.participantJoined,
      _AgoraCallConnectionPhase.reconnecting =>
        InAppCallConnectionPhase.connecting,
    });
  }

  /// Maps Agora tx/rx quality to a coarse network quality bucket.
  /// The telemetry coordinator throttles these to one per 60s.
  SessionCallNetworkQualityLevel _mapNetworkQuality(
    QualityType tx,
    QualityType rx,
  ) {
    // QualityType: 0=excellent, 1=good, 2=poor, 3=bad, 4=very bad, 5=down
    final worst = tx.index > rx.index ? tx : rx;
    return switch (worst) {
      QualityType.qualityExcellent ||
      QualityType.qualityGood => SessionCallNetworkQualityLevel.good,
      QualityType.qualityPoor ||
      QualityType.qualityBad ||
      QualityType.qualityVbad ||
      QualityType.qualityDown => SessionCallNetworkQualityLevel.poor,
      _ => SessionCallNetworkQualityLevel.unknown,
    };
  }

  SessionCallParticipantDisconnectReason _mapDisconnectReason(
    UserOfflineReasonType reason,
  ) {
    return switch (reason) {
      UserOfflineReasonType.userOfflineQuit =>
        SessionCallParticipantDisconnectReason.quit,
      UserOfflineReasonType.userOfflineDropped =>
        SessionCallParticipantDisconnectReason.dropped,
      _ => SessionCallParticipantDisconnectReason.unknown,
    };
  }

  void _unbindEngineEvents([String? sessionId]) {
    final engine = widget.enginePool
        .sessionFor(sessionId ?? widget.sessionId)
        ?.engine;
    final handler = _eventHandler;
    if (engine != null && handler != null) {
      engine.unregisterEventHandler(handler);
    }
    _eventHandler = null;
  }

  @override
  Widget build(BuildContext context) {
    final engine = _engine;

    if (engine == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _reportConnectionPhase();
        }
      });
      return SizedBox.expand(
        child: _StatusPanel(
          icon: Icons.sync,
          message: widget.labels.connecting,
          showSpinner: true,
        ),
      );
    }

    return SizedBox.expand(
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: switch (widget.callType) {
          SessionCallType.videoCall => _VideoLayout(
            engine: engine,
            remoteUid: _remoteUid,
            channelId: _channelId,
            phase: _phase,
            remoteVideoReady: _remoteVideoReady,
            localVideoReady: _localVideoReady,
            labels: widget.labels,
          ),
          SessionCallType.voiceCall || SessionCallType.externalMeeting =>
            _VoiceLayout(phase: _phase, labels: widget.labels),
        },
      ),
    );
  }
}

class _VideoLayout extends StatefulWidget {
  const _VideoLayout({
    required this.engine,
    required this.remoteUid,
    required this.channelId,
    required this.phase,
    required this.remoteVideoReady,
    required this.localVideoReady,
    required this.labels,
  });

  final RtcEngine engine;
  final int? remoteUid;
  final String? channelId;
  final _AgoraCallConnectionPhase phase;
  final bool remoteVideoReady;
  final bool localVideoReady;
  final AgoraCallSurfaceLabels labels;

  @override
  State<_VideoLayout> createState() => _VideoLayoutState();
}

class _VideoLayoutState extends State<_VideoLayout> {
  /// Cached controllers — recreated ONLY when remoteUid or channelId
  /// actually changes, NOT on every parent rebuild. This prevents the
  /// expensive native video renderer (texture/surface) from being
  /// destroyed and recreated on phase/video-state changes.
  VideoViewController? _remoteController;
  VideoViewController? _localController;

  @override
  void didUpdateWidget(_VideoLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Invalidate remote controller only when the participant or channel
    // actually changes — not on every phase/video-ready toggle.
    if (oldWidget.remoteUid != widget.remoteUid ||
        oldWidget.channelId != widget.channelId) {
      _remoteController = null;
    }
    // Invalidate local controller only when the engine changes.
    if (oldWidget.engine != widget.engine) {
      _localController = null;
      _remoteController = null;
    }
  }

  @override
  void dispose() {
    _remoteController = null;
    _localController = null;
    super.dispose();
  }

  VideoViewController? get _effectiveRemoteController {
    if (_remoteController != null) return _remoteController;
    final uid = widget.remoteUid;
    final channelId = widget.channelId;
    if (uid == null || channelId == null || channelId.isEmpty) return null;
    _remoteController = VideoViewController.remote(
      rtcEngine: widget.engine,
      canvas: VideoCanvas(uid: uid),
      connection: RtcConnection(channelId: channelId),
    );
    return _remoteController;
  }

  VideoViewController get _effectiveLocalController {
    if (_localController != null) return _localController!;
    _localController = VideoViewController(
      rtcEngine: widget.engine,
      canvas: const VideoCanvas(uid: 0),
    );
    return _localController!;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final hasRemoteParticipant =
        widget.remoteUid != null &&
        widget.channelId != null &&
        widget.channelId!.isNotEmpty;
    final showRemoteVideo = hasRemoteParticipant && widget.remoteVideoReady;
    final showLocalFullscreen = widget.localVideoReady && !hasRemoteParticipant;
    final showLocalPiP = widget.localVideoReady && hasRemoteParticipant;
    final pipWidth = tokens.spaceXXL * 3.5;
    final pipHeight = tokens.spaceXXL * 4.625;

    final remoteParticipantName =
        InAppCallConnectionReporter.remoteParticipantDisplayNameOf(context);

    final (placeholderIcon, placeholderMessage) = switch (widget.phase) {
      _AgoraCallConnectionPhase.connecting => (
        Icons.sync,
        widget.labels.connecting,
      ),
      _AgoraCallConnectionPhase.reconnecting => (
        Icons.wifi_off,
        widget.labels.connecting,
      ),
      _AgoraCallConnectionPhase.waitingForParticipant => (
        Icons.hourglass_top_outlined,
        widget.labels.waitingForParticipant,
      ),
      _AgoraCallConnectionPhase.participantJoined
          when hasRemoteParticipant && !showRemoteVideo =>
        (
          Icons.person_outline,
          remoteParticipantName ?? widget.labels.connected,
        ),
      _ => (Icons.person_outline, widget.labels.connected),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        if (showRemoteVideo)
          AgoraVideoView(controller: _effectiveRemoteController!)
        else if (showLocalFullscreen)
          AgoraVideoView(controller: _effectiveLocalController)
        else
          AgoraCallVideoPlaceholder(
            icon: placeholderIcon,
            message: placeholderMessage,
            showSpinner:
                widget.phase == _AgoraCallConnectionPhase.connecting ||
                widget.phase == _AgoraCallConnectionPhase.reconnecting,
          ),
        if (showLocalPiP)
          PositionedDirectional(
            top: tokens.spaceMedium,
            end: tokens.spaceMedium,
            child: SizedBox(
              width: pipWidth,
              height: pipHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(tokens.radiusMedium),
                  border: Border.all(color: colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(
                        alpha: tokens.opacityShadowStrong,
                      ),
                      blurRadius: tokens.spaceSmall,
                      offset: Offset(0, tokens.spaceExtraSmall / 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(tokens.radiusMedium),
                  child: AgoraVideoView(controller: _effectiveLocalController),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Placeholder for video calls before Agora streams are renderable.
class AgoraCallVideoPlaceholder extends StatelessWidget {
  const AgoraCallVideoPlaceholder({
    super.key,
    required this.icon,
    required this.message,
    this.showSpinner = false,
  });

  final IconData icon;
  final String message;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;

    final avatarRadius = tokens.iconSizeLargePlus + tokens.spaceMedium;
    final avatarIconSize = tokens.iconSizeLargePlus;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner)
              const CircularProgressIndicator()
            else
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  size: avatarIconSize,
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
      ),
    );
  }
}

bool _isRemoteVideoRenderable(RemoteVideoState state) =>
    agoraRemoteVideoIsRenderable(state);

bool _isLocalVideoRenderable(LocalVideoStreamState state) =>
    agoraLocalVideoIsRenderable(state);

/// Whether remote Agora video is safe to bind to [AgoraVideoView].
bool agoraRemoteVideoIsRenderable(RemoteVideoState state) {
  return switch (state) {
    RemoteVideoState.remoteVideoStateStarting ||
    RemoteVideoState.remoteVideoStateDecoding ||
    RemoteVideoState.remoteVideoStateFrozen => true,
    RemoteVideoState.remoteVideoStateStopped ||
    RemoteVideoState.remoteVideoStateFailed => false,
  };
}

/// Whether local camera preview is safe to bind to [AgoraVideoView].
bool agoraLocalVideoIsRenderable(LocalVideoStreamState state) {
  return switch (state) {
    LocalVideoStreamState.localVideoStreamStateCapturing ||
    LocalVideoStreamState.localVideoStreamStateEncoding => true,
    LocalVideoStreamState.localVideoStreamStateStopped ||
    LocalVideoStreamState.localVideoStreamStateFailed => false,
  };
}

class _VoiceLayout extends StatelessWidget {
  const _VoiceLayout({required this.phase, required this.labels});

  final _AgoraCallConnectionPhase phase;
  final AgoraCallSurfaceLabels labels;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;

    final avatarRadius = tokens.iconSizeLargePlus + tokens.spaceMedium;
    final avatarIconSize = tokens.iconSizeLargePlus;

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline,
                  size: avatarIconSize,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              SizedBox(height: tokens.spaceLarge),
              Text(
                labels.voiceCallTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spaceSmall),
              Text(
                switch (phase) {
                  _AgoraCallConnectionPhase.connecting => labels.connecting,
                  _AgoraCallConnectionPhase.reconnecting => labels.connecting,
                  _AgoraCallConnectionPhase.waitingForParticipant =>
                    labels.waitingForParticipant,
                  _AgoraCallConnectionPhase.participantJoined =>
                    labels.connected,
                },
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        if (phase == _AgoraCallConnectionPhase.participantJoined)
          const _VoiceActivePulse(),
      ],
    );
  }
}

class _VoiceActivePulse extends StatefulWidget {
  const _VoiceActivePulse();

  @override
  State<_VoiceActivePulse> createState() => _VoiceActivePulseState();
}

class _VoiceActivePulseState extends State<_VoiceActivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _animationStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animationStarted) {
      return;
    }
    _animationStarted = true;
    _controller.duration = Theme.of(context).tokens.durationSlow * 2;
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: tokens.spaceLarge),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (index) {
                final barWidth = tokens.spaceSmall * 0.75;
                final baseHeight = tokens.spaceSmall + tokens.spaceExtraSmall;
                final height =
                    baseHeight +
                    (_controller.value *
                        tokens.spaceLarge *
                        1.25 *
                        ((index + 1) % 3 + 1));
                return Container(
                  width: barWidth,
                  height: height,
                  margin: EdgeInsets.symmetric(
                    horizontal: tokens.spaceSmall / 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(
                      alpha: 0.5 + (_controller.value * 0.5),
                    ),
                    borderRadius: BorderRadius.circular(tokens.radiusSmall),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.message,
    this.showSpinner = false,
  });

  final IconData icon;
  final String message;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            const CircularProgressIndicator()
          else
            Icon(
              icon,
              size: tokens.iconSizeExtraLarge + tokens.spaceExtraSmall,
              color: colorScheme.primary,
            ),
          SizedBox(height: tokens.spaceMedium),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Builds an Agora surface when [providerKind] is [SessionCallProviderKind.agora].
Widget? buildAgoraCallSurface({
  required String sessionId,
  required SessionCallType callType,
  required SessionCallProviderKind providerKind,
  required AgoraRtcEnginePool enginePool,
  required AgoraCallSurfaceLabels labels,
  SessionCallProviderEventHub? eventHub,
}) {
  if (providerKind != SessionCallProviderKind.agora) {
    return null;
  }

  return AgoraCallSurface(
    sessionId: sessionId,
    callType: callType,
    enginePool: enginePool,
    labels: labels,
    eventHub: eventHub,
  );
}
