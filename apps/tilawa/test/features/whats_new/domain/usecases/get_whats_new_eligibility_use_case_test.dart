import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:tilawa/features/onboarding/domain/usecases/check_onboarding_status.dart';
import 'package:tilawa/features/whats_new/domain/entities/changelog_release.dart';
import 'package:tilawa/features/whats_new/domain/entities/whats_new_eligibility.dart';
import 'package:tilawa/features/whats_new/domain/repositories/changelog_repository.dart';
import 'package:tilawa/features/whats_new/domain/repositories/whats_new_progress_repository.dart';
import 'package:tilawa/features/whats_new/domain/usecases/get_current_changelog_release_use_case.dart';
import 'package:tilawa/features/whats_new/domain/usecases/get_whats_new_eligibility_use_case.dart';
import 'package:tilawa_core/errors/failures.dart';

class _FakeProgressRepository implements WhatsNewProgressRepository {
  String? lastSeen;

  @override
  Future<void> clearProgress() async {
    lastSeen = null;
  }

  @override
  Future<String?> getLastSeenReleaseId() async => lastSeen;

  @override
  Future<void> markReleaseSeen(String releaseId) async {
    lastSeen = releaseId;
  }
}

class _FakeChangelogRepository implements ChangelogRepository {
  _FakeChangelogRepository(this.release);

  final ChangelogRelease? release;

  @override
  Future<Either<Failure, ChangelogRelease>> getReleaseForCurrentApp() async {
    if (release == null) {
      return const Left(CacheFailure('missing'));
    }
    return Right(release!);
  }
}

class _FakeOnboardingRepository implements OnboardingRepository {
  _FakeOnboardingRepository(this.completed);

  final bool completed;

  @override
  Future<bool> isOnboardingCompleted() async => completed;

  @override
  Future<void> completeOnboarding() async {}
}

void main() {
  const ChangelogRelease release = ChangelogRelease(
    id: '2.0.8+52',
    version: '2.0.8',
    buildNumber: 52,
    highlightsByLocale: <String, List<String>>{
      'en': <String>['Highlight'],
    },
  );

  late _FakeProgressRepository progress;
  late _FakeOnboardingRepository onboardingRepository;

  GetWhatsNewEligibilityUseCase buildUseCase({
    ChangelogRelease? currentRelease,
  }) {
    return GetWhatsNewEligibilityUseCase(
      GetCurrentChangelogReleaseUseCase(
        _FakeChangelogRepository(currentRelease),
      ),
      progress,
      CheckOnboardingStatus(onboardingRepository),
    );
  }

  setUp(() {
    progress = _FakeProgressRepository();
    onboardingRepository = _FakeOnboardingRepository(true);
  });

  group('GetWhatsNewEligibilityUseCase', () {
    test('shows when release is unseen on home route', () async {
      final result = await buildUseCase(currentRelease: release).call(
        currentRoutePath: '/',
        sacredFlowBlocked: false,
        sessionAlreadyShown: false,
      );

      expect(result.shouldShow, isTrue);
      expect(result.release?.id, '2.0.8+52');
    });

    test('skips when already seen', () async {
      progress.lastSeen = '2.0.8+52';

      final result = await buildUseCase(currentRelease: release).call(
        currentRoutePath: '/',
        sacredFlowBlocked: false,
        sessionAlreadyShown: false,
      );

      expect(result.skipReason, WhatsNewSkipReason.alreadySeen);
    });

    test('skips on onboarding route', () async {
      final result = await buildUseCase(currentRelease: release).call(
        currentRoutePath: '/language-welcome',
        sacredFlowBlocked: false,
        sessionAlreadyShown: false,
      );

      expect(result.skipReason, WhatsNewSkipReason.blockedRoute);
    });

    test('skips during sacred flow', () async {
      final result = await buildUseCase(currentRelease: release).call(
        currentRoutePath: '/',
        sacredFlowBlocked: true,
        sessionAlreadyShown: false,
      );

      expect(result.skipReason, WhatsNewSkipReason.sacredFlow);
    });

    test('skips when onboarding is incomplete', () async {
      onboardingRepository = _FakeOnboardingRepository(false);

      final result = await buildUseCase(currentRelease: release).call(
        currentRoutePath: '/',
        sacredFlowBlocked: false,
        sessionAlreadyShown: false,
      );

      expect(result.skipReason, WhatsNewSkipReason.onboardingIncomplete);
    });
  });
}
