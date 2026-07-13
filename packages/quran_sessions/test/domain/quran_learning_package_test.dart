import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/quran_learning_package.dart';

StudentPackageCounters counters({
  int issued = 8,
  int available = 8,
  int reserved = 0,
  int consumed = 0,
  int restored = 0,
  int expired = 0,
  int adjustPos = 0,
  int adjustNeg = 0,
}) => StudentPackageCounters(
  issuedCredits: issued,
  availableCredits: available,
  reservedCredits: reserved,
  consumedCredits: consumed,
  restoredCredits: restored,
  expiredCredits: expired,
  adjustPositiveTotal: adjustPos,
  adjustNegativeTotal: adjustNeg,
);

void main() {
  group('StudentPackageCounters.issued', () {
    test('mints n available credits and is consistent', () {
      final c = StudentPackageCounters.issued(8);
      check(c.availableCredits).equals(8);
      check(c.issuedCredits).equals(8);
      check(c.isConsistent).isTrue();
      check(c.isExhausted).isFalse();
    });
  });

  group('conservation invariant', () {
    test('freshly issued balance holds', () {
      check(counters().isConsistent).isTrue();
    });

    test('after one reservation holds', () {
      // reserve: available-1, reserved+1
      check(counters(available: 7, reserved: 1).isConsistent).isTrue();
    });

    test('after reserve+consume holds', () {
      // consume: reserved-1, consumed+1
      check(counters(available: 7, consumed: 1).isConsistent).isTrue();
    });

    test('after reserve+restore holds and tallies restored', () {
      // restore: reserved-1, available+1, restored tally+1
      final c = counters(available: 8, restored: 1);
      check(c.isConsistent).isTrue();
      check(c.restoredCredits).equals(1);
    });

    test('after expiry of remaining credits holds', () {
      // expire(8): available-8, expired+8
      check(counters(available: 0, expired: 8).isExhausted).isTrue();
      check(counters(available: 0, expired: 8).isConsistent).isTrue();
    });

    test('positive adjustment adds an available credit and stays balanced', () {
      // adjust_positive(2): available+2, adjustPositiveTotal+2
      check(counters(available: 10, adjustPos: 2).isConsistent).isTrue();
    });

    test(
      'negative adjustment removes an available credit and stays balanced',
      () {
        // adjust_negative(1): available-1, adjustNegativeTotal+1
        check(counters(available: 7, adjustNeg: 1).isConsistent).isTrue();
      },
    );

    test('sum mismatch is inconsistent', () {
      // available inflated by 1 with no source
      check(counters(available: 9).isConsistent).isFalse();
    });

    test('negative counter is inconsistent', () {
      check(counters(available: -1, reserved: 9).allNonNegative).isFalse();
      check(counters(available: -1, reserved: 9).isConsistent).isFalse();
    });
  });

  group('StudentPackage.canReserve', () {
    final now = DateTime(2026, 7, 11, 12);
    StudentPackage pkg({
      StudentPackageStatus status = StudentPackageStatus.active,
      bool suspended = false,
      int available = 8,
      DateTime? expiresAt,
    }) => StudentPackage(
      packageId: 'pkg_1',
      orderId: 'ord_1',
      planId: 'plan_eg_8',
      learnerId: 'learner_1',
      teacherId: 'teacher_1',
      marketCode: 'EG',
      terms: const PackageTermsSnapshot(
        planId: 'plan_eg_8',
        marketCode: 'EG',
        sessionCount: 8,
        sessionDurationMinutes: 30,
        validityDays: 35,
        cancellationCutoffHours: 12,
        priceMinor: 120000,
        currencyCode: 'EGP',
        compatibilityMeetingAllowance: 1,
        policyVersion: 'v1',
      ),
      counters: counters(available: available, expired: 8 - available),
      status: status,
      version: 1,
      activatedAt: now.subtract(const Duration(days: 1)),
      expiresAt: expiresAt ?? now.add(const Duration(days: 34)),
      policyVersion: 'v1',
      suspended: suspended,
    );

    test('active with credits before expiry can reserve', () {
      check(pkg().canReserve(now)).isTrue();
    });

    test('suspended cannot reserve', () {
      check(pkg(suspended: true).canReserve(now)).isFalse();
    });

    test('exhausted cannot reserve', () {
      check(pkg(available: 0).canReserve(now)).isFalse();
    });

    test('expired window cannot reserve', () {
      check(
        pkg(
          expiresAt: now.subtract(const Duration(minutes: 1)),
        ).canReserve(now),
      ).isFalse();
    });

    test('completed status is not active', () {
      check(pkg(status: StudentPackageStatus.completed).isActive).isFalse();
    });
  });

  group('PackageCreditMovementType', () {
    test('adjustments require privileged actor', () {
      check(
        PackageCreditMovementType.adjustPositive.requiresPrivilegedActor,
      ).isTrue();
      check(
        PackageCreditMovementType.adjustNegative.requiresPrivilegedActor,
      ).isTrue();
      check(
        PackageCreditMovementType.reserve.requiresPrivilegedActor,
      ).isFalse();
    });
  });

  group('PackageTermsSnapshot', () {
    test('exposes major price', () {
      const t = PackageTermsSnapshot(
        planId: 'p',
        marketCode: 'EG',
        sessionCount: 8,
        sessionDurationMinutes: 30,
        validityDays: 35,
        cancellationCutoffHours: 12,
        priceMinor: 120000,
        currencyCode: 'EGP',
        compatibilityMeetingAllowance: 1,
        policyVersion: 'v1',
      );
      check(t.priceMajor).equals(1200.0);
    });
  });
}
