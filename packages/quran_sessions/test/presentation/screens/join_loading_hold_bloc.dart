import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_audit_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';

/// Holds [joinInProgress] after join tap so footer loading state can be asserted.
class JoinLoadingHoldBloc extends SessionDetailBloc {
  JoinLoadingHoldBloc({required SessionDetailSuccess seed})
    : super(
        getSessionAggregate: GetSessionAggregateUseCase(
          FakeSessionAggregateRepository(),
        ),
        getTimeline: GetSessionTimelineUseCase(FakeAuditRepository()),
      ) {
    emit(seed);
  }

  @override
  void add(SessionDetailEvent event) {
    if (event is SessionDetailLoadRequested) {
      return;
    }
    if (event is SessionDetailJoinRequested) {
      final current = state;
      if (current is! SessionDetailSuccess) {
        return;
      }
      emit(current.copyWith(joinInProgress: true));
      return;
    }
    super.add(event);
  }
}
