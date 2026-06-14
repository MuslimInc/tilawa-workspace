import 'package:tilawa_core/utils/typedefs.dart';

import '../../domain/entities/in_app_update_availability.dart';

/// Platform bridge for Google Play in-app updates.
abstract class InAppUpdatePlatformDataSource {
  Future<bool> isSupported();

  ResultFuture<InAppUpdateAvailability> checkAvailability();

  ResultFuture<void> performImmediateUpdate();

  ResultFuture<void> openAppStoreListing();

  /// Starts a flexible update flow.
  ///
  /// The native plugin completes this future only after Play reports
  /// [InstallStatus.downloaded], not merely after user consent.
  ResultFuture<bool> startFlexibleUpdate();

  ResultFuture<void> completeFlexibleUpdate();
}
