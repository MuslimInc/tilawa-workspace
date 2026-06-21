import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

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
import '../../helpers/fakes/fake_booking_repository.dart';
import '../../helpers/fakes/fake_market_config_repository.dart';
import '../../helpers/fakes/fake_session_policy_repository.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fakes/fake_user_profile_repository.dart';
import '../../helpers/fixtures.dart';

void main() {
  late FakeTeacherRepository teacherRepo;
  late FakeBookingRepository bookingRepo;
  late FakeUserProfileRepository profileRepo;
  late FakeSessionPolicyRepository policyRepo;
  late FakeMarketConfigRepository marketConfigRepo;
  late BookingBloc bloc;

  final now = DateTime.now();

  setUp(() {
    teacherRepo = FakeTeacherRepository()
      ..teachers = [makeTeacher(id: 'teacher_1')];
    bookingRepo = FakeBookingRepository();
    // Profile is complete (has gender + DOB) so eligibility passes in all tests
    // that focus on the booking flow rather than eligibility rules.
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
    bloc = BookingBloc(
      getAvailability: GetTeacherAvailabilityUseCase(teacherRepo),
      createBooking: CreateBookingUseCase(bookingRepo),
      validateEligibility: ValidateBookingEligibilityUseCase(
        profileRepository: profileRepo,
        policyRepository: policyRepo,
        teacherRepository: teacherRepo,
        marketConfigRepository: marketConfigRepo,
      ),
    );
  });

  tearDown(() => bloc.close());

  group('BookingBloc', () {
    blocTest<BookingBloc, BookingState>(
      'emits [SlotsLoading, Selecting] when slots are available',
      build: () {
        teacherRepo.availability = [makeSlot(), makeSlot(slotId: 'slot_2')];
        return bloc;
      },
      act: (b) => b.add(
        BookingScreenOpened(
          teacherId: 'teacher_1',
          studentId: 'student_1',
          from: now,
          to: now.add(const Duration(days: 14)),
        ),
      ),
      expect: () => [
        isA<BookingEligibilityChecking>(),
        isA<BookingSlotsLoading>(),
        isA<BookingSelecting>(),
      ],
      verify: (b) {
        final state = b.state as BookingSelecting;
        check(state.availableSlots).length.equals(2);
        check(state.canSubmit).isFalse();
      },
    );

    blocTest<BookingBloc, BookingState>(
      'SlotSelected updates selectedSlot and enables submit',
      build: () {
        teacherRepo.availability = [makeSlot()];
        return bloc;
      },
      seed: () => BookingSelecting(
        teacherId: 'teacher_1',
        availableSlots: [makeSlot()],
      ),
      act: (b) => b.add(SlotSelected(makeSlot())),
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
        availableSlots: [],
      ),
      act: (b) => b.add(const CallTypeSelected(SessionCallType.voiceCall)),
      expect: () => [isA<BookingSelecting>()],
      verify: (b) {
        final state = b.state as BookingSelecting;
        check(state.selectedCallType).equals(SessionCallType.voiceCall);
      },
    );

    blocTest<BookingBloc, BookingState>(
      'BookingSubmitted emits [Submitting, Success] on success',
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
        isA<BookingSuccess>(),
      ],
      verify: (b) {
        final state = b.state as BookingSuccess;
        check(state.booking.status).equals(BookingStatus.confirmed);
      },
    );

    blocTest<BookingBloc, BookingState>(
      'BookingSubmitted emits [Submitting, Failure] on repository error',
      build: () {
        bookingRepo.failWith = const ServerFailure(statusCode: 500);
        return bloc;
      },
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
  });
}
