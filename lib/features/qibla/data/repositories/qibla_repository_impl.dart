import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/qibla_direction_entity.dart';
import '../../domain/repositories/qibla_repository.dart';
import '../datasources/qibla_data_source.dart';

@LazySingleton(as: QiblaRepository)
class QiblaRepositoryImpl implements QiblaRepository {
  QiblaRepositoryImpl(this._dataSource);
  final QiblaDataSource _dataSource;

  @override
  Stream<QiblaDirectionEntity> getQiblaDirection() {
    return _dataSource.qiblaStream.map((qiblaDirection) {
      return QiblaDirectionEntity(
        qibla: qiblaDirection.qibla,
        direction: qiblaDirection.direction,
        offset: qiblaDirection.offset,
      );
    });
  }

  @override
  Future<bool> isLocationServiceEnabled() {
    return _dataSource.isLocationServiceEnabled();
  }

  @override
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await _dataSource.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await _dataSource.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
