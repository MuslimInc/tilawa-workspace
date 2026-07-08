import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../boundaries/payment/session_payment_confirmation.dart';
import '../../../domain/entities/booking_block_reason.dart';
import '../../../domain/entities/manual_payment_price.dart';
import '../../../domain/entities/session_lifecycle_status.dart';
import '../../../domain/entities/session_price.dart';
import '../../../domain/entities/session_pricing_type.dart';
import '../../../domain/entities/teacher_availability.dart';
import '../../../domain/failures/quran_sessions_failure.dart';
import '../../../domain/mappers/session_aggregate_mapper.dart';
import '../../../domain/policies/session_mode_policy.dart';
import '../../../domain/entities/session_pricing_quote.dart';
import '../../../domain/usecases/get_booking_pricing_quote_usecase.dart';
import '../../../domain/usecases/get_teacher_availability_usecase.dart';
import '../../../domain/usecases/get_teacher_profile_by_id_usecase.dart';
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
    this._getPricingQuote,
    this._sessionModePolicy = SessionModePolicy.videoOnly,
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

  /// Server-authoritative price preview. Flutter must not derive final
  /// paid/free or payment-block state without this quote.
  final GetBookingPricingQuoteUseCase? _getPricingQuote;
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
    final teacherDisplayName = profileResult.fold(
      (_) => null,
      (profile) => profile.displayName,
    );

    SessionPricingType? pricingType;
    SessionPrice? sessionPrice;
    bool? paymentProviderAvailable;
    ManualPaymentPrice? manualPaymentPrice;
    BookingBlockReason blockReason = BookingBlockReason.none;

    final fetched = await _fetchServerQuote(teacherId);
    if (fetched.quote != null) {
      final quote = fetched.quote!;
      pricingType = quote.pricingType;
      sessionPrice = quote.price;
      paymentProviderAvailable = quote.paymentProviderAvailable;
      manualPaymentPrice = quote.isManualOffApp && quote.isPaid
          ? ManualPaymentPrice(
              amountMinor: (quote.amount * 100).round(),
              currencyCode: quote.currencyCode,
            )
          : null;
      blockReason = fetched.failureBlockReason ?? BookingBlockReason.none;
    } else if (fetched.failureBlockReason != null) {
      // The server reported a typed config/admin block (a non-best-effort
      // backend that still throws). Surface the typed reason and do NOT fall
      // back to the client market preview — that would hide the block and
      // let the student reach submit, only to be rejected server-side.
      blockReason = fetched.failureBlockReason!;
    } else {
      // Transport-level quote failure only (network/App Check/timeout).
      // The client-side market preview cannot see teacher-level pricing
      // overrides, so it must not decide whether this session is paid/free or
      // whether payment is unavailable. Keep the price unknown and block submit
      // with neutral retry copy until the server quote is available.
      blockReason = BookingBlockReason.pricingQuoteUnavailable;
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
        teacherDisplayName: teacherDisplayName,
        teacherExternalMeetingUrl: externalMeetingUrl,
        pricingType: pricingType,
        sessionPrice: sessionPrice,
        manualPaymentPrice: manualPaymentPrice,
        paymentProviderAvailable: paymentProviderAvailable,
        blockReason: blockReason,
      ),
    );
  }

  /// Fetches the server quote and splits the outcome so config/admin blocks
  /// are surfaced as typed [BookingBlockReason]s rather than swallowed into
  /// the silent client-side fallback.
  Future<({SessionPricingQuote? quote, BookingBlockReason? failureBlockReason})>
  _fetchServerQuote(String teacherId) async {
    final getPricingQuote = _getPricingQuote;
    if (getPricingQuote == null) {
      return (quote: null, failureBlockReason: null);
    }
    final result = await getPricingQuote(teacherId: teacherId);
    return result.fold(
      (f) => (quote: null, failureBlockReason: _blockReasonFromFailure(f)),
      (quote) => (quote: quote, failureBlockReason: quote.blockReason),
    );
  }

  /// Maps a quote failure of a *config/admin* kind to a typed block reason.
  /// Returns null for transport/auth failures so the bloc surfaces neutral
  /// pricing-unavailable copy instead of inferring payment state.
  BookingBlockReason? _blockReasonFromFailure(QuranSessionsFailure f) {
    if (f is PlatformBookingDisabledFailure) {
      return BookingBlockReason.bookingDisabledByAdmin;
    }
    if (f is PricingConfigMissingFailure) {
      return BookingBlockReason.pricingConfigMissing;
    }
    if (f is MarketNotEnabledFailure) {
      return BookingBlockReason.marketDisabled;
    }
    if (f is TeacherNotWhitelistedFailure || f is TeacherNotVerifiedFailure) {
      return BookingBlockReason.teacherNotBookable;
    }
    return null;
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
    final selecting = state is BookingSelecting
        ? state as BookingSelecting
        : null;
    emit(const BookingSubmitting());

    final result = await _submitBooking(
      teacherId: event.teacherId,
      slotId: event.slotId,
      callType: event.callType,
      pricingType: event.pricingType,
      paymentReference: event.paymentReference,
      studentNote: event.note,
    );

    result.fold(
      (failure) => emit(BookingFailure(failure)),
      (outcome) {
        if (outcome.requiresPaymentConfirmation) {
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
        final booking = aggregateToQuranBooking(outcome.aggregate);
        if (outcome.aggregate.lifecycleStatus ==
            SessionLifecycleStatus.pendingPayment) {
          final paymentReference =
              outcome.paymentReference ?? outcome.aggregate.paymentReference;
          if (paymentReference != null && paymentReference.isNotEmpty) {
            emit(
              BookingManualPaymentPending(
                booking: booking,
                paymentReference: paymentReference,
                teacherDisplayName:
                    selecting?.teacherDisplayName ??
                    outcome.aggregate.teacherId,
                startsAt:
                    selecting?.selectedSlot?.startsAt ??
                    outcome.aggregate.startsAt,
                sessionPrice: selecting?.sessionPrice,
              ),
            );
            return;
          }
        }
        emit(BookingSuccess(booking));
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
