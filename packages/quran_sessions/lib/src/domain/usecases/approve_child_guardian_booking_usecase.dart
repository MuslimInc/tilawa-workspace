import 'package:dartz_plus/dartz_plus.dart';

import '../failures/quran_sessions_failure.dart';
import '../repositories/guardian_approval_repository.dart';

/// Records guardian approval so a child student can book sessions.
class ApproveChildGuardianBookingUseCase {
  const ApproveChildGuardianBookingUseCase(this._repository);

  final GuardianApprovalRepository _repository;

  Future<Either<QuranSessionsFailure, void>> call({
    required String studentId,
  }) => _repository.approveChildBooking(studentId: studentId);
}
