import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/entities/quran_booking.dart';
import '../../domain/entities/session_review.dart';
import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_data_source.dart';
import '../mappers/booking_mapper.dart';
import '../mappers/review_mapper.dart';
import 'repository_error_mapper.dart';

class BookingRepositoryImpl implements BookingRepository {
  const BookingRepositoryImpl(this._remote);

  final BookingRemoteDataSource _remote;

  @override
  Future<Either<QuranSessionsFailure, QuranBooking>> createBooking({
    required String teacherId,
    required String slotId,
    required String requestedCallTypeId,
    String? paymentReference,
    String? studentNote,
  }) async {
    try {
      final dto = await _remote.createBooking(
        teacherId: teacherId,
        slotId: slotId,
        requestedCallTypeId: requestedCallTypeId,
        paymentReference: paymentReference,
        studentNote: studentNote,
      );
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, QuranBooking>> cancelBooking(
    String bookingId, {
    required String reason,
  }) async {
    try {
      final dto = await _remote.cancelBooking(bookingId, reason: reason);
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, QuranBooking>> rescheduleBooking(
    String bookingId, {
    required String newSlotId,
  }) async {
    try {
      final dto = await _remote.rescheduleBooking(
        bookingId,
        newSlotId: newSlotId,
      );
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, List<QuranBooking>>> getStudentBookings(
    String studentId,
  ) async {
    try {
      final dtos = await _remote.getStudentBookings(studentId);
      return Right(dtos.map((d) => d.toDomain()).toList());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }

  @override
  Future<Either<QuranSessionsFailure, SessionReview>> submitReview({
    required String sessionId,
    required int rating,
    String? comment,
  }) async {
    try {
      final dto = await _remote.submitReview(
        sessionId: sessionId,
        rating: rating,
        comment: comment,
      );
      return Right(dto.toDomain());
    } on Exception catch (e) {
      return Left(mapRemoteException(e));
    }
  }
}
