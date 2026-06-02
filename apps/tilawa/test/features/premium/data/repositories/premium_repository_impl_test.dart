import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/premium/data/datasources/premium_local_datasource.dart';
import 'package:tilawa/features/premium/data/datasources/premium_remote_datasource.dart';
import 'package:tilawa/features/premium/data/repositories/premium_repository_impl.dart';
import 'package:tilawa/features/premium/domain/entities/premium_status.dart';
import 'package:tilawa/features/premium/domain/entities/subscription_plan.dart';

import 'premium_repository_impl_test.mocks.dart';

@GenerateMocks([PremiumLocalDataSource, PremiumRemoteDataSource])
void main() {
  late PremiumRepositoryImpl repository;
  late MockPremiumLocalDataSource mockLocalDataSource;
  late MockPremiumRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockLocalDataSource = MockPremiumLocalDataSource();
    mockRemoteDataSource = MockPremiumRemoteDataSource();
    repository = PremiumRepositoryImpl(
      mockLocalDataSource,
      mockRemoteDataSource,
    );
  });

  final tPremiumStatus = PremiumStatus(
    isPremium: true,
    subscriptionStartDate: DateTime.now(),
    subscriptionEndDate: DateTime.now().add(const Duration(days: 30)),
    subscriptionType: 'monthly',
    isTrialUsed: false,
    trialStartDate: null,
    trialEndDate: null,
  );

  final tPlans = [
    const SubscriptionPlan(
      id: 'monthly',
      name: 'Test Plan',
      description: 'Test Description',
      price: 9.99,
      currency: 'USD',
      type: SubscriptionType.monthly,
      durationInDays: 30,
      features: [],
      isPopular: false,
      discountPercentage: null,
    ),
  ];

  group('getPremiumStatus', () {
    test(
      'should return remote status and save it locally when remote is successful',
      () async {
        // Arrange
        when(
          mockRemoteDataSource.getPremiumStatus(),
        ).thenAnswer((_) async => tPremiumStatus);
        when(
          mockLocalDataSource.savePremiumStatus(any),
        ).thenAnswer((_) async => {});

        // Act
        final PremiumStatus result = await repository.getPremiumStatus();

        // Assert
        expect(result, tPremiumStatus);
        verify(mockRemoteDataSource.getPremiumStatus()).called(1);
        verify(mockLocalDataSource.savePremiumStatus(tPremiumStatus)).called(1);
      },
    );

    test('should return local status when remote fails', () async {
      // Arrange
      when(
        mockRemoteDataSource.getPremiumStatus(),
      ).thenThrow(Exception('Remote failure'));
      when(
        mockLocalDataSource.getPremiumStatus(),
      ).thenAnswer((_) async => tPremiumStatus);

      // Act
      final PremiumStatus result = await repository.getPremiumStatus();

      // Assert
      expect(result, tPremiumStatus);
      verify(mockRemoteDataSource.getPremiumStatus()).called(1);
      verify(mockLocalDataSource.getPremiumStatus()).called(1);
    });
  });

  group('getAvailablePlans', () {
    test('should return remote plans when remote is successful', () async {
      // Arrange
      when(
        mockRemoteDataSource.getAvailablePlans(),
      ).thenAnswer((_) async => tPlans);

      // Act
      final List<SubscriptionPlan> result = await repository.getAvailablePlans();

      // Assert
      expect(result, tPlans);
      verify(mockRemoteDataSource.getAvailablePlans()).called(1);
    });

    test('should return default plans when remote fails', () async {
      // Arrange
      when(
        mockRemoteDataSource.getAvailablePlans(),
      ).thenThrow(Exception('Remote failure'));

      // Act
      final List<SubscriptionPlan> result = await repository.getAvailablePlans();

      // Assert
      expect(result.length, 3); // 3 default plans
      verify(mockRemoteDataSource.getAvailablePlans()).called(1);
    });
  });

  group('purchaseSubscription', () {
    const tPlanId = 'monthly';

    test('should propagate UnsupportedError from datasource', () async {
      // purchaseSubscription in the remote datasource throws UnsupportedError
      // to enforce that all purchases must go through Play Billing. The repo
      // delegates directly so the error surfaces to the caller.
      when(
        mockRemoteDataSource.purchaseSubscription(tPlanId),
      ).thenThrow(UnsupportedError('Must use Play Billing'));

      expect(
        () => repository.purchaseSubscription(tPlanId),
        throwsUnsupportedError,
      );
      verify(mockRemoteDataSource.purchaseSubscription(tPlanId)).called(1);
    });
  });

  group('restoreSubscription', () {
    test('should propagate UnsupportedError from datasource', () async {
      // restoreSubscription must go through Play Billing's restorePurchases().
      when(
        mockRemoteDataSource.restoreSubscription(),
      ).thenThrow(UnsupportedError('Must use Play Billing'));

      expect(
        () => repository.restoreSubscription(),
        throwsUnsupportedError,
      );
      verify(mockRemoteDataSource.restoreSubscription()).called(1);
    });
  });

  group('startTrial', () {
    const tPremiumStatus = PremiumStatus(
      isPremium: false,
      subscriptionStartDate: null,
      subscriptionEndDate: null,
      subscriptionType: null,
      isTrialUsed: false,
      trialStartDate: null,
      trialEndDate: null,
    );

    test(
      'should return true and update status when trial is started',
      () async {
        // Arrange
        when(
          mockRemoteDataSource.getPremiumStatus(),
        ).thenAnswer((_) async => tPremiumStatus);
        when(
          mockLocalDataSource.getPremiumStatus(),
        ).thenAnswer((_) async => tPremiumStatus);
        when(
          mockLocalDataSource.savePremiumStatus(any),
        ).thenAnswer((_) async => {});
        when(
          mockRemoteDataSource.updatePremiumStatus(any),
        ).thenAnswer((_) async => {});
        when(
          mockRemoteDataSource.getAvailablePlans(),
        ).thenAnswer((_) async => []);

        // Act
        final bool result = await repository.startTrial();

        // Assert
        expect(result, true);
        // Called once in getPremiumStatus and once in updatePremiumStatus
        verify(mockLocalDataSource.savePremiumStatus(any)).called(2);
      },
    );

    test('should return false when trial already used', () async {
      // Arrange
      final tUsedTrialStatus = PremiumStatus(
        isPremium: false,
        subscriptionStartDate: null,
        subscriptionEndDate: null,
        subscriptionType: null,
        isTrialUsed: true,
        trialStartDate: DateTime.now(),
        trialEndDate: DateTime.now().add(const Duration(days: 7)),
      );
      // Force fallback to local to avoid savePremiumStatus call in getPremiumStatus
      when(
        mockRemoteDataSource.getPremiumStatus(),
      ).thenAnswer((_) async => null);
      when(
        mockLocalDataSource.getPremiumStatus(),
      ).thenAnswer((_) async => tUsedTrialStatus);

      // Act
      final bool result = await repository.startTrial();

      // Assert
      expect(result, false);
      verifyNever(mockLocalDataSource.savePremiumStatus(any));
    });

    test('should return false when exception occurs', () async {
      // Arrange
      when(
        mockRemoteDataSource.getPremiumStatus(),
      ).thenThrow(Exception('Remote failure'));
      when(
        mockLocalDataSource.getPremiumStatus(),
      ).thenThrow(Exception('Local failure'));

      // Act
      final bool result = await repository.startTrial();

      // Assert
      expect(result, false);
    });
  });

  group('updatePremiumStatus', () {
    final tPremiumStatus = PremiumStatus(
      isPremium: true,
      subscriptionStartDate: DateTime.now(),
      subscriptionEndDate: DateTime.now().add(const Duration(days: 30)),
      subscriptionType: 'monthly',
      isTrialUsed: false,
      trialStartDate: null,
      trialEndDate: null,
    );

    test('should swallow exception when remote update fails', () async {
      // Arrange
      when(
        mockLocalDataSource.savePremiumStatus(any),
      ).thenAnswer((_) async => {});
      when(
        mockRemoteDataSource.updatePremiumStatus(any),
      ).thenThrow(Exception('Remote update failed'));

      // Act
      await repository.updatePremiumStatus(tPremiumStatus);

      // Assert
      verify(mockLocalDataSource.savePremiumStatus(tPremiumStatus)).called(1);
      verify(
        mockRemoteDataSource.updatePremiumStatus(tPremiumStatus),
      ).called(1);
    });
  });

  group('getPlanById', () {
    final tPlans = [
      const SubscriptionPlan(
        id: 'monthly',
        name: 'Monthly Premium',
        description: 'Test',
        price: 4.99,
        currency: 'USD',
        type: SubscriptionType.monthly,
        durationInDays: 30,
        features: [],
        isPopular: false,
        discountPercentage: null,
      ),
    ];

    test('should return plan by id', () async {
      // Arrange
      when(
        mockRemoteDataSource.getAvailablePlans(),
      ).thenAnswer((_) async => tPlans);

      // Act
      final SubscriptionPlan result = await repository.getPlanById('monthly');

      // Assert
      expect(result, tPlans.first);
    });
  });

  group('cancelSubscription', () {
    const tPremiumStatus = PremiumStatus(
      isPremium: true,
      subscriptionStartDate: null,
      subscriptionEndDate: null,
      subscriptionType: 'monthly',
      isTrialUsed: false,
      trialStartDate: null,
      trialEndDate: null,
    );

    test(
      'should return true and update local status when successful',
      () async {
        // Arrange
        when(
          mockRemoteDataSource.cancelSubscription(),
        ).thenAnswer((_) async => true);
        when(
          mockRemoteDataSource.getPremiumStatus(),
        ).thenAnswer((_) async => tPremiumStatus);
        when(
          mockLocalDataSource.getPremiumStatus(),
        ).thenAnswer((_) async => tPremiumStatus);
        when(
          mockLocalDataSource.savePremiumStatus(any),
        ).thenAnswer((_) async => {});
        when(
          mockRemoteDataSource.updatePremiumStatus(any),
        ).thenAnswer((_) async => {});
        when(
          mockRemoteDataSource.getAvailablePlans(),
        ).thenAnswer((_) async => []);

        // Act
        final bool result = await repository.cancelSubscription();

        // Assert
        expect(result, true);
        verify(mockRemoteDataSource.cancelSubscription()).called(1);
        verify(mockLocalDataSource.savePremiumStatus(any)).called(2);
      },
    );

    test('should return false when remote returns false', () async {
      // Arrange
      when(
        mockRemoteDataSource.cancelSubscription(),
      ).thenAnswer((_) async => false);

      // Act
      final bool result = await repository.cancelSubscription();

      // Assert
      expect(result, false);
      verify(mockRemoteDataSource.cancelSubscription()).called(1);
      verifyNever(mockLocalDataSource.savePremiumStatus(any));
    });

    test('should return false when exception occurs', () async {
      // Arrange
      when(
        mockRemoteDataSource.cancelSubscription(),
      ).thenThrow(Exception('Cancel failed'));

      // Act
      final bool result = await repository.cancelSubscription();

      // Assert
      expect(result, false);
    });
  });

  group('isTrialEligible', () {
    test('should return true when trial not used and no active sub', () async {
      // Arrange
      const tStatus = PremiumStatus(
        isPremium: false,
        subscriptionStartDate: null,
        subscriptionEndDate: null,
        subscriptionType: null,
        isTrialUsed: false,
        trialStartDate: null,
        trialEndDate: null,
      );
      when(
        mockRemoteDataSource.getPremiumStatus(),
      ).thenAnswer((_) async => null);
      when(
        mockLocalDataSource.getPremiumStatus(),
      ).thenAnswer((_) async => tStatus);

      // Act
      final bool result = await repository.isTrialEligible();

      // Assert
      expect(result, true);
    });

    test('should return false when trial used', () async {
      // Arrange
      const tStatus = PremiumStatus(
        isPremium: false,
        subscriptionStartDate: null,
        subscriptionEndDate: null,
        subscriptionType: null,
        isTrialUsed: true,
        trialStartDate: null,
        trialEndDate: null,
      );
      when(
        mockRemoteDataSource.getPremiumStatus(),
      ).thenAnswer((_) async => null);
      when(
        mockLocalDataSource.getPremiumStatus(),
      ).thenAnswer((_) async => tStatus);

      // Act
      final bool result = await repository.isTrialEligible();

      // Assert
      expect(result, false);
    });

    test('should return false when subscription active', () async {
      // Arrange
      final tStatus = PremiumStatus(
        isPremium: true,
        subscriptionStartDate: DateTime.now(),
        subscriptionEndDate: DateTime.now().add(const Duration(days: 30)),
        subscriptionType: 'monthly',
        isTrialUsed: false,
        trialStartDate: null,
        trialEndDate: null,
      );
      when(
        mockRemoteDataSource.getPremiumStatus(),
      ).thenAnswer((_) async => null);
      when(
        mockLocalDataSource.getPremiumStatus(),
      ).thenAnswer((_) async => tStatus);

      // Act
      final bool result = await repository.isTrialEligible();

      // Assert
      expect(result, false);
    });
  });

  group('canAccessFeature', () {
    test('should return true for non-premium feature', () async {
      // Act
      final bool result = await repository.canAccessFeature('basic_feature');

      // Assert
      expect(result, true);
      verifyNever(mockRemoteDataSource.getPremiumStatus());
    });

    test('should return true for worship utility feature regardless of status',
        () async {
      // Act
      final bool result = await repository.canAccessFeature('download');

      // Assert
      expect(result, true);
    });
  });

  group('canDownload', () {
    test('should allow download without premium gating', () async {
      // Act
      final bool result = await repository.canDownload();

      // Assert
      expect(result, true);
      verifyNever(mockRemoteDataSource.getPremiumStatus());
      verifyNever(mockLocalDataSource.getPremiumStatus());
    });
  });

  group('getPremiumFeatures', () {
    test('should return correct list of features', () {
      // Act
      final List<String> result = repository.getPremiumFeatures();

      // Assert
      expect(result.length, 6);
      expect(result, contains('Unlimited Downloads'));
      expect(result, contains('Offline Mode'));
    });
  });
}
