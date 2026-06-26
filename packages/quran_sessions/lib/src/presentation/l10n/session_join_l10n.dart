import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';

import '../session_join/session_join_ui_state.dart';

extension SessionJoinUiStateL10n on SessionJoinUiState {
  String localizedMessage(QuranSessionsLocalizations l10n) => switch (this) {
    SessionJoinUiState.notStarted => l10n.sessionJoinStateNotStarted,
    SessionJoinUiState.joinAvailable => l10n.sessionJoinStateJoinAvailable,
    SessionJoinUiState.joining => l10n.sessionJoinStateJoining,
    SessionJoinUiState.joined => l10n.sessionJoinStateJoined,
    SessionJoinUiState.failed => l10n.sessionJoinStateFailed,
    SessionJoinUiState.ended => l10n.sessionJoinStateEnded,
    SessionJoinUiState.cancelled => l10n.sessionJoinStateCancelled,
    SessionJoinUiState.awaitingTutorApproval => l10n.bookingRequestSentSubtitle,
    SessionJoinUiState.rejectedByTutor => l10n.bookingRejectedSubtitle,
  };
}
