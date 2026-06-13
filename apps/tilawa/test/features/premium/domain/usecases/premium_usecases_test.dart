import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/premium/domain/entities/premium_status.dart';
import 'package:tilawa/features/premium/domain/entities/subscription_plan.dart';
import 'package:tilawa/features/premium/domain/repositories/premium_repository.dart';
import 'package:tilawa/features/premium/domain/usecases/cancel_subscription_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/get_available_plans_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/get_premium_status_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/purchase_subscription_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/restore_subscription_use_case.dart';
import 'package:tilawa/features/premium/domain/usecases/start_trial_use_case.dart';

import 'premium_usecases_test.mocks.dart';

@GenerateMocks([PremiumRepository])
void main() {
  late MockPremiumRepository mockRepository;

  setUp(() {
    mockRepository = MockPremiumRepository();
  });

  group('CancelSubscriptionUseCase', () {
    test('returns repository result on success', () async {
      when(
        mockRepository.cancelSubscription(),
      ).thenAnswer((_) async => true);

      final result = await CancelSubscriptionUseCase(mockRepository)();

      expect(result, isTrue);
      verify(mockRepository.cancelSubscription()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('returns false when repository reports failure', () async {
      when(
        mockRepository.cancelSubscription(),
      ).thenAnswer((_) async => false);

      final result = await CancelSubscriptionUseCase(mockRepository)();

      expect(result, isFalse);
    });
  });

  group('GetAvailablePlansUseCase', () {
    test('returns the list from the repository', () async {
      const plans = [
        SubscriptionPlan(
          id: 'monthly',
          name: 'Monthly',
          description: 'Monthly plan',
          price: 4.99,
          currency: 'USD',
          type: SubscriptionType.monthly,
          durationInDays: 30,
          features: ['downloads'],
          isPopular: false,
          discountPercentage: null,
        ),
      ];
      when(
        mockRepository.getAvailablePlans(),
      ).thenAnswer((_) async => plans);

      final result = await GetAvailablePlansUseCase(mockRepository)();

      expect(result, plans);
      verify(mockRepository.getAvailablePlans()).called(1);
    });

    test('returns empty list when no plans are available', () async {
      when(
        mockRepository.getAvailablePlans(),
      ).thenAnswer((_) async => <SubscriptionPlan>[]);

      final result = await GetAvailablePlansUseCase(mockRepository)();

      expect(result, isEmpty);
    });
  });

  group('GetPremiumStatusUseCase', () {
    const status = PremiumStatus(
      isPremium: true,
      subscriptionStartDate: null,
      subscriptionEndDate: null,
      subscriptionType: 'monthly',
      isTrialUsed: false,
      trialStartDate: null,
      trialEndDate: null,
    );
    const plans = <SubscriptionPlan>[];

    test(
      'composes status, plans, and canDownload into a single record',
      () async {
        when(
          mockRepository.getPremiumStatus(),
        ).thenAnswer((_) async => status);
        when(
          mockRepository.getAvailablePlans(),
        ).thenAnswer((_) async => plans);
        when(
          mockRepository.canDownload(),
        ).thenAnswer((_) async => true);

        final result = await GetPremiumStatusUseCase(mockRepository)();

        expect(result.status, status);
        expect(result.plans, plans);
        expect(result.canDownload, isTrue);

        verify(mockRepository.getPremiumStatus()).called(1);
        verify(mockRepository.getAvailablePlans()).called(1);
        verify(mockRepository.canDownload()).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test('returns canDownload=false when repository says so', () async {
      when(
        mockRepository.getPremiumStatus(),
      ).thenAnswer((_) async => status);
      when(
        mockRepository.getAvailablePlans(),
      ).thenAnswer((_) async => plans);
      when(
        mockRepository.canDownload(),
      ).thenAnswer((_) async => false);

      final result = await GetPremiumStatusUseCase(mockRepository)();

      expect(result.canDownload, isFalse);
    });
  });

  group('PurchaseSubscriptionUseCase', () {
    test('forwards planId to repository and returns its result', () async {
      when(
        mockRepository.purchaseSubscription(any),
      ).thenAnswer((_) async => true);

      final result = await PurchaseSubscriptionUseCase(mockRepository)(
        'monthly',
      );

      expect(result, isTrue);
      verify(mockRepository.purchaseSubscription('monthly')).called(1);
    });

    test('returns false when purchase fails', () async {
      when(
        mockRepository.purchaseSubscription(any),
      ).thenAnswer((_) async => false);

      final result = await PurchaseSubscriptionUseCase(mockRepository)(
        'yearly',
      );

      expect(result, isFalse);
    });
  });

  group('RestoreSubscriptionUseCase', () {
    test('returns repository result on success', () async {
      when(
        mockRepository.restoreSubscription(),
      ).thenAnswer((_) async => true);

      final result = await RestoreSubscriptionUseCase(mockRepository)();

      expect(result, isTrue);
      verify(mockRepository.restoreSubscription()).called(1);
    });

    test('returns false when nothing to restore', () async {
      when(
        mockRepository.restoreSubscription(),
      ).thenAnswer((_) async => false);

      final result = await RestoreSubscriptionUseCase(mockRepository)();

      expect(result, isFalse);
    });
  });

  group('StartTrialUseCase', () {
    test(
      'skips startTrial and reports ineligibility when not eligible',
      () async {
        when(
          mockRepository.isTrialEligible(),
        ).thenAnswer((_) async => false);

        final result = await StartTrialUseCase(mockRepository)();

        expect(result.isEligible, isFalse);
        expect(result.success, isFalse);

        verify(mockRepository.isTrialEligible()).called(1);
        // Crucial: we must NOT call startTrial when ineligible.
        verifyNever(mockRepository.startTrial());
      },
    );

    test('calls startTrial when eligible and reports its result', () async {
      when(
        mockRepository.isTrialEligible(),
      ).thenAnswer((_) async => true);
      when(
        mockRepository.startTrial(),
      ).thenAnswer((_) async => true);

      final result = await StartTrialUseCase(mockRepository)();

      expect(result.isEligible, isTrue);
      expect(result.success, isTrue);

      verify(mockRepository.isTrialEligible()).called(1);
      verify(mockRepository.startTrial()).called(1);
    });

    test('reports success=false when eligible but startTrial fails', () async {
      when(
        mockRepository.isTrialEligible(),
      ).thenAnswer((_) async => true);
      when(
        mockRepository.startTrial(),
      ).thenAnswer((_) async => false);

      final result = await StartTrialUseCase(mockRepository)();

      expect(result.isEligible, isTrue);
      expect(result.success, isFalse);
    });
  });
}
