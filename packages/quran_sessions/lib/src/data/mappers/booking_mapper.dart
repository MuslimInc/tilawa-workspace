import '../../domain/entities/quran_booking.dart';
import '../../domain/entities/session_call_type.dart';
import '../../domain/entities/session_pricing_type.dart';
import '../dtos/quran_booking_dto.dart';

extension QuranBookingDtoMapper on QuranBookingDto {
  QuranBooking toDomain() => QuranBooking(
    id: id,
    teacherId: teacherId,
    studentId: studentId,
    slotId: slotId,
    requestedCallType: _mapCallType(requestedCallType),
    pricingType: _mapPricingType(pricingType),
    status: _mapStatus(status),
    createdAt: DateTime.parse(createdAt),
    amountPaidUsd: amountPaidUsd,
    paymentReference: paymentReference,
    sessionId: sessionId,
    studentNote: studentNote,
  );
}

SessionCallType _mapCallType(String raw) => switch (raw) {
  'external_meeting' => SessionCallType.externalMeeting,
  'voice_call' => SessionCallType.voiceCall,
  'video_call' => SessionCallType.videoCall,
  _ => SessionCallType.externalMeeting,
};

SessionPricingType _mapPricingType(String raw) => switch (raw) {
  'free' => SessionPricingType.free,
  'fixed_per_session' => SessionPricingType.fixedPerSession,
  'subscription' => SessionPricingType.subscription,
  _ => SessionPricingType.free,
};

BookingStatus _mapStatus(String raw) => switch (raw) {
  'pending' => BookingStatus.pending,
  'confirmed' => BookingStatus.confirmed,
  'rejected' => BookingStatus.rejected,
  'cancelled' => BookingStatus.cancelled,
  'completed' => BookingStatus.completed,
  'refunded' => BookingStatus.refunded,
  _ => BookingStatus.pending,
};
