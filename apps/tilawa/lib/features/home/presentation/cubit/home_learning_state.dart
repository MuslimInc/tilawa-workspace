import 'package:equatable/equatable.dart';
import 'package:quran_sessions/quran_sessions.dart';

/// The active slot types for the home learning priority card.
enum HomeLearningStatus {
  initial,
  loading,
  nextSession, // Ongoing or imminent session within imminentSessionThreshold (2h)
  continueLearning, // Revision pending from latest completed session within revisionAgeOutThreshold (7d)
  pendingBooking, // Session awaiting tutor approval or pending payment
  none, // No active learning state; falls back to Featured Tutor card
}

class HomeLearningState extends Equatable {
  const HomeLearningState({
    required this.status,
    this.session,
    this.revisionAggregate,
    this.isInterestSignalNeeded = false,
  });

  const HomeLearningState.initial() : this(status: HomeLearningStatus.initial);

  const HomeLearningState.loading() : this(status: HomeLearningStatus.loading);

  final HomeLearningStatus status;
  final QuranSession? session;
  final SessionAggregate? revisionAggregate;
  final bool isInterestSignalNeeded;

  HomeLearningState copyWith({
    HomeLearningStatus? status,
    QuranSession? session,
    SessionAggregate? revisionAggregate,
    bool? isInterestSignalNeeded,
  }) {
    return HomeLearningState(
      status: status ?? this.status,
      session: session ?? this.session,
      revisionAggregate: revisionAggregate ?? this.revisionAggregate,
      isInterestSignalNeeded:
          isInterestSignalNeeded ?? this.isInterestSignalNeeded,
    );
  }

  @override
  List<Object?> get props => [
    status,
    session,
    revisionAggregate,
    isInterestSignalNeeded,
  ];
}
