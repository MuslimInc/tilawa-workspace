import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_audit_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';

class TutorCancelEmitSuccessBloc extends SessionDetailBloc {
  TutorCancelEmitSuccessBloc({
    required SessionDetailSuccess seed,
  }) : super(
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
    if (event is SessionDetailCancelSubmitted) {
      final current = state;
      if (current is! SessionDetailSuccess) return;
      emit(
        current.copyWith(
          aggregate: current.aggregate.copyWith(
            lifecycleStatus: SessionLifecycleStatus.cancelledByTeacher,
          ),
          cancellationSucceeded: true,
          clearCancellationInProgress: true,
        ),
      );
      return;
    }
    if (event is SessionDetailCancelAcknowledged) {
      final current = state;
      if (current is! SessionDetailSuccess) return;
      emit(current.copyWith(clearCancellationSucceeded: true));
      return;
    }
    super.add(event);
  }
}
