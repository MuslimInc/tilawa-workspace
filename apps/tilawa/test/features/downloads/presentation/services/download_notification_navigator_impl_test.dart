import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/navigation/navigation_source.dart';
import 'package:tilawa/core/navigation/notification_destination.dart';
import 'package:tilawa/core/services/navigation_service.dart';
import 'package:tilawa/features/downloads/presentation/services/download_notification_navigator_impl.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/router/app_router_config.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';

class _RecordingNavigationService implements NavigationService {
  NotificationDestination? routed;

  @override
  void routeToDestination(NotificationDestination destination) {
    routed = destination;
  }

  @override
  void navigateToNotification(String location, {Object? extra}) {}

  @override
  Future<void> push(String location, {Object? extra}) async {}

  @override
  String? getCurrentLocation() => null;
}

class _FakeRecitersRepository implements RecitersRepository {
  _FakeRecitersRepository({this.byId, this.all = const <ReciterEntity>[]});

  final ReciterEntity? byId;
  final List<ReciterEntity> all;

  @override
  Future<Either<Failure, ReciterEntity?>> getReciterById(String id) async =>
      Right<Failure, ReciterEntity?>(byId);

  @override
  Future<Either<Failure, List<ReciterEntity>>> getReciters() async =>
      Right<Failure, List<ReciterEntity>>(all);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ReciterEntity _reciter(int id, String name) => ReciterEntity.fromJson(
  <String, dynamic>{
    'id': id,
    'name': name,
    'letter': name.substring(0, 1),
    'date': '',
    'moshaf': <dynamic>[],
  },
);

void main() {
  group('DownloadNotificationNavigatorImpl', () {
    test('routes to reciter details by id with embedded reciter + notification '
        'source', () async {
      final ReciterEntity reciter = _reciter(7, 'Test Reciter');
      final _RecordingNavigationService nav = _RecordingNavigationService();
      final DownloadNotificationNavigatorImpl navigator =
          DownloadNotificationNavigatorImpl(
            _FakeRecitersRepository(byId: reciter),
            nav,
          );

      await navigator.navigateToReciter(reciterId: '7');

      expect(nav.routed, isNotNull);
      expect(
        Uri.parse(nav.routed!.location).path,
        Uri.parse(const ReciterDetailsRoute(reciterId: '7').location).path,
      );
      expect(nav.routed!.extra, isA<ReciterEntity>());
      expect((nav.routed!.extra! as ReciterEntity).id, 7);
      expect(nav.routed!.source, NavigationSource.notification);
    });

    test('falls back to lookup by name when id is missing', () async {
      final ReciterEntity reciter = _reciter(9, 'Named Reciter');
      final _RecordingNavigationService nav = _RecordingNavigationService();
      final DownloadNotificationNavigatorImpl navigator =
          DownloadNotificationNavigatorImpl(
            _FakeRecitersRepository(all: <ReciterEntity>[reciter]),
            nav,
          );

      await navigator.navigateToReciter(reciterName: 'Named Reciter');

      expect(nav.routed, isNotNull);
      expect((nav.routed!.extra! as ReciterEntity).id, 9);
      expect(nav.routed!.source, NavigationSource.notification);
    });

    test('does not navigate when reciter cannot be resolved', () async {
      final _RecordingNavigationService nav = _RecordingNavigationService();
      final DownloadNotificationNavigatorImpl navigator =
          DownloadNotificationNavigatorImpl(
            _FakeRecitersRepository(),
            nav,
          );

      await navigator.navigateToReciter(reciterId: '404');

      expect(nav.routed, isNull);
    });
  });
}
