import 'package:dartz_plus/dartz_plus.dart';

import '../failures/quran_sessions_failure.dart';

enum SessionNotificationKind {
  bookingConfirmed,
  cancellation,
  rescheduleRequested,
  rescheduleConfirmed,
  noShowMarked,
  compensationIssued,
  reminder,
}

class SessionNotificationCommand {
  const SessionNotificationCommand({
    required this.sessionId,
    required this.kind,
    required this.recipientUserIds,
    this.payload = const {},
  });

  final String sessionId;
  final SessionNotificationKind kind;
  final List<String> recipientUserIds;
  final Map<String, Object?> payload;
}

abstract interface class SessionNotificationGateway {
  Future<Either<QuranSessionsFailure, void>> enqueue(
    SessionNotificationCommand command,
  );
}
