import 'package:checks/checks.dart';
import 'package:quran_sessions/src/domain/entities/manual_payment_price.dart';
import 'package:quran_sessions/src/domain/entities/session_price.dart';
import 'package:quran_sessions/src/domain/entities/session_pricing_type.dart';
import 'package:quran_sessions/src/presentation/widgets/teacher_list_filter_bar.dart';
import 'package:quran_sessions/src/presentation/widgets/teacher_list_filter_logic.dart';
import 'package:test/test.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('filterTeachersByNameQuery', () {
    test('returns all teachers when query is empty', () {
      final teachers = [
        makeTeacher(id: 't1', displayName: 'Sheikh Ahmed'),
        makeTeacher(id: 't2', displayName: 'Ustad Fatima'),
      ];

      check(filterTeachersByNameQuery(teachers, '')).deepEquals(teachers);
      check(filterTeachersByNameQuery(teachers, '   ')).deepEquals(teachers);
    });

    test('matches display name case-insensitively', () {
      final teachers = [
        makeTeacher(id: 't1', displayName: 'Sheikh Ahmed'),
        makeTeacher(id: 't2', displayName: 'Ustad Fatima'),
      ];

      final filtered = filterTeachersByNameQuery(teachers, 'ahmed');

      check(filtered.length).equals(1);
      check(filtered.single.id).equals('t1');
    });
  });

  group('applyTeacherListClientFilter', () {
    test('paid filter excludes free teachers', () {
      final teachers = [
        makeTeacher(
          id: 'free',
          pricingType: SessionPricingType.free,
          price: null,
        ),
        makeTeacher(
          id: 'paid',
          pricingType: SessionPricingType.fixedPerSession,
          price: const SessionPrice(
            amount: 800,
            currencyCode: 'EGP',
            countryCode: 'EG',
          ),
        ),
      ];

      final filtered = applyTeacherListClientFilter(
        teachers,
        TeacherListFilter.paid,
        const {},
      );

      check(filtered.length).equals(1);
      check(filtered.single.id).equals('paid');
    });

    test(
      'paid filter includes teacher with free type and paid quote price',
      () {
        final teachers = [
          makeTeacher(
            id: 'free',
            pricingType: SessionPricingType.free,
            price: null,
          ),
          makeTeacher(
            id: 'manual',
            pricingType: SessionPricingType.free,
            price: const SessionPrice(
              amount: 125,
              currencyCode: 'EGP',
              countryCode: 'EG',
            ),
            manualPaymentPrice: const ManualPaymentPrice(
              amountMinor: 12500,
              currencyCode: 'EGP',
            ),
          ),
        ];

        final paid = applyTeacherListClientFilter(
          teachers,
          TeacherListFilter.paid,
          const {},
        );
        final free = applyTeacherListClientFilter(
          teachers,
          TeacherListFilter.free,
          const {},
        );

        check(
          paid.map((teacher) => teacher.id).toList(),
        ).deepEquals(['manual']);
        check(free.map((teacher) => teacher.id).toList()).deepEquals(['free']);
      },
    );

    test('budget filter keeps paid teachers under threshold', () {
      final teachers = [
        makeTeacher(
          id: 'cheap',
          pricingType: SessionPricingType.fixedPerSession,
          price: const SessionPrice(
            amount: 300,
            currencyCode: 'EGP',
            countryCode: 'EG',
          ),
        ),
        makeTeacher(
          id: 'expensive',
          pricingType: SessionPricingType.fixedPerSession,
          price: const SessionPrice(
            amount: 900,
            currencyCode: 'EGP',
            countryCode: 'EG',
          ),
        ),
      ];

      final filtered = applyTeacherListClientFilter(
        teachers,
        TeacherListFilter.budget,
        const {},
        budgetPriceThreshold: 500,
      );

      check(filtered.map((teacher) => teacher.id).toList()).deepEquals([
        'cheap',
      ]);
    });
  });
}
