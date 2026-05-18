import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/debug/deep_link_debug_log.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../../../router/app_router_config.dart';
import '../../../reciters/domain/repositories/reciters_repository.dart';
import '../../domain/services/download_notification_navigator.dart';

@LazySingleton(as: DownloadNotificationNavigator)
class DownloadNotificationNavigatorImpl
    implements DownloadNotificationNavigator {
  DownloadNotificationNavigatorImpl(this._recitersRepository, this._navigator);

  final RecitersRepository _recitersRepository;
  final NavigationService _navigator;

  @override
  Future<void> navigateToReciter({
    String? reciterId,
    String? reciterName,
  }) async {
    final int startMs = DeepLinkDebugLog.elapsedMs;
    // #region agent log
    DeepLinkDebugLog.log(
      'DownloadNavigator.navigateToReciter START',
      scenario: 'download_nav',
      hypothesisId: 'H6',
      data: <String, Object?>{
        'reciterId': reciterId,
        'reciterName': reciterName,
      },
    );
    // #endregion
    try {
      if (reciterId != null) {
        final Either<Failure, ReciterEntity?> result = await _recitersRepository
            .getReciterById(reciterId);
        final ReciterEntity? reciter = result.fold(
          (_) => null,
          (value) => value,
        );
        if (reciter != null) {
          _pushReciterIfNeeded(reciter);
          // #region agent log
          DeepLinkDebugLog.log(
            'DownloadNavigator.navigateToReciter END (by id)',
            scenario: 'download_nav',
            hypothesisId: 'H6',
            data: <String, Object?>{
              'durationMs': DeepLinkDebugLog.elapsedMs - startMs,
            },
          );
          // #endregion
          return;
        }
        // #region agent log
        DeepLinkDebugLog.log(
          'DownloadNavigator reciter not found by id',
          scenario: 'download_nav',
          hypothesisId: 'H6',
          data: <String, Object?>{'reciterId': reciterId},
        );
        // #endregion
      }

      if (reciterName == null || reciterName.isEmpty) {
        // #region agent log
        DeepLinkDebugLog.log(
          'DownloadNavigator abort no id or name',
          scenario: 'download_nav',
          hypothesisId: 'H6',
        );
        // #endregion
        return;
      }

      final Either<Failure, List<ReciterEntity>> result =
          await _recitersRepository.getReciters();

      result.fold(
        (failure) => logger.e(
          'DownloadNotificationNavigator: Failed to fetch reciters: $failure',
        ),
        (reciters) {
          try {
            final ReciterEntity reciterEntity = reciters.firstWhere(
              (r) => r.name == reciterName,
            );
            _pushReciterIfNeeded(reciterEntity);
          } catch (e) {
            logger.w(
              'DownloadNotificationNavigator: Reciter not found for name: $reciterName',
            );
          }
        },
      );
    } catch (e) {
      logger.e('DownloadNotificationNavigator: Navigation error: $e');
    }
  }

  void _pushReciterIfNeeded(ReciterEntity reciter) {
    final String reciterId = reciter.id.toString();
    final String location = ReciterDetailsRoute(
      reciterId: reciterId,
      $extra: reciter,
    ).location;

    // Only use cold-start navigation when the app was actually launched from
    // a notification (restoration disabled). After bootstrap consumes that
    // launch, warm taps must use push so we do not re-go an already-visible
    // route.
    if (AppRouter.disableStateRestoration &&
        AppRouter.pendingColdStartLocation != null) {
      AppRouter.navigateFromColdStart(location, extra: reciter);
      return;
    }

    final String? currentLocation = _navigator.getCurrentLocation();
    if (currentLocation != null) {
      final Uri currentUri = Uri.parse(currentLocation);
      final Uri targetUri = Uri.parse(location);
      if (currentUri.path == targetUri.path) {
        // #region agent log
        DeepLinkDebugLog.log(
          'DownloadNavigator skip already on target',
          scenario: 'download_nav',
          hypothesisId: 'H6',
          data: <String, Object?>{'path': currentUri.path},
        );
        // #endregion
        return;
      }
    }

    // #region agent log
    DeepLinkDebugLog.log(
      'DownloadNavigator NavigationService.push',
      scenario: 'download_nav',
      hypothesisId: 'H6',
      data: <String, Object?>{
        'location': location,
        'from': currentLocation,
      },
    );
    // #endregion
    _navigator.push(location, extra: reciter);
  }
}
