import 'package:quran_sessions/quran_sessions.dart';

import '../../helpers/fakes/fake_audit_repository.dart';
import '../../helpers/fakes/fake_session_aggregate_repository.dart';

class RecordingSessionDetailBloc extends SessionDetailBloc {
  RecordingSessionDetailBloc({
    required SessionDetailSuccess seed,
    this._onRecord,
  }) : super(
         getSessionAggregate: GetSessionAggregateUseCase(
           FakeSessionAggregateRepository(),
         ),
         getTimeline: GetSessionTimelineUseCase(FakeAuditRepository()),
       ) {
    emit(seed);
  }

  final void Function(SessionDetailEvent event)? _onRecord;

  @override
  void add(SessionDetailEvent event) {
    _onRecord?.call(event);
  }
}
