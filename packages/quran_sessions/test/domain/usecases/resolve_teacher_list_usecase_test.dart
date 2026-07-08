import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/booking_block_reason.dart';
import 'package:quran_sessions/src/domain/entities/effective_pricing_source.dart';
import 'package:quran_sessions/src/domain/entities/session_pricing_quote.dart';
import 'package:quran_sessions/src/domain/entities/session_pricing_type.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/usecases/get_booking_pricing_quote_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/get_teachers_usecase.dart';
import 'package:quran_sessions/src/domain/usecases/resolve_teacher_list_usecase.dart';

import '../../helpers/fakes/fake_session_pricing_quote_gateway.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fixtures.dart';

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

const _quoteUnavailable = SessionPricingQuote(
  pricingType: SessionPricingType.free,
  amount: 0,
  currencyCode: 'EGP',
  paymentRequired: false,
  paymentProviderAvailable: false,
  bookingEnabled: true,
  quranSessionsEnabled: true,
  effectivePricingSource: EffectivePricingSource.marketConfig,
  blockReason: BookingBlockReason.pricingQuoteUnavailable,
);

void main() {
  late FakeTeacherRepository repo;

  setUp(() => repo = FakeTeacherRepository());

  ResolveTeacherListUseCase build(FakeSessionPricingQuoteGateway gateway) =>
      ResolveTeacherListUseCase(
        GetTeachersUseCase(repo),
        getPricingQuote: GetBookingPricingQuoteUseCase(gateway),
      );

  ResolveTeacherListUseCase buildBatch(
    FakeSessionPricingQuoteGateway gateway,
  ) => ResolveTeacherListUseCase(
    GetTeachersUseCase(repo),
    getPricingQuote: GetBookingPricingQuoteUseCase(gateway),
    getPricingQuotes: GetBookingPricingQuotesUseCase(gateway),
  );

  group('ResolveTeacherListUseCase', () {
    test('keeps free teachers visible with their quote attached', () async {
      repo.teachers = [makeTeacher(id: 't1')];
      final result = await build(
        FakeSessionPricingQuoteGateway(quote: _freeQuote),
      )();

      final page = result.fold((_) => throw StateError('left'), (r) => r);
      check(page.items.map((i) => i.teacherId).toList()).deepEquals(['t1']);
      check(page.items.single.isBookable).isTrue();
      check(page.items.single.pricingQuote!.isFree).isTrue();
    });

    test(
      'hides paid teachers while the payment provider is disabled',
      () async {
        repo.teachers = [makeTeacher(id: 't1'), makeTeacher(id: 't2')];
        final result = await build(
          FakeSessionPricingQuoteGateway(
            quotesByTeacher: const {
              't1': _freeQuote,
              't2': _paidUnavailableQuote,
            },
          ),
        )();

        final page = result.fold((_) => throw StateError('left'), (r) => r);
        // Domain bookability rule applied here, not in the BLoC.
        check(page.items.map((i) => i.teacherId).toList()).deepEquals(['t1']);
        check(page.rawTeacherCount).equals(2);
        check(
          page.hiddenByBlockReason[BookingBlockReason
              .paymentProviderUnavailable],
        ).equals(1);
      },
    );

    test(
      'keeps a pricingQuoteUnavailable teacher visible but not bookable',
      () async {
        repo.teachers = [makeTeacher(id: 't1')];
        final result = await build(
          FakeSessionPricingQuoteGateway(quote: _quoteUnavailable),
        )();

        final item = result
            .fold((_) => throw StateError('left'), (r) => r)
            .items
            .single;
        check(item.isVisibleInList).isTrue();
        check(item.isBookable).isFalse();
      },
    );

    test(
      'keeps a teacher visible with a null quote on transport failure',
      () async {
        repo.teachers = [makeTeacher(id: 't1')];
        final result = await build(
          FakeSessionPricingQuoteGateway(failure: const NetworkFailure()),
        )();

        final item = result
            .fold((_) => throw StateError('left'), (r) => r)
            .items
            .single;
        check(item.pricingQuote).isNull();
        check(item.isVisibleInList).isTrue();
        check(item.isBookable).isFalse();
      },
    );

    test('deduplicates quote calls for repeated teacher ids', () async {
      repo.teachers = [
        makeTeacher(id: 't1'),
        makeTeacher(id: 't1'),
        makeTeacher(id: 't2'),
      ];
      final gateway = FakeSessionPricingQuoteGateway(quote: _freeQuote);
      await build(gateway)();

      // Two unique ids -> exactly two quote calls, not three.
      check(gateway.callCount).equals(2);
    });

    test(
      'never filters and attaches no quote when pricing is unwired',
      () async {
        repo.teachers = [makeTeacher(id: 't1'), makeTeacher(id: 't2')];
        final result = await ResolveTeacherListUseCase(
          GetTeachersUseCase(repo),
        )();

        final page = result.fold((_) => throw StateError('left'), (r) => r);
        check(page.items.length).equals(2);
        check(page.items.every((i) => i.pricingQuote == null)).isTrue();
      },
    );

    test('propagates a repository failure', () async {
      repo.failWith = const NetworkFailure();
      final result = await build(
        FakeSessionPricingQuoteGateway(quote: _freeQuote),
      )();
      check(result.isLeft()).isTrue();
    });

    test(
      'resolves a whole page with one batch call, no per-teacher fan-out',
      () async {
        repo.teachers = [
          makeTeacher(id: 't1'),
          makeTeacher(id: 't2'),
          makeTeacher(id: 't3'),
        ];
        final gateway = FakeSessionPricingQuoteGateway(quote: _freeQuote);
        final result = await buildBatch(gateway)();

        final page = result.fold((_) => throw StateError('left'), (r) => r);
        check(
          page.items.map((i) => i.teacherId).toList(),
        ).deepEquals(['t1', 't2', 't3']);
        // Exactly one batch round-trip; the N+1 per-teacher path is untouched.
        check(gateway.batchCallCount).equals(1);
        check(gateway.perTeacherCallCount).equals(0);
      },
    );

    test(
      'applies the same bookability filter to batch-resolved quotes',
      () async {
        repo.teachers = [makeTeacher(id: 't1'), makeTeacher(id: 't2')];
        final gateway = FakeSessionPricingQuoteGateway(
          quotesByTeacher: const {
            't1': _freeQuote,
            't2': _paidUnavailableQuote,
          },
        );
        final result = await buildBatch(gateway)();

        final page = result.fold((_) => throw StateError('left'), (r) => r);
        check(page.items.map((i) => i.teacherId).toList()).deepEquals(['t1']);
        check(gateway.batchCallCount).equals(1);
      },
    );

    test('falls back to per-teacher quotes when the batch call fails', () async {
      repo.teachers = [makeTeacher(id: 't1'), makeTeacher(id: 't2')];
      final gateway = FakeSessionPricingQuoteGateway(
        quote: _freeQuote,
        batchFailure: const NetworkFailure(),
      );
      final result = await buildBatch(gateway)();

      final page = result.fold((_) => throw StateError('left'), (r) => r);
      check(
        page.items.map((i) => i.teacherId).toList(),
      ).deepEquals(['t1', 't2']);
      // Batch was attempted once, then the per-teacher path resolved both ids.
      check(gateway.batchCallCount).equals(1);
      check(gateway.perTeacherCallCount).equals(2);
    });
  });
}
