import 'package:bloc_test/bloc_test.dart';
import 'package:checks/checks.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/entities/quran_learning_package.dart';
import 'package:quran_sessions/src/domain/failures/quran_package_failure.dart';
import 'package:quran_sessions/src/domain/repositories/quran_package_repository.dart';
import 'package:quran_sessions/src/domain/usecases/quran_package_order_usecases.dart';
import 'package:quran_sessions/src/presentation/blocs/package_order/package_order_bloc.dart';
import 'package:quran_sessions/src/presentation/blocs/package_order/package_order_event.dart';
import 'package:quran_sessions/src/presentation/blocs/package_order/package_order_state.dart';

const _terms = PackageTermsSnapshot(
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
);

const _instruction = PackagePaymentInstructionSnapshot(
  instructionVersion: 'v1',
  methodCode: 'instapay',
  displayInstructions: 'Send to ...',
  paymentReference: 'REF-1',
);

PackagePlan _plan() => PackagePlan(
  planId: 'plan_eg_8',
  marketCode: 'EG',
  localizedName: const {'en': 'Egypt 8-session'},
  localizedDescription: const {'en': '...'},
  terms: _terms,
  status: PackagePlanStatus.active,
  eligibleTeacherIds: const ['teacher_1'],
  policyVersion: 'v1',
  updatedAt: DateTime(2026, 7, 1),
);

PackageOrder _order({
  PackageOrderStatus status = PackageOrderStatus.pendingPayment,
}) => PackageOrder(
  orderId: 'ord_1',
  planId: 'plan_eg_8',
  learnerId: 'learner_1',
  teacherId: 'teacher_1',
  marketCode: 'EG',
  terms: _terms,
  paymentInstruction: _instruction,
  status: status,
  createdAt: DateTime(2026, 7, 11, 10),
  expiresAt: DateTime(2026, 7, 12, 10),
);

/// Configurable fake implementing both the read repository and command gateway.
class _FakePackageBackend
    implements QuranPackageRepository, QuranPackageCommandGateway {
  Either<QuranPackageFailure, List<PackagePlan>> plansResult = Right([_plan()]);
  Either<QuranPackageFailure, PackageOrder> createResult = Right(_order());
  Either<QuranPackageFailure, PackageOrder> cancelResult = Right(
    _order(status: PackageOrderStatus.cancelled),
  );
  Either<QuranPackageFailure, PackageOrder> orderResult = Right(_order());

  @override
  Future<Either<QuranPackageFailure, List<PackagePlan>>> getPurchasablePlans({
    required String marketCode,
  }) async => plansResult;

  @override
  Future<Either<QuranPackageFailure, PackageOrder>> createOrder({
    required String planId,
    required String teacherId,
    String? learnerId,
    String? compatibilityMeetingId,
    required String idempotencyKey,
  }) async => createResult;

  @override
  Future<Either<QuranPackageFailure, PackageOrder>> cancelOrder({
    required String orderId,
    required String reason,
    required String idempotencyKey,
  }) async => cancelResult;

  @override
  Future<Either<QuranPackageFailure, PackageOrder>> getOrder(
    String orderId,
  ) async => orderResult;

  // Unused read methods for this flow.
  @override
  Future<Either<QuranPackageFailure, PackagePlan>> getPlan(
    String planId,
  ) async => Right(_plan());
  @override
  Future<Either<QuranPackageFailure, StudentPackage>> getPackage(String id) =>
      throw UnimplementedError();
  @override
  Future<Either<QuranPackageFailure, List<StudentPackage>>> getLearnerPackages(
    String learnerId,
  ) => throw UnimplementedError();
  @override
  Future<Either<QuranPackageFailure, PackageActivityPage>> getPackageActivity(
    String packageId, {
    int limit = 20,
    String? startAfterMovementId,
  }) => throw UnimplementedError();
  @override
  Future<Either<QuranPackageFailure, List<PackageOrder>>> getLearnerOrders(
    String learnerId,
  ) => throw UnimplementedError();
  @override
  Future<Either<QuranPackageFailure, PackageBookingResult>> createBooking({
    required String packageId,
    required String slotId,
    required String requestedCallTypeId,
    String? note,
    required String idempotencyKey,
  }) => throw UnimplementedError();
}

PackageOrderBloc _buildBloc(_FakePackageBackend backend) => PackageOrderBloc(
  getPlans: GetPurchasablePackagePlansUseCase(backend),
  createOrder: CreateQuranPackageOrderUseCase(backend),
  cancelOrder: CancelQuranPackageOrderUseCase(backend),
  refreshOrder: RefreshQuranPackageOrderUseCase(backend),
);

void main() {
  group('PackageOrderBloc', () {
    late _FakePackageBackend backend;

    setUp(() => backend = _FakePackageBackend());

    blocTest<PackageOrderBloc, PackageOrderState>(
      'loads purchasable plans',
      build: () => _buildBloc(backend),
      act: (b) => b.add(const PackagePlansRequested(marketCode: 'EG')),
      expect: () => [
        const PackagePlansLoading(),
        isA<PackagePlansLoaded>(),
      ],
    );

    blocTest<PackageOrderBloc, PackageOrderState>(
      'submitting a valid order yields pending payment (balance hidden)',
      build: () => _buildBloc(backend),
      act: (b) => b.add(
        const PackageOrderSubmitted(
          planId: 'plan_eg_8',
          teacherId: 'teacher_1',
          idempotencyKey: 'idem-1',
        ),
      ),
      expect: () => [
        const PackageOrderSubmitting(),
        isA<PackageOrderPendingPayment>(),
      ],
    );

    blocTest<PackageOrderBloc, PackageOrderState>(
      'refresh reflecting admin confirmation resolves the order',
      build: () {
        backend.orderResult = Right(
          _order(status: PackageOrderStatus.confirmed),
        );
        return _buildBloc(backend);
      },
      act: (b) => b.add(const PackageOrderRefreshed(orderId: 'ord_1')),
      verify: (b) {
        final state = b.state;
        check(state).isA<PackageOrderResolved>()
          ..has((s) => s.isConfirmed, 'isConfirmed').isTrue();
      },
    );

    blocTest<PackageOrderBloc, PackageOrderState>(
      'order conflict surfaces a failure state',
      build: () {
        backend.createResult = const Left(
          PackageOrderConflictFailure(existingOrderId: 'ord_old'),
        );
        return _buildBloc(backend);
      },
      act: (b) => b.add(
        const PackageOrderSubmitted(
          planId: 'plan_eg_8',
          teacherId: 'teacher_1',
          idempotencyKey: 'idem-2',
        ),
      ),
      expect: () => [
        const PackageOrderSubmitting(),
        isA<PackageOrderFailure>(),
      ],
    );

    blocTest<PackageOrderBloc, PackageOrderState>(
      'cancelling a pending order resolves it as cancelled',
      build: () => _buildBloc(backend),
      act: (b) => b.add(
        const PackageOrderCancelled(
          orderId: 'ord_1',
          reason: 'changed_mind',
          idempotencyKey: 'idem-3',
        ),
      ),
      verify: (b) {
        check(b.state).isA<PackageOrderResolved>()
          ..has((s) => s.isConfirmed, 'isConfirmed').isFalse();
      },
    );
  });
}
