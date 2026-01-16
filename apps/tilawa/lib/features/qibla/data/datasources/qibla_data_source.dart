import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:qibla/qibla.dart';
import 'package:tilawa/core/wrappers/location_service_wrapper.dart';
import 'package:tilawa/core/wrappers/qibla_service_wrapper.dart';

abstract class QiblaDataSource {
  Stream<QiblaDirection> get qiblaStream;
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
}

@LazySingleton(as: QiblaDataSource)
class QiblaDataSourceImpl implements QiblaDataSource {
  QiblaDataSourceImpl(this._locationService, this._qiblaService);

  final LocationServiceWrapper _locationService;
  final QiblaServiceWrapper _qiblaService;

  @override
  Stream<QiblaDirection> get qiblaStream => _qiblaService.qiblaStream;

  @override
  Future<bool> isLocationServiceEnabled() =>
      _locationService.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() =>
      _locationService.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      _locationService.requestPermission();
}
