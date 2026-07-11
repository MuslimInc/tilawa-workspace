import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/data/dtos/quran_package_dto.dart';
import 'package:quran_sessions/src/data/mappers/quran_package_mapper.dart';
import 'package:quran_sessions/src/domain/entities/quran_learning_package.dart';
import 'package:quran_sessions/src/domain/failures/quran_package_failure.dart';

Map<String, dynamic> termsJson({
  int priceMinor = 120000,
  int sessionCount = 8,
}) => {
  'plan_id': 'plan_eg_8',
  'market_code': 'EG',
  'session_count': sessionCount,
  'session_duration_minutes': 30,
  'validity_days': 35,
  'cancellation_cutoff_hours': 12,
  'price_minor': priceMinor,
  'currency_code': 'EGP',
  'compatibility_meeting_allowance': 1,
  'policy_version': 'v1',
  'allow_child_learner': false,
};

Map<String, dynamic> countersJson({
  int issued = 8,
  int available = 8,
  int reserved = 0,
  int consumed = 0,
  int restored = 0,
  int expired = 0,
  int adjustPos = 0,
  int adjustNeg = 0,
}) => {
  'issued_credits': issued,
  'available_credits': available,
  'reserved_credits': reserved,
  'consumed_credits': consumed,
  'restored_credits': restored,
  'expired_credits': expired,
  'adjust_positive_total': adjustPos,
  'adjust_negative_total': adjustNeg,
};

Map<String, dynamic> packageJson({
  Map<String, dynamic>? counters,
  String status = 'active',
  int version = 3,
}) => {
  'package_id': 'pkg_1',
  'order_id': 'ord_1',
  'plan_id': 'plan_eg_8',
  'learner_id': 'learner_1',
  'teacher_id': 'teacher_1',
  'market_code': 'EG',
  'terms': termsJson(),
  'counters': counters ?? countersJson(),
  'status': status,
  'version': version,
  'activated_at': '2026-07-10T09:00:00.000Z',
  'expires_at': '2026-08-14T09:00:00.000Z',
  'policy_version': 'v1',
};

void main() {
  group('PackageTermsDto → domain', () {
    test('round-trips a valid terms document', () {
      final dto = PackageTermsDto.fromJson(termsJson());
      final result = dto.toDomain();
      check(result.isRight()).isTrue();
      final terms = result.getOrElse(() => throw StateError('expected Right'));
      check(terms.priceMinor).equals(120000);
      check(terms.sessionCount).equals(8);
      check(terms.marketCode).equals('EG');
    });

    test('rejects negative price as corruption', () {
      final dto = PackageTermsDto.fromJson(termsJson(priceMinor: -1));
      final result = dto.toDomain();
      check(result.isLeft()).isTrue();
      result.fold(
        (f) =>
            check(f).isA<PackageDataCorruptionFailure>()
              ..has((c) => c.detail, 'detail').equals('negative_price'),
        (_) => throw StateError('expected Left'),
      );
    });

    test('rejects non-positive session count', () {
      final dto = PackageTermsDto.fromJson(termsJson(sessionCount: 0));
      check(dto.toDomain().isLeft()).isTrue();
    });
  });

  group('StudentPackageDto → domain', () {
    test('maps a consistent package', () {
      final dto = StudentPackageDto.fromJson(
        packageJson(
          counters: countersJson(available: 7, consumed: 1),
        ),
      );
      final result = dto.toDomain();
      check(result.isRight()).isTrue();
      final pkg = result.getOrElse(() => throw StateError('expected Right'));
      check(pkg.status).equals(StudentPackageStatus.active);
      check(pkg.counters.availableCredits).equals(7);
      check(pkg.version).equals(3);
    });

    test('rejects inconsistent counters (invariant violation)', () {
      final dto = StudentPackageDto.fromJson(
        packageJson(
          // available inflated with no matching source
          counters: countersJson(available: 9),
        ),
      );
      final result = dto.toDomain();
      check(result.isLeft()).isTrue();
      result.fold(
        (f) =>
            check(f).isA<PackageDataCorruptionFailure>()
              ..has((c) => c.detail, 'detail').equals('invariant_violation'),
        (_) => throw StateError('expected Left'),
      );
    });

    test('rejects negative counters', () {
      final dto = StudentPackageDto.fromJson(
        packageJson(
          counters: countersJson(available: -1, reserved: 9),
        ),
      );
      final result = dto.toDomain();
      check(result.isLeft()).isTrue();
      result.fold(
        (f) =>
            check(f).isA<PackageDataCorruptionFailure>()
              ..has((c) => c.detail, 'detail').equals('negative_counter'),
        (_) => throw StateError('expected Left'),
      );
    });

    test('rejects unknown status', () {
      final dto = StudentPackageDto.fromJson(packageJson(status: 'frozen'));
      final result = dto.toDomain();
      check(result.isLeft()).isTrue();
      result.fold(
        (f) =>
            check(f).isA<PackageDataCorruptionFailure>()
              ..has((c) => c.detail, 'detail').startsWith('unknown_status'),
        (_) => throw StateError('expected Left'),
      );
    });

    test('rejects negative version', () {
      final dto = StudentPackageDto.fromJson(packageJson(version: -1));
      check(dto.toDomain().isLeft()).isTrue();
    });
  });

  group('PackageCreditMovementDto → domain', () {
    Map<String, dynamic> movementJson({String type = 'reserve', int qty = 1}) =>
        {
          'movement_id': 'mv_1',
          'package_id': 'pkg_1',
          'type': type,
          'quantity': qty,
          'reason_code': 'booking_created',
          'policy_version': 'v1',
          'created_at': '2026-07-11T10:00:00.000Z',
          'booking_id': 'bk_1',
        };

    test('maps each known movement type', () {
      for (final t in [
        'issue',
        'reserve',
        'consume',
        'restore',
        'expire',
        'adjust_positive',
        'adjust_negative',
      ]) {
        final dto = PackageCreditMovementDto.fromJson(movementJson(type: t));
        check(dto.toDomain().isRight(), because: t).isTrue();
      }
    });

    test('rejects unknown movement type', () {
      final dto = PackageCreditMovementDto.fromJson(movementJson(type: 'burn'));
      check(dto.toDomain().isLeft()).isTrue();
    });

    test('rejects non-positive quantity', () {
      final dto = PackageCreditMovementDto.fromJson(movementJson(qty: 0));
      check(dto.toDomain().isLeft()).isTrue();
    });
  });

  group('PackageOrderDto → domain', () {
    test('maps a pending order', () {
      final dto = PackageOrderDto.fromJson({
        'order_id': 'ord_1',
        'plan_id': 'plan_eg_8',
        'learner_id': 'learner_1',
        'teacher_id': 'teacher_1',
        'market_code': 'EG',
        'terms': termsJson(),
        'payment_instruction': {
          'instruction_version': 'v1',
          'method_code': 'instapay',
          'display_instructions': 'Send to ...',
          'payment_reference': 'REF-123',
        },
        'status': 'pending_payment',
        'created_at': '2026-07-11T10:00:00.000Z',
        'expires_at': '2026-07-12T10:00:00.000Z',
      });
      final result = dto.toDomain();
      check(result.isRight()).isTrue();
      final order = result.getOrElse(() => throw StateError('expected Right'));
      check(order.isPending).isTrue();
      check(order.paymentInstruction.paymentReference).equals('REF-123');
    });
  });
}
