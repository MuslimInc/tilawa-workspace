import 'package:flutter/material.dart' hide ConnectionState;
import 'package:livekit_client/livekit_client.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../boundaries/call/livekit_room_pool.dart';
import 'agora_call_surface.dart';
import 'agora_call_surface_labels.dart';

enum _LiveKitCallConnectionPhase {
  connecting,
  waitingForParticipant,
  participantJoined,
  reconnecting,
}

/// LiveKit voice/video in-call surface backed by an active [LiveKitRoomPool] session.
class LiveKitCallSurface extends StatefulWidget {
  const LiveKitCallSurface({
    super.key,
    required this.sessionId,
    required this.callType,
    required this.roomPool,
    required this.labels,
    this.eventHub,
  });

  final String sessionId;
  final SessionCallType callType;
  final LiveKitRoomPool roomPool;
  final AgoraCallSurfaceLabels labels;
  final SessionCallProviderEventHub? eventHub;

  @override
  State<LiveKitCallSurface> createState() => _LiveKitCallSurfaceState();
}

class _LiveKitCallSurfaceState extends State<LiveKitCallSurface> {
  _LiveKitCallConnectionPhase _phase = _LiveKitCallConnectionPhase.connecting;
  String? _remoteParticipantId;
  bool _remoteVideoReady = false;
  bool _localVideoReady = false;
  EventsListener<RoomEvent>? _listener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindRoomEvents());
  }

  @override
  void didUpdateWidget(covariant LiveKitCallSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      _unbindRoomEvents();
      _remoteParticipantId = null;
      _remoteVideoReady = false;
      _localVideoReady = false;
      _phase = _LiveKitCallConnectionPhase.connecting;
      _bindRoomEvents();
      _reportConnectionPhase();
    }
  }

  @override
  void dispose() {
    _unbindRoomEvents();
    super.dispose();
  }

  Room? get _room => widget.roomPool.sessionFor(widget.sessionId)?.room;

  void _bindRoomEvents() {
    final room = _room;
    if (room == null) {
      return;
    }

    room.addListener(_onRoomChanged);
    _listener = room.createListener()
      ..on<RoomDisconnectedEvent>((_) {
        if (!mounted) return;
        widget.eventHub?.emit(
          SessionCallParticipantDisconnected(
            sessionId: widget.sessionId,
            remoteParticipantId: _remoteParticipantId ?? '',
            reason: SessionCallParticipantDisconnectReason.dropped,
          ),
        );
      })
      ..on<ParticipantConnectedEvent>((event) {
        if (!mounted) {
          return;
        }
        final remote = event.participant;
        widget.eventHub?.emit(
          SessionCallParticipantConnected(
            sessionId: widget.sessionId,
            remoteParticipantId: remote.identity,
          ),
        );
        setState(() {
          _remoteParticipantId = remote.identity;
          _remoteVideoReady = _hasRenderableRemoteVideo(remote);
          _phase = _LiveKitCallConnectionPhase.participantJoined;
        });
        _reportConnectionPhase();
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        if (!mounted || event.participant.identity != _remoteParticipantId) {
          return;
        }
        widget.eventHub?.emit(
          SessionCallParticipantDisconnected(
            sessionId: widget.sessionId,
            remoteParticipantId: event.participant.identity,
            reason: SessionCallParticipantDisconnectReason.quit,
          ),
        );
        setState(() {
          _remoteParticipantId = null;
          _remoteVideoReady = false;
          _phase = _LiveKitCallConnectionPhase.waitingForParticipant;
        });
        _reportConnectionPhase();
      })
      ..on<RoomReconnectingEvent>((_) {
        if (!mounted) return;
        widget.eventHub?.emit(
          SessionCallReconnecting(sessionId: widget.sessionId),
        );
        setState(() {
          _phase = _LiveKitCallConnectionPhase.reconnecting;
        });
        _reportConnectionPhase();
      })
      ..on<RoomReconnectedEvent>((_) {
        if (!mounted) return;
        widget.eventHub?.emit(
          SessionCallReconnected(sessionId: widget.sessionId),
        );
        setState(() {
          _phase = _remoteParticipantId != null
              ? _LiveKitCallConnectionPhase.participantJoined
              : _LiveKitCallConnectionPhase.waitingForParticipant;
        });
        _reportConnectionPhase();
      });

    _syncRemoteParticipant(room);
    _reportConnectionPhase();
  }

  void _onRoomChanged() {
    if (!mounted) return;
    final room = _room;
    if (room == null) {
      return;
    }
    _syncRemoteParticipant(room);
    _localVideoReady = _hasRenderableLocalVideo(room);
  }

  void _syncRemoteParticipant(Room room) {
    final remote = room.remoteParticipants.values.firstOrNull;
    if (remote == null) {
      if (_remoteParticipantId != null) {
        setState(() {
          _remoteParticipantId = null;
          _remoteVideoReady = false;
          _phase = _LiveKitCallConnectionPhase.waitingForParticipant;
        });
      } else if (_phase == _LiveKitCallConnectionPhase.connecting &&
          room.connectionState == ConnectionState.connected) {
        setState(() {
          _phase = _LiveKitCallConnectionPhase.waitingForParticipant;
        });
      }
      return;
    }

    final videoReady = _hasRenderableRemoteVideo(remote);
    if (_remoteParticipantId != remote.identity ||
        _remoteVideoReady != videoReady) {
      setState(() {
        _remoteParticipantId = remote.identity;
        _remoteVideoReady = videoReady;
        _phase = _LiveKitCallConnectionPhase.participantJoined;
      });
    }
  }

  bool _hasRenderableRemoteVideo(RemoteParticipant participant) {
    for (final pub in participant.videoTrackPublications) {
      if (pub.isScreenShare || pub.muted || !pub.subscribed) {
        continue;
      }
      if (pub.track is VideoTrack) {
        return true;
      }
    }
    return false;
  }

  bool _hasRenderableLocalVideo(Room room) {
    final participant = room.localParticipant;
    if (participant == null) {
      return false;
    }
    for (final pub in participant.videoTrackPublications) {
      if (pub.isScreenShare || pub.muted) {
        continue;
      }
      if (pub.track is LocalVideoTrack) {
        return true;
      }
    }
    return false;
  }

  VideoTrack? _remoteVideoTrack(Room room) {
    final remoteId = _remoteParticipantId;
    if (remoteId == null) {
      return null;
    }
    final remote = room.remoteParticipants[remoteId];
    if (remote == null) {
      return null;
    }
    for (final pub in remote.videoTrackPublications) {
      if (pub.isScreenShare || pub.muted || !pub.subscribed) {
        continue;
      }
      final track = pub.track;
      if (track is VideoTrack) {
        return track;
      }
    }
    return null;
  }

  LocalVideoTrack? _localVideoTrack(Room room) {
    final participant = room.localParticipant;
    if (participant == null) {
      return null;
    }
    for (final pub in participant.videoTrackPublications) {
      if (pub.isScreenShare || pub.muted) {
        continue;
      }
      final track = pub.track;
      if (track is LocalVideoTrack) {
        return track;
      }
    }
    return null;
  }

  void _unbindRoomEvents() {
    final room = _room;
    room?.removeListener(_onRoomChanged);
    _listener?.dispose();
    _listener = null;
  }

  void _reportConnectionPhase() {
    final reporter = InAppCallConnectionReporter.maybeOf(context);
    if (reporter == null) {
      return;
    }
    reporter.onPhaseChanged(switch (_phase) {
      _LiveKitCallConnectionPhase.connecting =>
        InAppCallConnectionPhase.connecting,
      _LiveKitCallConnectionPhase.waitingForParticipant =>
        InAppCallConnectionPhase.waitingForParticipant,
      _LiveKitCallConnectionPhase.participantJoined =>
        InAppCallConnectionPhase.participantJoined,
      _LiveKitCallConnectionPhase.reconnecting =>
        InAppCallConnectionPhase.connecting,
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;

    if (room == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _reportConnectionPhase();
        }
      });
      return SizedBox.expand(
        child: _LiveKitStatusPanel(
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
          SessionCallType.videoCall => _LiveKitVideoLayout(
            room: room,
            phase: _phase,
            remoteVideoReady: _remoteVideoReady,
            localVideoReady: _localVideoReady,
            remoteVideoTrack: _remoteVideoTrack(room),
            localVideoTrack: _localVideoTrack(room),
            labels: widget.labels,
          ),
          SessionCallType.voiceCall || SessionCallType.externalMeeting =>
            _LiveKitVoiceLayout(phase: _phase, labels: widget.labels),
        },
      ),
    );
  }
}

class _LiveKitVideoLayout extends StatelessWidget {
  const _LiveKitVideoLayout({
    required this.room,
    required this.phase,
    required this.remoteVideoReady,
    required this.localVideoReady,
    required this.remoteVideoTrack,
    required this.localVideoTrack,
    required this.labels,
  });

  final Room room;
  final _LiveKitCallConnectionPhase phase;
  final bool remoteVideoReady;
  final bool localVideoReady;
  final VideoTrack? remoteVideoTrack;
  final LocalVideoTrack? localVideoTrack;
  final AgoraCallSurfaceLabels labels;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final colorScheme = Theme.of(context).colorScheme;
    final showRemoteVideo = remoteVideoReady && remoteVideoTrack != null;
    final showLocalFullscreen = localVideoReady && !showRemoteVideo;
    final showLocalPiP = localVideoReady && showRemoteVideo;
    final pipWidth = tokens.spaceXXL * 3.5;
    final pipHeight = tokens.spaceXXL * 4.625;

    final (placeholderIcon, placeholderMessage) = switch (phase) {
      _LiveKitCallConnectionPhase.connecting => (Icons.sync, labels.connecting),
      _LiveKitCallConnectionPhase.reconnecting => (
        Icons.wifi_off,
        labels.connecting,
      ),
      _LiveKitCallConnectionPhase.waitingForParticipant => (
        Icons.hourglass_top_outlined,
        labels.waitingForParticipant,
      ),
      _LiveKitCallConnectionPhase.participantJoined when !showRemoteVideo => (
        Icons.videocam_outlined,
        labels.connected,
      ),
      _ => (Icons.person_outline, labels.connected),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        if (showRemoteVideo)
          VideoTrackRenderer(remoteVideoTrack!)
        else if (showLocalFullscreen && localVideoTrack != null)
          VideoTrackRenderer(localVideoTrack!)
        else
          AgoraCallVideoPlaceholder(
            icon: placeholderIcon,
            message: placeholderMessage,
            showSpinner:
                phase == _LiveKitCallConnectionPhase.connecting ||
                phase == _LiveKitCallConnectionPhase.reconnecting,
          ),
        if (showLocalPiP && localVideoTrack != null)
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
                  child: VideoTrackRenderer(localVideoTrack!),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LiveKitVoiceLayout extends StatelessWidget {
  const _LiveKitVoiceLayout({required this.phase, required this.labels});

  final _LiveKitCallConnectionPhase phase;
  final AgoraCallSurfaceLabels labels;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).tokens;
    final avatarRadius = tokens.iconSizeLargePlus + tokens.spaceMedium;
    final avatarIconSize = tokens.iconSizeLargePlus;

    return Center(
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
              _LiveKitCallConnectionPhase.connecting => labels.connecting,
              _LiveKitCallConnectionPhase.reconnecting => labels.connecting,
              _LiveKitCallConnectionPhase.waitingForParticipant =>
                labels.waitingForParticipant,
              _LiveKitCallConnectionPhase.participantJoined => labels.connected,
            },
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LiveKitStatusPanel extends StatelessWidget {
  const _LiveKitStatusPanel({
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

/// Builds a LiveKit surface when [providerKind] is [SessionCallProviderKind.livekit].
Widget? buildLiveKitCallSurface({
  required String sessionId,
  required SessionCallType callType,
  required SessionCallProviderKind providerKind,
  required LiveKitRoomPool roomPool,
  required AgoraCallSurfaceLabels labels,
  SessionCallProviderEventHub? eventHub,
}) {
  if (providerKind != SessionCallProviderKind.livekit) {
    return null;
  }

  return LiveKitCallSurface(
    sessionId: sessionId,
    callType: callType,
    roomPool: roomPool,
    labels: labels,
    eventHub: eventHub,
  );
}
