import 'package:dartz_plus/dartz_plus.dart';

import '../entities/compensation_record.dart';
import '../failures/quran_sessions_failure.dart';

abstract interface class CompensationGateway {
  Future<Either<QuranSessionsFailure, CompensationRecord>> execute({
    required String sessionId,
    required List<CompensationAction> actions,
    required String policyRuleId,
  });
}
