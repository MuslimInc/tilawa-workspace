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
  static const double _maxSingleSampleHeadingJump = 35;
  static const double _jumpConfirmationTolerance = 8;

  @override
  Stream<QiblaDirectionEntity> getQiblaDirection() {
    return _dataSource.qiblaStream
        .sampleTime(const Duration(milliseconds: 120))
        .map((qiblaDirection) {
          return QiblaDirectionEntity(
            qibla: _normalizeAngle(qiblaDirection.qibla),
            direction: _normalizeAngle(qiblaDirection.direction),
            offset: _normalizeAngle(qiblaDirection.offset),
            accuracy: qiblaDirection.accuracy,
          );
        })
        .transform(_headingSpikeFilter())
        .distinct(
          (prev, curr) =>
              _isSimilarAngle(prev.qibla, curr.qibla) &&
              _isSimilarAngle(prev.direction, curr.direction) &&
              _isSimilarAngle(prev.offset, curr.offset) &&
              prev.hasPoorCompassAccuracy == curr.hasPoorCompassAccuracy,
        );
  }

  StreamTransformer<QiblaDirectionEntity, QiblaDirectionEntity>
  _headingSpikeFilter() {
    QiblaDirectionEntity? lastEmitted;
    QiblaDirectionEntity? pendingJump;

    return StreamTransformer.fromHandlers(
      handleData: (current, sink) {
        if (lastEmitted == null) {
          lastEmitted = current;
          sink.add(current);
          return;
        }

        final double distanceFromLast = _angleDistance(
          lastEmitted!.direction,
          current.direction,
        );
        if (distanceFromLast <= _maxSingleSampleHeadingJump) {
          lastEmitted = current;
          pendingJump = null;
          sink.add(current);
          return;
        }

        if (pendingJump != null &&
            _angleDistance(pendingJump!.direction, current.direction) <=
                _jumpConfirmationTolerance) {
          lastEmitted = current;
          pendingJump = null;
          sink.add(current);
          return;
        }

        pendingJump = current;
      },
    );
  }

  double _normalizeAngle(double value) {
    return (value % 360 + 360) % 360;
  }

  bool _isSimilarAngle(double first, double second) {
    return _angleDistance(first, second) < _angleTolerance;
  }

  double _angleDistance(double first, double second) {
    final double diff = (first - second).abs() % 360;
    return diff > 180 ? 360 - diff : diff;
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
