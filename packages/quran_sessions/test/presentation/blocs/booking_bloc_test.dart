import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/src/domain/entities/quran_booking.dart';
import '../../../lib/src/domain/entities/session_call_type.dart';
import '../../../lib/src/domain/failures/quran_sessions_failure.dart';
import '../../../lib/src/domain/usecases/create_booking_usecase.dart';
import '../../../lib/src/domain/usecases/get_teacher_availability_usecase.dart';
import '../../../lib/src/presentation/blocs/booking/booking_bloc.dart';
import '../../../lib/src/presentation/blocs/booking/booking_event.dart';
import '../../../lib/src/presentation/blocs/booking/booking_state.dart';
import '../../helpers/fakes/fake_booking_repository.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fixtures.dart';

void main() {
  late FakeTeacherRepository teacherRepo;
  late FakeBookingRepository bookingRepo;
  late BookingBloc bloc;

  final now = DateTime.now();

  setUp(() {
    teacherRepo = FakeTeacherRepository();
    bookingRepo = FakeBookingRepository();
    bloc = BookingBloc(
      getAvailability: GetTeacherAvailabilityUseCase(teacherRepo),
      createBooking: CreateBookingUseCase(bookingRepo),
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
          from: now,
          to: now.add(const Duration(days: 14)),
        ),
      ),
      expect: () => [
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
