import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

class FakeCompensationGateway implements CompensationGateway {
  QuranSessionsFailure? failWith;
  final List<CompensationRecord> records = [];

  @override
  Future<Either<QuranSessionsFailure, CompensationRecord>> execute({
    required String sessionId,
    required List<CompensationAction> actions,
    required String policyRuleId,
  }) async {
    if (failWith != null) return Left(failWith!);
    final record = CompensationRecord(
      sessionId: sessionId,
      actions: actions,
      policyRuleId: policyRuleId,
      createdAt: DateTime.utc(2026, 1, 1),
    );
    records.add(record);
    return Right(record);
  }
}
