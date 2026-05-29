import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/core/navigation/navigation_source.dart';
import 'package:tilawa/core/navigation/notification_destination.dart';
import 'package:tilawa/core/services/navigation_service.dart';
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
    try {
      if (reciterId != null) {
        final Either<Failure, ReciterEntity?> result = await _recitersRepository
            .getReciterById(reciterId);
        final ReciterEntity? reciter = result.fold(
          (_) => null,
          (value) => value,
        );
        if (reciter != null) {
          _pushReciter(reciter);
          return;
        }
      }

      if (reciterName == null || reciterName.isEmpty) {
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
            _pushReciter(reciterEntity);
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

  void _pushReciter(ReciterEntity reciter) {
    final String location = ReciterDetailsRoute(
      reciterId: reciter.id.toString(),
      $extra: reciter,
    ).location;

    // Cold-start vs warm and same-target/duplicate handling are now owned by the
    // unified NavigationService + AppRouter, so this path no longer branches.
    _navigator.routeToDestination(
      NotificationDestination(
        location: location,
        extra: reciter,
        source: NavigationSource.notification,
      ),
    );
  }
}
