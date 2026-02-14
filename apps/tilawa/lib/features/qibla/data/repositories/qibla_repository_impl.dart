import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain/entities/qibla_direction_entity.dart';
import '../../domain/repositories/qibla_repository.dart';
import '../datasources/qibla_data_source.dart';

@LazySingleton(as: QiblaRepository)
class QiblaRepositoryImpl implements QiblaRepository {
  QiblaRepositoryImpl(this._dataSource);
  final QiblaDataSource _dataSource;
  static const double _angleTolerance = 0.5;

  @override
  Stream<QiblaDirectionEntity> getQiblaDirection() {
    return _dataSource.qiblaStream
        .sampleTime(const Duration(milliseconds: 120))
        .map((qiblaDirection) {
          return QiblaDirectionEntity(
            qibla: _normalizeAngle(qiblaDirection.qibla),
            direction: _normalizeAngle(qiblaDirection.direction),
            offset: _normalizeAngle(qiblaDirection.offset),
          );
        })
        .distinct(
          (prev, curr) =>
              _isSimilarAngle(prev.qibla, curr.qibla) &&
              _isSimilarAngle(prev.direction, curr.direction) &&
              _isSimilarAngle(prev.offset, curr.offset),
        );
  }

  double _normalizeAngle(double value) {
    return (value % 360 + 360) % 360;
  }

  bool _isSimilarAngle(double first, double second) {
    final double diff = (first - second).abs() % 360;
    final double shortestDistance = diff > 180 ? 360 - diff : diff;
    return shortestDistance < _angleTolerance;
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
