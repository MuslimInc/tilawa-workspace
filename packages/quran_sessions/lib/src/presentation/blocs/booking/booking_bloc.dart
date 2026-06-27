import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../boundaries/payment/session_payment_confirmation.dart';
import '../../../domain/entities/manual_payment_price.dart';
import '../../../domain/entities/session_lifecycle_status.dart';
import '../../../domain/entities/session_price.dart';
import '../../../domain/entities/session_pricing_type.dart';
import '../../../domain/entities/teacher_availability.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../../domain/mappers/session_aggregate_mapper.dart';
import '../../../domain/policies/session_mode_policy.dart';
import '../../../domain/usecases/get_teacher_availability_usecase.dart';
import '../../../domain/usecases/get_teacher_profile_by_id_usecase.dart';
import '../../../domain/usecases/get_teacher_profile_usecase.dart';
import '../../../domain/usecases/submit_session_booking_usecase.dart';
import '../../../domain/usecases/validate_booking_eligibility_usecase.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc({
    required this._getAvailability,
    required this._submitBooking,
    required this._validateEligibility,
    required this._getTeacherProfile,
    this._getTeacherListing,
    this._sessionModePolicy = SessionModePolicy.freeBeta,
    this._onBookingLostDueToNoAvailability,
    this._resolveMarketCode,
    this._paymentConfirmation,
  }) : super(const BookingInitial()) {
    on<BookingScreenOpened>(_onScreenOpened, transformer: restartable());
    on<BookingEligibilityRetried>(
      _onEligibilityRetried,
      transformer: restartable(),
    );
    on<SlotSelected>(_onSlotSelected, transformer: sequential());
    on<CallTypeSelected>(_onCallTypeSelected, transformer: sequential());
    on<BookingSubmitted>(_onSubmitted, transformer: droppable());
    on<BookingConfirmPayment>(_onConfirmPayment, transformer: droppable());
  }

  final GetTeacherAvailabilityUseCase _getAvailability;
  final SubmitSessionBookingUseCase _submitBooking;
  final ValidateBookingEligibilityUseCase _validateEligibility;
  final GetTeacherProfileByIdUseCase _getTeacherProfile;
  final GetTeacherProfileUseCase? _getTeacherListing;
  final SessionModePolicy _sessionModePolicy;
  final SessionPaymentConfirmation? _paymentConfirmation;

  /// Fired when eligibility passes but no unbooked slots exist in the window.
  final void Function(Map<String, Object> parameters)?
  _onBookingLostDueToNoAvailability;

  /// Optional teacher market code for analytics segmentation.
  final Future<String?> Function(String teacherId)? _resolveMarketCode;

  Future<void> _onScreenOpened(
    BookingScreenOpened event,
    Emitter<BookingState> emit,
  ) => _checkEligibilityThenLoadSlots(
    teacherId: event.teacherId,
    studentId: event.studentId,
    from: event.from,
    to: event.to,
    emit: emit,
  );

  Future<void> _onEligibilityRetried(
    BookingEligibilityRetried event,
    Emitter<BookingState> emit,
  ) => _checkEligibilityThenLoadSlots(
    teacherId: event.teacherId,
    studentId: event.studentId,
    from: event.from,
    to: event.to,
    emit: emit,
  );

  Future<void> _checkEligibilityThenLoadSlots({
    required String teacherId,
    required String studentId,
    required DateTime from,
    required DateTime to,
    required Emitter<BookingState> emit,
  }) async {
    emit(const BookingEligibilityChecking());

    final eligibility = await _validateEligibility(
      teacherId: teacherId,
      studentId: studentId,
    );

    if (eligibility.isLeft()) {
      eligibility.fold((f) => emit(BookingFailure(f)), (_) {});
      return;
    }

    emit(const BookingSlotsLoading());

    final profileResult = await _getTeacherProfile(teacherId);
    final externalMeetingUrl = profileResult.fold(
      (_) => null,
      (profile) => profile.externalMeetingUrl,
    );

    SessionPricingType? pricingType;
    SessionPrice? sessionPrice;
    ManualPaymentPrice? manualPaymentPrice;
    final listing = _getTeacherListing;
    if (listing != null) {
      final listingResult = await listing(teacherId);
      listingResult.fold((_) {}, (teacher) {
        pricingType = teacher.pricingType;
        sessionPrice = teacher.price;
        manualPaymentPrice = teacher.manualPaymentPrice;
      });
    }

    final defaultCallType = SessionModePolicy.defaultCallType(
      policy: _sessionModePolicy,
      externalMeetingUrl: externalMeetingUrl,
    );

    final result = await _getAvailability(teacherId, from: from, to: to);

    if (result.isLeft()) {
      result.fold((failure) => emit(BookingFailure(failure)), (_) {});
      return;
    }

    final slots = result.fold(
      (_) => const <TeacherAvailability>[],
      (value) => value,
    );
    final available = slots.where((s) => !s.isBooked).toList();
    if (available.isEmpty) {
      await _emitBookingLost(
        teacherId: teacherId,
        from: from,
        to: to,
      );
    }
    emit(
      BookingSelecting(
        teacherId: teacherId,
        availableSlots: available,
        selectedCallType: defaultCallType,
        teacherExternalMeetingUrl: externalMeetingUrl,
        pricingType: pricingType,
        sessionPrice: sessionPrice,
        manualPaymentPrice: manualPaymentPrice,
      ),
    );
  }

  Future<void> _emitBookingLost({
    required String teacherId,
    required DateTime from,
    required DateTime to,
  }) async {
    final callback = _onBookingLostDueToNoAvailability;
    if (callback == null) return;
    final marketCode = await _resolveMarketCode?.call(teacherId);
    callback({
      'teacher_id': teacherId,
      'requested_from': from.toUtc().toIso8601String(),
      'requested_to': to.toUtc().toIso8601String(),
      'market_code': ?marketCode,
    });
  }

  void _onSlotSelected(SlotSelected event, Emitter<BookingState> emit) {
    final current = state;
    if (current is! BookingSelecting) return;
    emit(current.copyWith(selectedSlot: event.slot));
  }

  void _onCallTypeSelected(CallTypeSelected event, Emitter<BookingState> emit) {
    final current = state;
    if (current is! BookingSelecting) return;
    emit(current.copyWith(selectedCallType: event.callType));
  }

  Future<void> _onSubmitted(
    BookingSubmitted event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingSubmitting());

    final result = await _submitBooking(
      teacherId: event.teacherId,
      slotId: event.slotId,
      callType: event.callType,
      paymentReference: event.paymentReference,
      studentNote: event.note,
    );

    result.fold(
      (failure) => emit(BookingFailure(failure)),
      (outcome) {
        if (outcome.requiresPaymentConfirmation) {
          final selecting = state is BookingSelecting
              ? state as BookingSelecting
              : null;
          emit(
            BookingPaymentRequired(
              outcome,
              pricingType:
                  selecting?.pricingType ?? outcome.aggregate.pricingType,
              sessionPrice: selecting?.sessionPrice,
            ),
          );
          return;
        }
        emit(BookingSuccess(aggregateToQuranBooking(outcome.aggregate)));
      },
    );
  }

  Future<void> _onConfirmPayment(
    BookingConfirmPayment event,
    Emitter<BookingState> emit,
  ) async {
    final confirmation = _paymentConfirmation;
    if (confirmation == null) {
      emit(const BookingFailure(PaymentProviderFailure()));
      return;
    }
    final token = event.outcome.clientConfirmToken;
    final paymentReference = event.outcome.paymentReference;
    if (token == null ||
        token.isEmpty ||
        paymentReference == null ||
        paymentReference.isEmpty) {
      emit(const BookingFailure(PaymentProviderFailure()));
      return;
    }

    emit(const BookingSubmitting());
    final result = await confirmation.confirm(
      bookingId: event.outcome.aggregate.id,
      paymentReference: paymentReference,
      clientConfirmToken: token,
    );
    result.fold((failure) => emit(BookingFailure(failure)), (_) {
      emit(
        BookingSuccess(
          aggregateToQuranBooking(
            event.outcome.aggregate.copyWith(
              lifecycleStatus: SessionLifecycleStatus.scheduled,
              paymentReference: paymentReference,
            ),
          ),
        ),
      );
    });
  }
}
