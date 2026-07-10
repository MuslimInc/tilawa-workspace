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
    this.isBrowseEntryVisible = false,
  });

  const HomeLearningState.initial() : this(status: HomeLearningStatus.initial);

  const HomeLearningState.loading() : this(status: HomeLearningStatus.loading);

  final HomeLearningStatus status;
  final QuranSession? session;
  final SessionAggregate? revisionAggregate;
  final bool isInterestSignalNeeded;

  /// Whether the persistent Learn Quran browse entry is shown in the [none]
  /// fallback — true once the user answered the interest prompt with yes, so
  /// saying yes never removes the Learn Quran section from Home.
  final bool isBrowseEntryVisible;

  HomeLearningState copyWith({
    HomeLearningStatus? status,
    QuranSession? session,
    SessionAggregate? revisionAggregate,
    bool? isInterestSignalNeeded,
    bool? isBrowseEntryVisible,
  }) {
    return HomeLearningState(
      status: status ?? this.status,
      session: session ?? this.session,
      revisionAggregate: revisionAggregate ?? this.revisionAggregate,
      isInterestSignalNeeded:
          isInterestSignalNeeded ?? this.isInterestSignalNeeded,
      isBrowseEntryVisible: isBrowseEntryVisible ?? this.isBrowseEntryVisible,
    );
  }

  @override
  List<Object?> get props => [
    status,
    session,
    revisionAggregate,
    isInterestSignalNeeded,
    isBrowseEntryVisible,
  ];
}
