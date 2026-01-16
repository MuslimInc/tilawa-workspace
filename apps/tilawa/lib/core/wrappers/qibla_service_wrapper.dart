import 'package:injectable/injectable.dart';
import 'package:qibla/qibla.dart';

@lazySingleton
class QiblaServiceWrapper {
  Stream<QiblaDirection> get qiblaStream => Qibla.qiblaStream;
}
