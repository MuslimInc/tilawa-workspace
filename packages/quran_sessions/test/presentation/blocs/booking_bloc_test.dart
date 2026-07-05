import 'package:dartz_plus/dartz_plus.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/teacher_availability.dart';
import 'package:quran_sessions/src/domain/entities/teacher_profile.dart';
import 'package:quran_sessions/src/domain/entities/teacher_verification_status.dart';
import 'package:quran_sessions/src/domain/rules/teacher_profile_completeness.dart';
import 'package:quran_sessions/src/domain/entities/quran_booking.dart';
import 'package:quran_sessions/src/domain/entities/session_call_type.dart';
import 'package:quran_sessions/src/domain/entities/user_profile.dart';
import 'package:quran_sessions/src/domain/entities/weekly_schedule.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/entities/session_pricing_quote.dart';
import 'package:quran_sessions/src/domain/entities/session_pricing_type.dart';
import 'package:quran_sessions/src/domain/usecases/get_booking_pricing_quote_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/get_teacher_profile_by_id_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/get_teacher_availability_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/validate_booking_eligibility_usecase.dart';
import 'package:quran_sessions/src/presentation/blocs/booking/booking_bloc.dart';
import 'package:quran_sessions/src/presentation/blocs/booking/booking_event.dart';
import 'package:quran_sessions/src/presentation/blocs/booking/booking_state.dart';
import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_market_config_repository.dart';
import '../../helpers/fakes/fake_session_policy_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fakes/fake_user_profile_repository.dart';
import '../../helpers/fakes/fake_session_mutation_gateway.dart';
import '../../helpers/fakes/fake_session_pricing_quote_gateway.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';
import '../../helpers/lifecycle_test_helpers.dart';
import '../../helpers/fixtures.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  late FakeTeacherRepository teacherRepo;
  late FakeScheduleRepository scheduleRepo;
  late FakeSessionRepository sessionRepo;
  late FakeUserProfileRepository profileRepo;
  late FakeSessionPolicyRepository policyRepo;
  late FakeMarketConfigRepository marketConfigRepo;
  late GetTeacherAvailabilityUseCase getAvailability;
  late FakeSessionMutationGateway mutationGateway;
  late FakeTeacherProfileRepository teacherProfileRepo;
  late BookingBloc bloc;
  late TeacherAvailability generatedSlot;

  final fixedNow = DateTime.utc(2026, 1, 9);
  final windowFrom = DateTime.utc(2026, 1, 10);
  final windowTo = DateTime.utc(2026, 1, 17);

  setUpAll(tz_data.initializeTimeZones);

  setUp(() async {
    teacherRepo = FakeTeacherRepository()
      ..teachers = [makeTeacher(id: 'teacher_1')];
    scheduleRepo = FakeScheduleRepository()..schedule = makeWeeklySchedule();
    sessionRepo = FakeSessionRepository();
    profileRepo = FakeUserProfileRepository(
      profile: makeProfile(
        userId: 'student_1',
        gender: UserGender.male,
        dateOfBirth: DateTime(1995, 6, 15),
        countryCode: 'EG',
        cityId: 'cairo',
      ),
    );
    policyRepo = FakeSessionPolicyRepository();
    marketConfigRepo = FakeMarketConfigRepository();
    getAvailability = buildGetTeacherAvailabilityUseCase(
      scheduleRepository: scheduleRepo,
      sessionRepository: sessionRepo,
      now: () => fixedNow,
    );
    mutationGateway = FakeSessionMutationGateway();
    teacherProfileRepo = FakeTeacherProfileRepository(
      profile: _teacherProfile(externalMeetingUrl: null),
    );
    bloc = BookingBloc(
      getAvailability: getAvailability,
      submitBooking: buildSubmitSessionBookingUseCase(
        getAvailability: getAvailability,
        mutationGateway: mutationGateway,
        teacherProfiles: teacherProfileRepo,
      ),
      validateEligibility: ValidateBookingEligibilityUseCase(
        profileRepository: profileRepo,
        policyRepository: policyRepo,
        teacherRepository: teacherRepo,
        marketConfigRepository: marketConfigRepo,
      ),
      getTeacherProfile: GetTeacherProfileByIdUseCase(teacherProfileRepo),
    );

    final slots = await getAvailability(
      'teacher_1',
      from: windowFrom,
      to: windowTo,
    );
    generatedSlot = slots.fold(
      (_) => throw StateError(''),
      (value) => value.first,
    );
  });

  tearDown(() => bloc.close());

  group('BookingBloc', () {
    final bookingLostEvents = <Map<String, Object>>[];

    blocTest<BookingBloc, BookingState>(
      'emits [SlotsLoading, Selecting] when generated slots are available',
      build: () => bloc,
      act: (b) => b.add(
        BookingScreenOpened(
          teacherId: 'teacher_1',
          studentId: 'student_1',
          from: windowFrom,
          to: windowTo,
        ),
      ),
      expect: () => [
        isA<BookingEligibilityChecking>(),
        isA<BookingSlotsLoading>(),
        isA<BookingSelecting>(),
      ],
      verify: (b) {
        final state = b.state as BookingSelecting;
        check(state.availableSlots).isNotEmpty();
        check(state.canSubmit).isFalse();
        check(state.selectedCallType).equals(SessionCallType.videoCall);
        check(state.hasExternalMeetingUrl).isFalse();
      },
    );

    blocTest<BookingBloc, BookingState>(
      'defaults to video when teacher has meeting URL under video-only policy',
      build: () {
        teacherProfileRepo = FakeTeacherProfileRepository(
          profile: _teacherProfile(
            externalMeetingUrl: 'https://meet.example.com/room',
          ),
        );
        return BookingBloc(
          getAvailability: getAvailability,
          submitBooking: buildSubmitSessionBookingUseCase(
            getAvailability: getAvailability,
            mutationGateway: mutationGateway,
            teacherProfiles: teacherProfileRepo,
          ),
          validateEligibility: ValidateBookingEligibilityUseCase(
            profileRepository: profileRepo,
            policyRepository: policyRepo,
            teacherRepository: teacherRepo,
            marketConfigRepository: marketConfigRepo,
          ),
          getTeacherProfile: GetTeacherProfileByIdUseCase(teacherProfileRepo),
        );
      },
      act: (b) => b.add(
        BookingScreenOpened(
          teacherId: 'teacher_1',
          studentId: 'student_1',
          from: windowFrom,
          to: windowTo,
        ),
      ),
      expect: () => [
        isA<BookingEligibilityChecking>(),
        isA<BookingSlotsLoading>(),
        isA<BookingSelecting>(),
      ],
      verify: (b) {
        final state = b.state as BookingSelecting;
        check(state.selectedCallType).equals(SessionCallType.videoCall);
        check(state.hasExternalMeetingUrl).isTrue();
      },
    );

    blocTest<BookingBloc, BookingState>(
      'fires onBookingLostDueToNoAvailability when no unbooked slots',
      build: () {
        bookingLostEvents.clear();
        scheduleRepo.schedule = WeeklySchedule.empty(
          teacherId: 'teacher_1',
          timezone: 'Africa/Cairo',
        );
        final emptyAvailability = buildGetTeacherAvailabilityUseCase(
          scheduleRepository: scheduleRepo,
          sessionRepository: sessionRepo,
          now: () => fixedNow,
        );
        return BookingBloc(
          getAvailability: emptyAvailability,
          submitBooking: buildSubmitSessionBookingUseCase(
            getAvailability: emptyAvailability,
            mutationGateway: mutationGateway,
            teacherProfiles: teacherProfileRepo,
          ),
          validateEligibility: ValidateBookingEligibilityUseCase(
            profileRepository: profileRepo,
            policyRepository: policyRepo,
            teacherRepository: teacherRepo,
            marketConfigRepository: marketConfigRepo,
          ),
          getTeacherProfile: GetTeacherProfileByIdUseCase(teacherProfileRepo),
          onBookingLostDueToNoAvailability: bookingLostEvents.add,
          resolveMarketCode: (_) async => 'EG',
        );
      },
      act: (b) => b.add(
        BookingScreenOpened(
          teacherId: 'teacher_1',
          studentId: 'student_1',
          from: windowFrom,
          to: windowTo,
        ),
      ),
      expect: () => [
        isA<BookingEligibilityChecking>(),
        isA<BookingSlotsLoading>(),
        isA<BookingSelecting>(),
      ],
      verify: (b) {
        final state = b.state as BookingSelecting;
        check(state.availableSlots).isEmpty();
        check(bookingLostEvents.length).equals(1);
        check(bookingLostEvents.single['teacher_id']).equals('teacher_1');
        check(bookingLostEvents.single['market_code']).equals('EG');
      },
    );

    blocTest<BookingBloc, BookingState>(
      'SlotSelected updates selectedSlot and enables submit',
      build: () => bloc,
      seed: () => BookingSelecting(
        teacherId: 'teacher_1',
        availableSlots: [generatedSlot],
      ),
      act: (b) => b.add(SlotSelected(generatedSlot)),
      expect: () => [isA<BookingSelecting>()],
      verify: (b) {
        final state = b.state as BookingSelecting;
        check(state.selectedSlot).isNotNull();
        check(state.canSubmit).isTrue();
      },
    );

    blocTest<BookingBloc, BookingState>(
      'CallTypeSelected updates selectedCallType',
      build: () => bloc,
      seed: () => BookingSelecting(
        teacherId: 'teacher_1',
        availableSlots: const [],
      ),
      act: (b) => b.add(const CallTypeSelected(SessionCallType.videoCall)),
      expect: () => [isA<BookingSelecting>()],
      verify: (b) {
        final state = b.state as BookingSelecting;
        check(state.selectedCallType).equals(SessionCallType.videoCall);
      },
    );

    blocTest<BookingBloc, BookingState>(
      'BookingSubmitted emits [Submitting, Success] for voice when no URL',
      build: () => bloc,
      act: (b) => b.add(
        BookingSubmitted(
          teacherId: 'teacher_1',
          slotId: generatedSlot.slotId,
          callType: SessionCallType.voiceCall,
        ),
      ),
      expect: () => [
        isA<BookingSubmitting>(),
        isA<BookingSuccess>(),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'BookingSubmitted emits [Submitting, Success] for external with URL',
      build: () {
        teacherProfileRepo = FakeTeacherProfileRepository(
          profile: _teacherProfile(
            externalMeetingUrl: 'https://meet.example.com/room',
          ),
        );
        return BookingBloc(
          getAvailability: getAvailability,
          submitBooking: buildSubmitSessionBookingUseCase(
            getAvailability: getAvailability,
            mutationGateway: mutationGateway,
            teacherProfiles: teacherProfileRepo,
          ),
          validateEligibility: ValidateBookingEligibilityUseCase(
            profileRepository: profileRepo,
            policyRepository: policyRepo,
            teacherRepository: teacherRepo,
            marketConfigRepository: marketConfigRepo,
          ),
          getTeacherProfile: GetTeacherProfileByIdUseCase(teacherProfileRepo),
        );
      },
      act: (b) => b.add(
        BookingSubmitted(
          teacherId: 'teacher_1',
          slotId: generatedSlot.slotId,
          callType: SessionCallType.externalMeeting,
        ),
      ),
      expect: () => [
        isA<BookingSubmitting>(),
        isA<BookingSuccess>(),
      ],
      verify: (b) {
        final state = b.state as BookingSuccess;
        check(state.booking.status).equals(BookingStatus.confirmed);
      },
    );

    blocTest<BookingBloc, BookingState>(
      'BookingSubmitted emits meeting link failure for external without URL',
      build: () => bloc,
      act: (b) => b.add(
        BookingSubmitted(
          teacherId: 'teacher_1',
          slotId: generatedSlot.slotId,
          callType: SessionCallType.externalMeeting,
        ),
      ),
      expect: () => [
        isA<BookingSubmitting>(),
        isA<BookingFailure>(),
      ],
      verify: (b) {
        final state = b.state as BookingFailure;
        check(state.failure).isA<MeetingLinkUnavailableFailure>();
      },
    );

    blocTest<BookingBloc, BookingState>(
      'BookingSubmitted emits failure for unavailable legacy slot id',
      build: () => bloc,
      act: (b) => b.add(
        const BookingSubmitted(
          teacherId: 'teacher_1',
          slotId: 'slot_1',
          callType: SessionCallType.externalMeeting,
        ),
      ),
      expect: () => [
        isA<BookingSubmitting>(),
        isA<BookingFailure>(),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'BookingSubmitted emits [Submitting, Failure] on repository error',
      build: () {
        mutationGateway.onCreate =
            ({required teacherId, required studentId, required slotId}) async =>
                const Left(ServerFailure(statusCode: 500));
        return bloc;
      },
      act: (b) => b.add(
        BookingSubmitted(
          teacherId: 'teacher_1',
          slotId: generatedSlot.slotId,
          callType: SessionCallType.externalMeeting,
        ),
      ),
      expect: () => [
        isA<BookingSubmitting>(),
        isA<BookingFailure>(),
      ],
    );
  });

  group('BookingBloc server pricing quote', () {
    BookingBloc buildWithQuote(FakeSessionPricingQuoteGateway gateway) =>
        BookingBloc(
          getAvailability: getAvailability,
          submitBooking: buildSubmitSessionBookingUseCase(
            getAvailability: getAvailability,
            mutationGateway: mutationGateway,
            teacherProfiles: teacherProfileRepo,
          ),
          validateEligibility: ValidateBookingEligibilityUseCase(
            profileRepository: profileRepo,
            policyRepository: policyRepo,
            teacherRepository: teacherRepo,
            marketConfigRepository: marketConfigRepo,
          ),
          getTeacherProfile: GetTeacherProfileByIdUseCase(teacherProfileRepo),
          getPricingQuote: GetBookingPricingQuoteUseCase(gateway),
        );

    void openScreen(BookingBloc b) => b.add(
      BookingScreenOpened(
        teacherId: 'teacher_1',
        studentId: 'student_1',
        from: windowFrom,
        to: windowTo,
      ),
    );

    blocTest<BookingBloc, BookingState>(
      'free quote shows free pricing and allows booking once a slot is picked',
      build: () => buildWithQuote(
        FakeSessionPricingQuoteGateway(
          quote: const SessionPricingQuote(
            pricingType: SessionPricingType.free,
            amount: 0,
            currencyCode: 'USD',
            paymentRequired: false,
            paymentProviderAvailable: false,
          ),
        ),
      ),
      act: openScreen,
      skip: 2,
      expect: () => [isA<BookingSelecting>()],
      verify: (b) {
        final state = b.state as BookingSelecting;
        check(state.pricingType).equals(SessionPricingType.free);
        check(state.sessionPrice).isNull();
        check(state.isPaymentBlocked).isFalse();
      },
    );

    blocTest<BookingBloc, BookingState>(
      'free session with payment provider unavailable still allows booking',
      build: () => buildWithQuote(
        FakeSessionPricingQuoteGateway(
          quote: const SessionPricingQuote(
            pricingType: SessionPricingType.free,
            amount: 0,
            currencyCode: 'USD',
            paymentRequired: false,
            // Provider off must never gate a free session.
            paymentProviderAvailable: false,
          ),
        ),
      ),
      act: (b) async {
        openScreen(b);
        await b.stream.firstWhere((s) => s is BookingSelecting);
        final selecting = b.state as BookingSelecting;
        b.add(SlotSelected(selecting.availableSlots.first));
      },
      verify: (b) {
        final state = b.state as BookingSelecting;
        check(state.isPaymentBlocked).isFalse();
        check(state.selectedSlot).isNotNull();
        check(state.canSubmit).isTrue();
      },
    );

    blocTest<BookingBloc, BookingState>(
      'paid quote with provider available shows the price and permits submit',
      build: () => buildWithQuote(
        FakeSessionPricingQuoteGateway(
          quote: const SessionPricingQuote(
            pricingType: SessionPricingType.fixedPerSession,
            amount: 50,
            currencyCode: 'EGP',
            paymentRequired: true,
            paymentProviderAvailable: true,
            countryCode: 'EG',
            cityId: 'cairo',
          ),
        ),
      ),
      act: openScreen,
      skip: 2,
      expect: () => [isA<BookingSelecting>()],
      verify: (b) {
        final state = b.state as BookingSelecting;
        check(state.pricingType).equals(SessionPricingType.fixedPerSession);
        check(state.sessionPrice).isNotNull();
        check(state.sessionPrice!.amount).equals(50);
        check(state.sessionPrice!.currencyCode).equals('EGP');
        check(state.isPaymentBlocked).isFalse();
      },
    );

    blocTest<BookingBloc, BookingState>(
      'paid quote with provider disabled blocks submission before booking',
      build: () => buildWithQuote(
        FakeSessionPricingQuoteGateway(
          quote: const SessionPricingQuote(
            pricingType: SessionPricingType.fixedPerSession,
            amount: 50,
            currencyCode: 'EGP',
            paymentRequired: true,
            paymentProviderAvailable: false,
            countryCode: 'EG',
            cityId: 'cairo',
          ),
        ),
      ),
      act: (b) async {
        openScreen(b);
        await b.stream.firstWhere((s) => s is BookingSelecting);
        final selecting = b.state as BookingSelecting;
        b.add(SlotSelected(selecting.availableSlots.first));
      },
      verify: (b) {
        final state = b.state as BookingSelecting;
        check(state.isPaymentBlocked).isTrue();
        // A selected slot must NOT unlock submission while payment is blocked.
        check(state.selectedSlot).isNotNull();
        check(state.canSubmit).isFalse();
      },
    );

    blocTest<BookingBloc, BookingState>(
      'quote failure falls back to the client-side market preview',
      build: () => buildWithQuote(
        FakeSessionPricingQuoteGateway(
          failure: const NetworkFailure(),
        ),
      ),
      act: openScreen,
      skip: 2,
      expect: () => [isA<BookingSelecting>()],
      verify: (b) {
        final state = b.state as BookingSelecting;
        // Fallback preview carries no provider signal, so it never blocks.
        check(state.paymentProviderAvailable).isNull();
        check(state.isPaymentBlocked).isFalse();
      },
    );
  });
}

TeacherProfile _teacherProfile({required String? externalMeetingUrl}) =>
    TeacherProfileCompleteness.withComputedVisibility(
      TeacherProfile(
        id: 'teacher_1',
        userId: 'teacher_1',
        displayName: 'Sheikh Ahmed',
        publicBio: 'Bio',
        verificationStatus: TeacherVerificationStatus.verified,
        teachingLanguages: const ['ar'],
        specializations: const ['tajweed'],
        averageRating: 4.8,
        reviewCount: 42,
        isActive: true,
        profileCompleteness: TeacherProfileCompletenessStatus.complete,
        isPubliclyVisible: true,
        externalMeetingUrl: externalMeetingUrl,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
