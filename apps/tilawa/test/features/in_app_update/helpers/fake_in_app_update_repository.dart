import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_availability.dart';
import 'package:tilawa/features/in_app_update/domain/entities/in_app_update_policy.dart';
import 'package:tilawa/features/in_app_update/domain/repositories/in_app_update_repository.dart';
import 'package:tilawa_core/errors/failures.dart';

class FakeInAppUpdateRepository implements InAppUpdateRepository {
  FakeInAppUpdateRepository({
    this.isSupportedResult = true,
    this.policy = const InAppUpdatePolicy(),
    this.availability = const Right(InAppUpdateAvailability.unavailable()),
    this.startFlexibleUpdateResult = const Right(false),
    this.performImmediateUpdateResult = const Right(null),
    this.openAppStoreListingResult = const Right(null),
    this.completeFlexibleUpdateResult = const Right(null),
  });

  bool isSupportedResult;
  InAppUpdatePolicy policy;
  Either<Failure, InAppUpdateAvailability> availability;
  Either<Failure, bool> startFlexibleUpdateResult;
  Either<Failure, void> performImmediateUpdateResult;
  Either<Failure, void> openAppStoreListingResult;
  Either<Failure, void> completeFlexibleUpdateResult;

  bool throwOnCheckAvailability = false;
  int checkAvailabilityCalls = 0;
  int performImmediateUpdateCalls = 0;
  int openAppStoreListingCalls = 0;
  int startFlexibleUpdateCalls = 0;
  int completeFlexibleUpdateCalls = 0;

  @override
  Future<Either<Failure, InAppUpdateAvailability>> checkAvailability() async {
    checkAvailabilityCalls++;
    if (throwOnCheckAvailability) {
      throw StateError('unexpected');
    }
    return availability;
  }

  @override
  Future<Either<Failure, void>> completeFlexibleUpdate() async {
    completeFlexibleUpdateCalls++;
    return completeFlexibleUpdateResult;
  }

  @override
  Future<InAppUpdatePolicy> getPolicy() async => policy;

  @override
  Future<bool> isSupported() async => isSupportedResult;

  @override
  Future<Either<Failure, void>> performImmediateUpdate() async {
    performImmediateUpdateCalls++;
    return performImmediateUpdateResult;
  }

  @override
  Future<Either<Failure, void>> openAppStoreListing() async {
    openAppStoreListingCalls++;
    return openAppStoreListingResult;
  }

  @override
  Future<Either<Failure, bool>> startFlexibleUpdate() async {
    startFlexibleUpdateCalls++;
    return startFlexibleUpdateResult;
  }
}
