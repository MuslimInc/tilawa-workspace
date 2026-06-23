import 'package:dartz_plus/dartz_plus.dart';

import '../entities/session_report_category.dart';
import '../failures/quran_sessions_failure.dart';
import '../gateways/session_mutation_gateway.dart';

class ReportSessionConcernUseCase {
  const ReportSessionConcernUseCase({required this._gateway});

  final SessionMutationGateway _gateway;

  static const int minDescriptionLength = 20;

  Future<Either<QuranSessionsFailure, String>> call({
    required SessionReportCategory category,
    required String description,
    String? bookingId,
  }) async {
    final trimmed = description.trim();
    if (trimmed.length < minDescriptionLength) {
      return const Left(
        ValidationFailure(field: 'description', code: 'too_short'),
      );
    }

    final result = await _gateway.reportSessionConcern(
      category: category,
      description: trimmed,
      bookingId: bookingId,
    );
    return result.map((value) => value.reportId);
  }
}
