import 'package:tilawa_core/utils/typedefs.dart';

import '../entities/in_app_update_availability.dart';
import '../entities/in_app_update_policy.dart';

/// Domain contract for remote policy and Play in-app update operations.
abstract class InAppUpdateRepository {
  Future<bool> isSupported();

  Future<InAppUpdatePolicy> getPolicy();

  ResultFuture<InAppUpdateAvailability> checkAvailability();

  ResultFuture<void> performImmediateUpdate();

  ResultFuture<void> openAppStoreListing();

  ResultFuture<bool> startFlexibleUpdate();

  ResultFuture<void> completeFlexibleUpdate();
}
