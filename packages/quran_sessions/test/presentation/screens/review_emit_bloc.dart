import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_audit_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';

class ReviewEmitBloc extends SessionDetailBloc {
  ReviewEmitBloc({required SessionDetailSuccess seed})
    : super(
        getSessionAggregate: GetSessionAggregateUseCase(
          FakeSessionAggregateRepository(),
        ),
        getTimeline: GetSessionTimelineUseCase(FakeAuditRepository()),
      ) {
    emit(seed);
  }

  @override
  void add(SessionDetailEvent event) {}
}

/// Sets reviewSubmitted on [bloc] for widget tests (avoids public bloc methods).
void emitSessionDetailReviewSubmitted(SessionDetailBloc bloc) {
  final current = bloc.state;
  if (current is! SessionDetailSuccess) return;
  bloc.emit(current.copyWith(reviewSubmitted: true));
}
