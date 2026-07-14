import 'package:checks/checks.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/forced_update/domain/entities/forced_update_decision.dart';
import 'package:tilawa/features/forced_update/domain/entities/forced_update_host_platform.dart';
import 'package:tilawa/features/forced_update/domain/entities/forced_update_policy.dart';
import 'package:tilawa/features/forced_update/domain/repositories/forced_update_repository.dart';
import 'package:tilawa/features/forced_update/domain/services/forced_update_evaluator.dart';
import 'package:tilawa/features/forced_update/domain/services/forced_update_host_platform_resolver.dart';
import 'package:tilawa/features/forced_update/domain/usecases/evaluate_forced_update_use_case.dart';
import 'package:tilawa_core/entities/app_info.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

class _FakeForcedUpdateRepository implements ForcedUpdateRepository {
  _FakeForcedUpdateRepository(this.policy) : throwOnGet = false;

  ForcedUpdatePolicy policy;
  bool throwOnGet;

  @override
  Future<ForcedUpdatePolicy> getPolicy() async {
    if (throwOnGet) {
      throw Exception('network');
    }
    return policy;
  }
}

class _FakeAppInfoService implements AppInfoService {
  _FakeAppInfoService(this.buildNumber);

  String buildNumber;

  @override
  Future<AppInfo> getAppInfo() async {
    return AppInfo(
      version: '2.1.4',
      buildNumber: buildNumber,
      appName: 'MeMuslim',
      packageName: 'com.tilawa.app',
    );
  }
}

class _FakeHostPlatformResolver implements ForcedUpdateHostPlatformResolver {
  _FakeHostPlatformResolver(this.platform);

  ForcedUpdateHostPlatform platform;

  @override
  ForcedUpdateHostPlatform resolve() => platform;
}

void main() {
  late _FakeForcedUpdateRepository repository;
  late _FakeAppInfoService appInfoService;
  late _FakeHostPlatformResolver platformResolver;
  late EvaluateForcedUpdateUseCase useCase;

  setUp(() {
    repository = _FakeForcedUpdateRepository(const ForcedUpdatePolicy());
    appInfoService = _FakeAppInfoService('78');
    platformResolver = _FakeHostPlatformResolver(
      ForcedUpdateHostPlatform.android,
    );
    useCase = EvaluateForcedUpdateUseCase(
      repository,
      appInfoService,
      const ForcedUpdateEvaluator(),
      platformResolver,
    );
  });

  group('EvaluateForcedUpdateUseCase', () {
    test('returns required when behind android min', () async {
      repository.policy = const ForcedUpdatePolicy(androidMinBuildNumber: 80);

      check(await useCase()).equals(ForcedUpdateDecision.required);
    });

    test('returns none when current', () async {
      repository.policy = const ForcedUpdatePolicy(androidMinBuildNumber: 78);

      check(await useCase()).equals(ForcedUpdateDecision.none);
    });

    test('fails open when repository throws', () async {
      repository.throwOnGet = true;
      repository.policy = const ForcedUpdatePolicy(androidMinBuildNumber: 999);

      check(await useCase()).equals(ForcedUpdateDecision.none);
    });

    test('fails open when build number is unparseable', () async {
      repository.policy = const ForcedUpdatePolicy(androidMinBuildNumber: 80);
      appInfoService.buildNumber = 'x';

      check(await useCase()).equals(ForcedUpdateDecision.none);
    });

    test('uses ios min when host is ios', () async {
      platformResolver.platform = ForcedUpdateHostPlatform.ios;
      repository.policy = const ForcedUpdatePolicy(
        androidMinBuildNumber: 1,
        iosMinBuildNumber: 100,
      );
      appInfoService.buildNumber = '50';

      check(await useCase()).equals(ForcedUpdateDecision.required);
    });
  });
}
