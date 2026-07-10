import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/booking_block_reason.dart';
import 'package:quran_sessions/src/domain/entities/effective_pricing_source.dart';
import 'package:quran_sessions/src/domain/entities/session_pricing_quote.dart';
import 'package:quran_sessions/src/domain/entities/session_pricing_type.dart';
import 'package:quran_sessions/src/domain/entities/teacher_availability.dart';
import 'package:quran_sessions/src/domain/entities/weekly_schedule.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/usecases/get_booking_pricing_quote_usecase.dart';
// GetBookingPricingQuotesUseCase (batch) lives in the same file as the single.
import 'package:quran_sessions/src/domain/usecases/get_teacher_availability_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/get_teachers_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/resolve_teacher_list_usecase.dart';
import 'package:quran_sessions/src/presentation/blocs/teacher_list/teacher_list_bloc.dart';
import 'package:quran_sessions/src/presentation/blocs/teacher_list/teacher_list_event.dart';
import 'package:quran_sessions/src/presentation/blocs/teacher_list/teacher_list_state.dart';
import 'package:quran_sessions/src/presentation/models/teacher_availability_summary.dart';

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_booked_slot_lock_repository.dart';
import '../../helpers/fakes/fake_session_pricing_quote_gateway.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fixtures.dart';

/// Free, bookable quote — the row stays visible in the teacher list.
const _freeQuote = SessionPricingQuote(
  pricingType: SessionPricingType.free,
  amount: 0,
  currencyCode: 'EGP',
  paymentRequired: false,
  paymentProviderAvailable: false,
  bookingEnabled: true,
  quranSessionsEnabled: true,
  effectivePricingSource: EffectivePricingSource.marketConfig,
  blockReason: BookingBlockReason.none,
);

/// Paid quote while the payment provider is disabled — a non-transient block,
/// so the teacher-list filter must hide the row.
const _paidUnavailableQuote = SessionPricingQuote(
  pricingType: SessionPricingType.fixedPerSession,
  amount: 100,
  currencyCode: 'EGP',
  paymentRequired: true,
  paymentProviderAvailable: false,
  bookingEnabled: true,
  quranSessionsEnabled: true,
  effectivePricingSource: EffectivePricingSource.marketConfig,
  blockReason: BookingBlockReason.paymentProviderUnavailable,
);

class _StaticAvailabilityUseCase extends GetTeacherAvailabilityUseCase {
  _StaticAvailabilityUseCase(this.slots)
    : super(
        scheduleRepository: FakeScheduleRepository(),
        bookedSlotLocks: FakeBookedSlotLockRepository(),
      );

  final Map<String, List<TeacherAvailability>> slots;

  @override
  Future<Either<QuranSessionsFailure, List<TeacherAvailability>>> call(
    String teacherId, {
    required DateTime from,
    required DateTime to,
    WeeklySchedule? preloadedSchedule,
  }) async {
    return Right(slots[teacherId] ?? const []);
  }
}

void main() {
  late FakeTeacherRepository repo;
  late TeacherListBloc bloc;

  setUp(() {
    repo = FakeTeacherRepository();
    bloc = TeacherListBloc(
      ResolveTeacherListUseCase(GetTeachersUseCase(repo)),
      _StaticAvailabilityUseCase(const {}),
    );
  });

  tearDown(() => bloc.close());

  group('TeacherListBloc', () {
    blocTest<TeacherListBloc, TeacherListState>(
      'emits [Loading, Success] when teachers are returned',
      build: () {
        repo.teachers = [makeTeacher(id: '1'), makeTeacher(id: '2')];
        return bloc;
      },
      act: (b) => b.add(const LoadTeachersRequested()),
      expect: () => [
        isA<TeacherListLoading>(),
        isA<TeacherListSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherListSuccess;
        check(state.teachers).length.equals(2);
        check(state.hasMore).isFalse();
      },
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'emits availability summaries from generated availability use case',
      build: () {
        final DateTime slotStart = DateTime.now().add(const Duration(hours: 2));
        repo.teachers = [makeTeacher(id: 'teacher_with_slots')];
        return TeacherListBloc(
          ResolveTeacherListUseCase(GetTeachersUseCase(repo)),
          _StaticAvailabilityUseCase({
            'teacher_with_slots': [
              makeSlot(
                teacherId: 'teacher_with_slots',
                startsAt: slotStart,
              ),
            ],
          }),
        );
      },
      act: (b) => b.add(const LoadTeachersRequested()),
      expect: () => [
        isA<TeacherListLoading>(),
        isA<TeacherListSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherListSuccess;
        final summary = state.availabilitySummaries['teacher_with_slots'];
        check(summary).isNotNull();
        check(summary!.status).equals(TeacherAvailabilityStatus.availableToday);
        check(summary.hasAvailableSlots).isTrue();
      },
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'emits [Loading, Empty] when no teachers match filter',
      build: () {
        repo.teachers = [
          makeTeacher(specializations: ['tajweed']),
        ];
        return bloc;
      },
      act: (b) => b.add(const LoadTeachersRequested(specialization: 'hifz')),
      expect: () => [
        isA<TeacherListLoading>(),
        isA<TeacherListEmpty>(),
      ],
      verify: (b) {
        final state = b.state as TeacherListEmpty;
        check(state.activeSpecialization).equals('hifz');
      },
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'emits [Loading, Failure] on repository error',
      build: () {
        repo.failWith = const NetworkFailure();
        return bloc;
      },
      act: (b) => b.add(const LoadTeachersRequested()),
      expect: () => [
        isA<TeacherListLoading>(),
        isA<TeacherListFailure>(),
      ],
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'LoadMoreTeachersRequested is dropped when state is not Success',
      build: () => bloc,
      act: (b) => b.add(const LoadMoreTeachersRequested()),
      expect: () => <TeacherListState>[],
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'TeacherFilterChanged re-fetches from page 1 with new filter',
      build: () {
        repo.teachers = [
          makeTeacher(specializations: ['hifz']),
        ];
        return bloc;
      },
      act: (b) => b.add(const TeacherFilterChanged(specialization: 'hifz')),
      expect: () => [
        isA<TeacherListLoading>(),
        isA<TeacherListSuccess>(),
      ],
      verify: (b) {
        final state = b.state as TeacherListSuccess;
        check(state.activeSpecialization).equals('hifz');
      },
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'hides every teacher and emits NoBookableTeachers when all quotes are '
      'paid while the payment provider is unavailable',
      build: () {
        repo.teachers = [makeTeacher(id: 't1'), makeTeacher(id: 't2')];
        return TeacherListBloc(
          ResolveTeacherListUseCase(
            GetTeachersUseCase(repo),
            getPricingQuote: GetBookingPricingQuoteUseCase(
              FakeSessionPricingQuoteGateway(quote: _paidUnavailableQuote),
            ),
          ),
          _StaticAvailabilityUseCase(const {}),
        );
      },
      act: (b) => b.add(const LoadTeachersRequested()),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<TeacherListLoading>(),
        isA<TeacherListNoBookableTeachers>(),
      ],
      verify: (b) {
        final state = b.state as TeacherListNoBookableTeachers;
        check(
          state.hiddenByBlockReason[BookingBlockReason
              .paymentProviderUnavailable],
        ).equals(2);
      },
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'keeps bookable teachers, hides non-transient blocked ones, and exposes '
      'per-teacher quotes',
      build: () {
        repo.teachers = [makeTeacher(id: 't1'), makeTeacher(id: 't2')];
        return TeacherListBloc(
          ResolveTeacherListUseCase(
            GetTeachersUseCase(repo),
            getPricingQuote: GetBookingPricingQuoteUseCase(
              FakeSessionPricingQuoteGateway(
                quotesByTeacher: const {
                  't1': _freeQuote,
                  't2': _paidUnavailableQuote,
                },
              ),
            ),
          ),
          _StaticAvailabilityUseCase(const {}),
        );
      },
      act: (b) => b.add(const LoadTeachersRequested()),
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        final state = b.state as TeacherListSuccess;
        // The paid+unavailable teacher (t2) is hidden from the visible list.
        check(state.teachers.map((t) => t.id).toList()).deepEquals(['t1']);
        // The visible row carries its own free quote.
        check(state.pricingQuotes['t1']!.isFree).isTrue();
      },
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'resolves the page via one batch quote call and applies the '
      'bookability filter',
      build: () {
        repo.teachers = [makeTeacher(id: 't1'), makeTeacher(id: 't2')];
        final gateway = FakeSessionPricingQuoteGateway(
          quotesByTeacher: const {
            't1': _freeQuote,
            't2': _paidUnavailableQuote,
          },
        );
        return TeacherListBloc(
          ResolveTeacherListUseCase(
            GetTeachersUseCase(repo),
            getPricingQuote: GetBookingPricingQuoteUseCase(gateway),
            getPricingQuotes: GetBookingPricingQuotesUseCase(gateway),
          ),
          _StaticAvailabilityUseCase(const {}),
        );
      },
      act: (b) => b.add(const LoadTeachersRequested()),
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        final state = b.state as TeacherListSuccess;
        // Batch quotes flow through the same filter: t2 (paid+unavailable) hidden.
        check(state.teachers.map((t) => t.id).toList()).deepEquals(['t1']);
        check(state.pricingQuotes['t1']!.isFree).isTrue();
      },
    );

    blocTest<TeacherListBloc, TeacherListState>(
      'keeps pricing unresolved when the quote fails',
      build: () {
        repo.teachers = [makeTeacher(id: 't1')];
        return TeacherListBloc(
          ResolveTeacherListUseCase(
            GetTeachersUseCase(repo),
            getPricingQuote: GetBookingPricingQuoteUseCase(
              FakeSessionPricingQuoteGateway(failure: const NetworkFailure()),
            ),
          ),
          _StaticAvailabilityUseCase(const {}),
        );
      },
      act: (b) => b.add(const LoadTeachersRequested()),
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        final state = b.state as TeacherListSuccess;
        check(state.pricingQuote).isNull();
      },
    );
  });
}
