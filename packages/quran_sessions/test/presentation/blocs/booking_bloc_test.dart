import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/teacher_availability.dart';
import 'package:quran_sessions/src/domain/entities/quran_booking.dart';
import 'package:quran_sessions/src/domain/entities/session_call_type.dart';
import 'package:quran_sessions/src/domain/entities/user_profile.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/usecases/create_booking_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/get_teacher_availability_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/validate_booking_eligibility_usecase.dart';
import 'package:quran_sessions/src/presentation/blocs/booking/booking_bloc.dart';
import 'package:quran_sessions/src/presentation/blocs/booking/booking_event.dart';
import 'package:quran_sessions/src/presentation/blocs/booking/booking_state.dart';
import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_booking_repository.dart';
import '../../helpers/fakes/fake_market_config_repository.dart';
import '../../helpers/fakes/fake_session_policy_repository.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fakes/fake_user_profile_repository.dart';
import '../../helpers/fixtures.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  late FakeTeacherRepository teacherRepo;
  late FakeScheduleRepository scheduleRepo;
  late FakeSessionRepository sessionRepo;
  late FakeBookingRepository bookingRepo;
  late FakeUserProfileRepository profileRepo;
  late FakeSessionPolicyRepository policyRepo;
  late FakeMarketConfigRepository marketConfigRepo;
  late GetTeacherAvailabilityUseCase getAvailability;
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
    bookingRepo = FakeBookingRepository();
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
    bloc = BookingBloc(
      getAvailability: getAvailability,
      createBooking: CreateBookingUseCase(bookingRepo, getAvailability),
      validateEligibility: ValidateBookingEligibilityUseCase(
        profileRepository: profileRepo,
        policyRepository: policyRepo,
        teacherRepository: teacherRepo,
        marketConfigRepository: marketConfigRepo,
      ),
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
      act: (b) => b.add(const CallTypeSelected(SessionCallType.voiceCall)),
      expect: () => [isA<BookingSelecting>()],
      verify: (b) {
        final state = b.state as BookingSelecting;
        check(state.selectedCallType).equals(SessionCallType.voiceCall);
      },
    );

    blocTest<BookingBloc, BookingState>(
      'BookingSubmitted emits [Submitting, Success] for generated slot',
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
        isA<BookingSuccess>(),
      ],
      verify: (b) {
        final state = b.state as BookingSuccess;
        check(state.booking.status).equals(BookingStatus.confirmed);
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
        bookingRepo.failWith = const ServerFailure(statusCode: 500);
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
}
