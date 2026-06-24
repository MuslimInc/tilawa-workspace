import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../boundaries/call/agora_rtc_engine_pool.dart';
import 'agora_call_surface_labels.dart';

enum _AgoraCallConnectionPhase {
  connecting,
  waitingForParticipant,
  participantJoined,
}

/// Agora voice/video in-call surface backed by an active [AgoraRtcEnginePool] session.
class AgoraCallSurface extends StatefulWidget {
  const AgoraCallSurface({
    super.key,
    required this.sessionId,
    required this.callType,
    required this.enginePool,
    required this.labels,
  });

  final String sessionId;
  final SessionCallType callType;
  final AgoraRtcEnginePool enginePool;
  final AgoraCallSurfaceLabels labels;

  @override
  State<AgoraCallSurface> createState() => _AgoraCallSurfaceState();
}

class _AgoraCallSurfaceState extends State<AgoraCallSurface> {
  _AgoraCallConnectionPhase _phase = _AgoraCallConnectionPhase.connecting;
  int? _remoteUid;
  String? _channelId;
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
      _unbindEngineEvents();
      _remoteUid = null;
      _channelId = null;
      _phase = _AgoraCallConnectionPhase.connecting;
      _bindEngineEvents();
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
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        if (!mounted) return;
        setState(() {
          _remoteUid = remoteUid;
          _channelId = connection.channelId;
          _phase = _AgoraCallConnectionPhase.participantJoined;
        });
      },
      onUserOffline: (connection, remoteUid, reason) {
        if (!mounted || _remoteUid != remoteUid) return;
        setState(() {
          _remoteUid = null;
          _phase = _AgoraCallConnectionPhase.waitingForParticipant;
        });
      },
    );
    engine.registerEventHandler(_eventHandler!);
  }

  void _unbindEngineEvents() {
    final engine = _engine;
    final handler = _eventHandler;
    if (engine != null && handler != null) {
      engine.unregisterEventHandler(handler);
    }
    _eventHandler = null;
  }

  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;

    if (engine == null) {
      return _StatusPanel(
        icon: Icons.sync,
        message: widget.labels.connecting,
        showSpinner: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConnectionChip(phase: _phase, labels: widget.labels),
        SizedBox(height: tokens.spaceSmall),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            child: ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: switch (widget.callType) {
                SessionCallType.videoCall => _VideoLayout(
                  engine: engine,
                  remoteUid: _remoteUid,
                  channelId: _channelId,
                  phase: _phase,
                  labels: widget.labels,
                ),
                SessionCallType.voiceCall || SessionCallType.externalMeeting =>
                  _VoiceLayout(phase: _phase, labels: widget.labels),
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  const _ConnectionChip({required this.phase, required this.labels});

  final _AgoraCallConnectionPhase phase;
  final AgoraCallSurfaceLabels labels;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;

    final (icon, message) = switch (phase) {
      _AgoraCallConnectionPhase.connecting => (Icons.sync, labels.connecting),
      _AgoraCallConnectionPhase.waitingForParticipant => (
        Icons.hourglass_top_outlined,
        labels.waitingForParticipant,
      ),
      _AgoraCallConnectionPhase.participantJoined => (
        Icons.check_circle_outline,
        labels.connected,
      ),
    };

    return Semantics(
      label: message,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMedium,
          vertical: tokens.spaceSmall,
        ),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colorScheme.onSecondaryContainer),
            SizedBox(width: tokens.spaceSmall),
            Flexible(
              child: Text(
                message,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoLayout extends StatelessWidget {
  const _VideoLayout({
    required this.engine,
    required this.remoteUid,
    required this.channelId,
    required this.phase,
    required this.labels,
  });

  final RtcEngine engine;
  final int? remoteUid;
  final String? channelId;
  final _AgoraCallConnectionPhase phase;
  final AgoraCallSurfaceLabels labels;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final hasRemote =
        remoteUid != null && channelId != null && channelId!.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasRemote)
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: engine,
              canvas: VideoCanvas(uid: remoteUid),
              connection: RtcConnection(channelId: channelId),
            ),
          )
        else
          AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: engine,
              canvas: const VideoCanvas(uid: 0),
            ),
          ),
        if (!hasRemote && phase != _AgoraCallConnectionPhase.connecting)
          _StatusOverlay(message: labels.waitingForParticipant),
        if (hasRemote)
          PositionedDirectional(
            top: tokens.spaceMedium,
            end: tokens.spaceMedium,
            child: SizedBox(
              width: 112,
              height: 148,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(tokens.radiusMedium),
                  border: Border.all(color: colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(tokens.radiusMedium),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VoiceLayout extends StatelessWidget {
  const _VoiceLayout({required this.phase, required this.labels});

  final _AgoraCallConnectionPhase phase;
  final AgoraCallSurfaceLabels labels;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 56,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline,
                  size: 56,
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
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
                final height =
                    12 + (_controller.value * 20 * ((index + 1) % 3 + 1));
                return Container(
                  width: 6,
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
            Icon(icon, size: 48, color: colorScheme.primary),
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

class _StatusOverlay extends StatelessWidget {
  const _StatusOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;

    return ColoredBox(
      color: colorScheme.scrim.withValues(alpha: 0.45),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLarge),
          child: Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onInverseSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ),
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
}) {
  if (providerKind != SessionCallProviderKind.agora) {
    return null;
  }

  return AgoraCallSurface(
    sessionId: sessionId,
    callType: callType,
    enginePool: enginePool,
    labels: labels,
  );
}
