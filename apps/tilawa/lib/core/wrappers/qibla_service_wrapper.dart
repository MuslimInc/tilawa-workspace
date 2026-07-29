import 'package:qibla/qibla.dart';

class QiblaServiceWrapper {
  Stream<QiblaDirection> get qiblaStream => Qibla.qiblaStream;
}
