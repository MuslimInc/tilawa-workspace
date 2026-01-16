import 'package:audio_service/audio_service.dart';
import 'package:injectable/injectable.dart';

abstract class AudioPositionService {
  Stream<Duration> get position;
}

@LazySingleton(as: AudioPositionService)
class AudioPositionServiceImpl implements AudioPositionService {
  @override
  Stream<Duration> get position => AudioService.position.distinct();
}
