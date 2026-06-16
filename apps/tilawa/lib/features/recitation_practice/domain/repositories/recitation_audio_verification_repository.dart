import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../entities/recitation_comparison_result.dart';
import '../entities/recitation_target.dart';

/// Records recitation audio and verifies it against the expected ayah.
abstract class RecitationAudioVerificationRepository {
  Future<Either<Failure, void>> startRecording(RecitationTarget target);

  Future<Either<Failure, RecitationComparisonResult>> stopAndVerify(
    RecitationTarget target,
  );

  Future<void> cancel();

  Future<void> dispose();
}
