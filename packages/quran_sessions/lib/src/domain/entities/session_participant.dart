import 'package:equatable/equatable.dart';

import 'session_participant_role.dart';

/// A user attached to an individual or (future) group session.
class SessionParticipant extends Equatable {
  const SessionParticipant({
    required this.userId,
    required this.role,
  });

  final String userId;
  final SessionParticipantRole role;

  @override
  List<Object?> get props => [userId, role];
}
