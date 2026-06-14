import 'dart:async';
import 'dart:io';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/in_app_update_availability.dart';
import 'in_app_update_platform_data_source.dart';

@LazySingleton(as: InAppUpdatePlatformDataSource)
class PlayInAppUpdatePlatformDataSource
    implements InAppUpdatePlatformDataSource {
  Stream<void>? _flexibleDownloadedStream;

  /// When set, overrides [Platform.isAndroid] for stream behavior in tests.
  @visibleForTesting
  bool? androidPlatformForTesting;

  bool get _isAndroidHost => androidPlatformForTesting ?? Platform.isAndroid;
  @override
  Future<bool> isSupported() async => Platform.isAndroid;

  @override
  Future<Either<Failure, InAppUpdateAvailability>> checkAvailability() async {
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.totalBytesToDownload case final int bytes?) {
        logger.d(
          '[InAppUpdatePlatform] Play reports $bytes bytes to download.',
        );
      }
      return Right(
        InAppUpdateAvailability(
          updateAvailable:
              updateInfo.updateAvailability ==
              UpdateAvailability.updateAvailable,
          immediateUpdateAllowed: updateInfo.immediateUpdateAllowed,
          flexibleUpdateAllowed: updateInfo.flexibleUpdateAllowed,
          flexibleUpdateDownloaded:
              updateInfo.installStatus == InstallStatus.downloaded,
        ),
      );
    } catch (e) {
      if (e is PlatformException && _isUnsupportedPlayEnvironment(e)) {
        logger.d(
          '[InAppUpdatePlatform] In-app updates unavailable (${_installErrorCode(e)}). '
          'Expected on emulators, sideloads, or devices without Play Store.',
        );
        return const Right(InAppUpdateAvailability.unavailable());
      }
      logger.e('[InAppUpdatePlatform] checkAvailability failed: $e');
      final String? message = e is PlatformException ? e.message : e.toString();
      return Left(InAppUpdateFailure.checkFailed(message));
    }
  }

  @override
  Future<Either<Failure, void>> performImmediateUpdate() async {
    try {
      final AppUpdateResult result = await InAppUpdate.performImmediateUpdate();
      if (result == AppUpdateResult.userDeniedUpdate) {
        logger.d('[InAppUpdatePlatform] Immediate update denied by user.');
        return const Right(null);
      }
      if (result == AppUpdateResult.inAppUpdateFailed) {
        logger.w('[InAppUpdatePlatform] Immediate update failed.');
        return const Left(InAppUpdateFailure.updateFailed());
      }
      return const Right(null);
    } catch (e) {
      logger.e('[InAppUpdatePlatform] performImmediateUpdate failed: $e');
      final String? message = e is PlatformException ? e.message : e.toString();
      return Left(InAppUpdateFailure.platformError(message));
    }
  }

  @override
  Future<Either<Failure, void>> openAppStoreListing() async {
    try {
      await InAppUpdate.openAppStoreListing();
      return const Right(null);
    } catch (e) {
      logger.e('[InAppUpdatePlatform] openAppStoreListing failed: $e');
      final String? message = e is PlatformException ? e.message : e.toString();
      return Left(InAppUpdateFailure.platformError(message));
    }
  }

  @override
  Future<Either<Failure, bool>> startFlexibleUpdate() async {
    try {
      final AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();
      if (result != AppUpdateResult.success) {
        logger.w('[InAppUpdatePlatform] Flexible update result: $result');
        return const Right(false);
      }
      return const Right(true);
    } catch (e) {
      logger.e('[InAppUpdatePlatform] startFlexibleUpdate failed: $e');
      final String? message = e is PlatformException ? e.message : e.toString();
      return Left(InAppUpdateFailure.platformError(message));
    }
  }

  @override
  Future<Either<Failure, void>> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
      return const Right(null);
    } catch (e) {
      logger.e('[InAppUpdatePlatform] completeFlexibleUpdate failed: $e');
      final String? message = e is PlatformException ? e.message : e.toString();
      return Left(InAppUpdateFailure.platformError(message));
    }
  }

  @override
  Stream<void> get onFlexibleUpdateDownloaded {
    if (!_isAndroidHost) {
      return const Stream<void>.empty();
    }

    _flexibleDownloadedStream ??= InAppUpdate.installUpdateListener
        .map(
          (InstallStatus status) => switch (status) {
            InstallStatus.downloaded => true,
            _ => false,
          },
        )
        .where((bool downloaded) => downloaded)
        .map((_) {});
    return _flexibleDownloadedStream!;
  }

  bool _isUnsupportedPlayEnvironment(PlatformException error) {
    if (error.code != 'TASK_FAILURE') {
      return false;
    }
    return switch (_installErrorCode(error)) {
      '-9' || '-10' => true,
      _ => false,
    };
  }

  String _installErrorCode(PlatformException error) {
    final String message = error.message ?? '';
    final RegExpMatch? match = RegExp(r'Install Error\((-?\d+)\)').firstMatch(
      message,
    );
    return match?.group(1) ?? 'unknown';
  }
}
