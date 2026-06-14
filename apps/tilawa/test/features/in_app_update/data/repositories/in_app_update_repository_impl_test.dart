import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/in_app_update/data/datasources/in_app_update_config_remote_data_source.dart';
import 'package:tilawa/features/in_app_update/data/datasources/in_app_update_platform_data_source.dart';
import 'package:tilawa/features/in_app_update/data/repositories/in_app_update_repository_impl.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_availability.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_policy.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';

void main() {
  late FakeConfigDataSource configDataSource;
  late FakePlatformDataSource platformDataSource;
  late InAppUpdateRepositoryImpl repository;

  setUp(() {
    configDataSource = FakeConfigDataSource();
    platformDataSource = FakePlatformDataSource();
    repository = InAppUpdateRepositoryImpl(
      configDataSource,
      platformDataSource,
    );
  });

  group('InAppUpdateRepositoryImpl', () {
    test('delegates isSupported to platform data source', () async {
      platformDataSource.isSupportedResult = false;

      expect(await repository.isSupported(), isFalse);
    });

    test('delegates getPolicy to config data source', () async {
      configDataSource.policy = const InAppUpdatePolicy(forceUpdate: true);

      expect((await repository.getPolicy()).forceUpdate, isTrue);
    });

    test('delegates checkAvailability to platform data source', () async {
      const Either<Failure, InAppUpdateAvailability> availability = Right(
        InAppUpdateAvailability(
          updateAvailable: true,
          immediateUpdateAllowed: true,
          flexibleUpdateAllowed: false,
        ),
      );
      platformDataSource.checkAvailabilityResult = availability;

      expect(await repository.checkAvailability(), availability);
    });

    test('delegates update operations to platform data source', () async {
      await repository.performImmediateUpdate();
      await repository.openAppStoreListing();
      await repository.startFlexibleUpdate();
      await repository.completeFlexibleUpdate();

      expect(platformDataSource.performImmediateUpdateCalls, 1);
      expect(platformDataSource.openAppStoreListingCalls, 1);
      expect(platformDataSource.startFlexibleUpdateCalls, 1);
      expect(platformDataSource.completeFlexibleUpdateCalls, 1);
    });
  });
}

class FakeConfigDataSource implements InAppUpdateConfigRemoteDataSource {
  InAppUpdatePolicy policy = const InAppUpdatePolicy();

  @override
  Future<InAppUpdatePolicy> getPolicy() async => policy;
}

class FakePlatformDataSource implements InAppUpdatePlatformDataSource {
  bool isSupportedResult = true;
  Either<Failure, InAppUpdateAvailability> checkAvailabilityResult =
      const Right(InAppUpdateAvailability.unavailable());

  int performImmediateUpdateCalls = 0;
  int openAppStoreListingCalls = 0;
  int startFlexibleUpdateCalls = 0;
  int completeFlexibleUpdateCalls = 0;

  @override
  ResultFuture<InAppUpdateAvailability> checkAvailability() async {
    return checkAvailabilityResult;
  }

  @override
  ResultFuture<void> completeFlexibleUpdate() async {
    completeFlexibleUpdateCalls++;
    return const Right(null);
  }

  @override
  Future<bool> isSupported() async => isSupportedResult;

  @override
  ResultFuture<void> openAppStoreListing() async {
    openAppStoreListingCalls++;
    return const Right(null);
  }

  @override
  ResultFuture<void> performImmediateUpdate() async {
    performImmediateUpdateCalls++;
    return const Right(null);
  }

  @override
  ResultFuture<bool> startFlexibleUpdate() async {
    startFlexibleUpdateCalls++;
    return const Right(true);
  }

  @override
  Stream<void> get onFlexibleUpdateDownloaded => const Stream<void>.empty();
}
