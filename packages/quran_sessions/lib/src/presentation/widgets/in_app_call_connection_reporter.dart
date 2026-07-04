import 'package:flutter/material.dart';

/// Connection phase reported by in-app media surfaces (e.g. Agora).
enum InAppCallConnectionPhase {
  connecting,
  waitingForParticipant,
  participantJoined,
}

/// Optional hook for media surfaces to report connection phase to [InAppCallShellScreen].
class InAppCallConnectionReporter extends InheritedWidget {
  const InAppCallConnectionReporter({
    super.key,
    required this.onPhaseChanged,
    this.remoteParticipantDisplayName,
    required super.child,
  });

  final ValueChanged<InAppCallConnectionPhase> onPhaseChanged;

  /// Remote party name for camera-off placeholders in media surfaces.
  final String? remoteParticipantDisplayName;

  static InAppCallConnectionReporter? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<InAppCallConnectionReporter>();
  }

  static String? remoteParticipantDisplayNameOf(BuildContext context) {
    return maybeOf(context)?.remoteParticipantDisplayName;
  }

  @override
  bool updateShouldNotify(InAppCallConnectionReporter oldWidget) {
    return remoteParticipantDisplayName !=
        oldWidget.remoteParticipantDisplayName;
  }
}
