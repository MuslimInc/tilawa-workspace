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
    required super.child,
  });

  final ValueChanged<InAppCallConnectionPhase> onPhaseChanged;

  static InAppCallConnectionReporter? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<InAppCallConnectionReporter>();
  }

  @override
  bool updateShouldNotify(InAppCallConnectionReporter oldWidget) => false;
}
