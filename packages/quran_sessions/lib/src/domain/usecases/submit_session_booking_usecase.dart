import 'package:dartz_plus/dartz_plus.dart';

import '../entities/generated_slot.dart';
import '../entities/session_booking_outcome.dart';
import '../entities/session_call_type.dart';
import '../entities/session_pricing_type.dart';
import '../failures/quran_sessions_failure.dart';
import '../gateways/session_mutation_gateway.dart';
import '../policies/booking_idempotency.dart';
import '../policies/platform_scheduling_policy.dart';
import '../policies/session_mode_policy.dart';
import '../providers/auth_session_provider.dart';
import '../repositories/teacher_profile_repository.dart';
import 'get_teacher_availability_usecase.dart';

/// Creates a session booking via server orchestration after slot validation.
class SubmitSessionBookingUseCase {
  const SubmitSessionBookingUseCase({
    required this._mutationGateway,
    required this._getAvailability,
    required this._authSession,
    required this._teacherProfiles,
    this.defaultSlotDurationMinutes =
        PlatformSchedulingPolicy.defaultSlotDurationMinutes,
    this.sessionModePolicy = SessionModePolicy.freeBeta,
  });

  final SessionMutationGateway _mutationGateway;
  final GetTeacherAvailabilityUseCase _getAvailability;
  final AuthSessionProvider _authSession;
  final TeacherProfileRepository _teacherProfiles;
  final int defaultSlotDurationMinutes;
  final SessionModePolicy sessionModePolicy;

  Future<Either<QuranSessionsFailure, SessionBookingOutcome>> call({
    required String teacherId,
    required String slotId,
    required SessionCallType callType,
    String? paymentReference,
    String? studentNote,
    String? idempotencyKey,
  }) async {
    final studentId = _authSession.currentUserId;
    if (studentId == null || studentId.isEmpty) {
      return const Left(UnauthorizedFailure());
    }

    if (!sessionModePolicy.isEnabled(callType)) {
      return Left(
        UnsupportedSessionModeFailure(callType: callType.name),
      );
    }

    if (callType == SessionCallType.externalMeeting) {
      final profileResult = await _teacherProfiles.getProfileById(teacherId);
      if (profileResult.isLeft()) {
        return profileResult.map((_) => throw StateError('unreachable'));
      }
      final externalMeetingUrl = profileResult.fold(
        (_) => throw StateError('unreachable'),
        (profile) => profile.externalMeetingUrl,
      );
      if (!SessionModePolicy.hasExternalMeetingUrl(externalMeetingUrl)) {
        return const Left(MeetingLinkUnavailableFailure());
      }
    }

    final slotStart = GeneratedSlot.parseStartUtc(
      teacherId: teacherId,
      slotId: slotId,
    );
    if (slotStart == null) {
      return Left(SlotUnavailableFailure(slotId));
    }

    final availabilityResult = await _getAvailability(
      teacherId,
      from: slotStart.subtract(const Duration(hours: 1)),
      to: slotStart.add(const Duration(hours: 2)),
    );
    if (availabilityResult.isLeft()) {
      return availabilityResult.map((_) => throw StateError('unreachable'));
    }
    final slots = availabilityResult.fold(
      (_) => throw StateError('unreachable'),
      (value) => value,
    );
    final stillAvailable = slots.any(
      (slot) => slot.slotId == slotId && !slot.isBooked,
    );
    if (!stillAvailable) {
      return Left(SlotUnavailableFailure(slotId));
    }

    final startsAt = slotStart.toUtc();
    final endsAt = startsAt.add(Duration(minutes: defaultSlotDurationMinutes));
    final pricingType = paymentReference == null
        ? SessionPricingType.free
        : SessionPricingType.fixedPerSession;

    final created = await _mutationGateway.createBooking(
      teacherId: teacherId,
      studentId: studentId,
      slotId: slotId,
      startsAt: startsAt,
      endsAt: endsAt,
      callType: callType,
      pricingType: pricingType,
      paymentReference: paymentReference,
      studentNote: studentNote,
      idempotencyKey: idempotencyKey ?? BookingIdempotency.generateClientKey(),
    );
    return created.map(
      (outcome) => SessionBookingOutcome(
        aggregate: outcome.aggregate,
        clientConfirmToken: outcome.clientConfirmToken,
        paymentReference: outcome.paymentReference,
      ),
    );
  }
}
