import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/premium/domain/entities/premium_status.dart';
import 'package:tilawa/features/premium/domain/entities/subscription_plan.dart';
import 'package:tilawa/features/premium/domain/usecases/cancel_subscription_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/check_feature_access_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/get_available_plans_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/get_premium_status_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/purchase_subscription_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/restore_subscription_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/start_trial_use_case.dart';
import 'package:tilawa/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:tilawa/features/premium/presentation/bloc/premium_event.dart';
import 'package:tilawa/features/premium/presentation/bloc/premium_state.dart';

import 'premium_bloc_test.mocks.dart';

@GenerateMocks([
  GetPremiumStatusUseCase,
  PurchaseSubscriptionUseCase,
  CancelSubscriptionUseCase,
  RestoreSubscriptionUseCase,
  StartTrialUseCase,
  GetAvailablePlansUseCase,
  CheckFeatureAccessUseCase,
  Storage,
])
void main() {
  late PremiumBloc premiumBloc;
  late MockGetPremiumStatusUseCase mockGetPremiumStatus;
  late MockPurchaseSubscriptionUseCase mockPurchaseSubscription;
  late MockCancelSubscriptionUseCase mockCancelSubscription;
  late MockRestoreSubscriptionUseCase mockRestoreSubscription;
  late MockStartTrialUseCase mockStartTrial;
  late MockGetAvailablePlansUseCase mockGetAvailablePlans;
  late MockCheckFeatureAccessUseCase mockCheckFeatureAccess;
  late MockStorage mockStorage;

  const tStatus = PremiumStatus(
    isPremium: false,
    subscriptionStartDate: null,
    subscriptionEndDate: null,
    subscriptionType: null,
    isTrialUsed: false,
    trialStartDate: null,
    trialEndDate: null,
  );
  final tPlans = <SubscriptionPlan>[];
  const tCanDownload = false;

  setUp(() {
    mockStorage = MockStorage();
    when(mockStorage.read(any)).thenReturn(null);
    when(mockStorage.write(any, any)).thenAnswer((_) async => {});
    when(mockStorage.delete(any)).thenAnswer((_) async => {});
    when(mockStorage.clear()).thenAnswer((_) async => {});
    HydratedBloc.storage = mockStorage;

    mockGetPremiumStatus = MockGetPremiumStatusUseCase();
    mockPurchaseSubscription = MockPurchaseSubscriptionUseCase();
    mockCancelSubscription = MockCancelSubscriptionUseCase();
    mockRestoreSubscription = MockRestoreSubscriptionUseCase();
    mockStartTrial = MockStartTrialUseCase();
    mockGetAvailablePlans = MockGetAvailablePlansUseCase();
    mockCheckFeatureAccess = MockCheckFeatureAccessUseCase();

    // Default stubs
    when(mockGetPremiumStatus()).thenAnswer(
      (_) async => (canDownload: tCanDownload, plans: tPlans, status: tStatus),
    );

    premiumBloc = PremiumBloc(
      mockGetPremiumStatus,
      mockPurchaseSubscription,
      mockCancelSubscription,
      mockRestoreSubscription,
      mockStartTrial,
      mockGetAvailablePlans,
      mockCheckFeatureAccess,
    );
  });

  tearDown(() {
    premiumBloc.close();
  });

  test('initial state should be PremiumInitial', () {
    expect(premiumBloc.state, const PremiumState.initial());
  });

  group('LoadPremiumStatus', () {
    final PremiumStatus tPremiumStatus = tStatus.copyWith(isPremium: true);

    blocTest<PremiumBloc, PremiumState>(
      'emits [PremiumLoading, PremiumLoaded] when successful',
      build: () {
        when(mockGetPremiumStatus()).thenAnswer(
          (_) async =>
              (canDownload: true, plans: tPlans, status: tPremiumStatus),
        );
        return premiumBloc;
      },
      act: (bloc) => bloc.add(const LoadPremiumStatus()),
      expect: () => [
        const PremiumState.loading(),
        PremiumState.loaded(
          status: tPremiumStatus,
          availablePlans: tPlans,
          canDownload: true,
        ),
      ],
    );

    blocTest<PremiumBloc, PremiumState>(
      'emits [PremiumLoading, PremiumError] when failure',
      build: () {
        when(mockGetPremiumStatus()).thenThrow(Exception('Failure'));
        return premiumBloc;
      },
      act: (bloc) => bloc.add(const LoadPremiumStatus()),
      expect: () => [
        const PremiumState.loading(),
        const PremiumState.error(
          message: 'Failed to load premium status: Exception: Failure',
        ),
      ],
    );
  });

  group('PurchaseSubscription', () {
    const tPlanId = 'monthly';

    blocTest<PremiumBloc, PremiumState>(
      'emits [PremiumLoading, PremiumPurchaseSuccess, PremiumLoading, PremiumLoaded] when successful',
      build: () {
        when(mockPurchaseSubscription(tPlanId)).thenAnswer((_) async => true);
        return premiumBloc;
      },
      act: (bloc) =>
          bloc.add(const PremiumEvent.purchaseSubscription(planId: tPlanId)),
      expect: () => [
        const PremiumState.loading(),
        const PremiumState.purchaseSuccess(
          message: 'Subscription purchased successfully!',
        ),
        const PremiumState.loading(), // Triggered by add(LoadPremiumStatus())
        PremiumState.loaded(
          status: tStatus,
          availablePlans: tPlans,
          canDownload: tCanDownload,
        ),
      ],
    );

    blocTest<PremiumBloc, PremiumState>(
      'emits [PremiumLoading, PremiumPurchaseFailed] when failure',
      build: () {
        when(mockPurchaseSubscription(tPlanId)).thenAnswer((_) async => false);
        return premiumBloc;
      },
      act: (bloc) =>
          bloc.add(const PremiumEvent.purchaseSubscription(planId: tPlanId)),
      expect: () => [
        const PremiumState.loading(),
        const PremiumState.purchaseFailed(
          message: 'Failed to purchase subscription. Please try again.',
        ),
      ],
    );
  });

  group('CancelSubscription', () {
    blocTest<PremiumBloc, PremiumState>(
      'emits [PremiumLoading, PremiumPurchaseSuccess, PremiumLoading, PremiumLoaded] when successful',
      build: () {
        when(mockCancelSubscription()).thenAnswer((_) async => true);
        return premiumBloc;
      },
      act: (bloc) => bloc.add(const CancelSubscription()),
      expect: () => [
        const PremiumState.loading(),
        const PremiumState.purchaseSuccess(
          message: 'Subscription canceled successfully.',
        ),
        const PremiumState.loading(),
        PremiumState.loaded(
          status: tStatus,
          availablePlans: tPlans,
          canDownload: tCanDownload,
        ),
      ],
    );
  });

  group('StartTrial', () {
    blocTest<PremiumBloc, PremiumState>(
      'emits [PremiumLoading, PremiumTrialStarted, PremiumLoading, PremiumLoaded] when successful',
      build: () {
        when(
          mockStartTrial(),
        ).thenAnswer((_) async => (isEligible: true, success: true));
        return premiumBloc;
      },
      act: (bloc) => bloc.add(const StartTrial()),
      expect: () => [
        const PremiumState.loading(),
        const PremiumState.trialStarted(
          message: '7-day trial started! Enjoy premium features.',
        ),
        const PremiumState.loading(),
        PremiumState.loaded(
          status: tStatus,
          availablePlans: tPlans,
          canDownload: tCanDownload,
        ),
      ],
    );

    blocTest<PremiumBloc, PremiumState>(
      'emits [PremiumLoading, PremiumTrialNotEligible] when not eligible',
      build: () {
        when(
          mockStartTrial(),
        ).thenAnswer((_) async => (isEligible: false, success: false));
        return premiumBloc;
      },
      act: (bloc) => bloc.add(const StartTrial()),
      expect: () => [
        const PremiumState.loading(),
        const PremiumState.trialNotEligible(
          message:
              'Trial is not available. You may have already used it or have an active subscription.',
        ),
      ],
    );
  });
}
