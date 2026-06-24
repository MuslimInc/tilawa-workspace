import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/auth/domain/services/callable_session_payload_builder.dart';

import 'firebase_callable_failure_mapper.dart';

class FirebaseGuardianApprovalRepository implements GuardianApprovalRepository {
  FirebaseGuardianApprovalRepository(
    this._functions,
    this._sessionPayloadBuilder,
  );

  final FirebaseFunctions _functions;
  final CallableSessionPayloadBuilder _sessionPayloadBuilder;

  @override
  Future<Either<QuranSessionsFailure, void>> approveChildBooking({
    required String studentId,
  }) async {
    try {
      final callable = _functions.httpsCallable('approveChildGuardianBooking');
      await callable.call<Map<String, dynamic>>(
        await _sessionPayloadBuilder.withSessionEpoch({
          'studentId': studentId,
        }),
      );
      return const Right(null);
    } on FirebaseFunctionsException catch (error) {
      return Left(mapQuranSessionsCallableFailure(error));
    } on Object {
      return const Left(NetworkFailure());
    }
  }
}
