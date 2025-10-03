import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:muzakri/audio_player_handler.dart';
import 'package:muzakri/audio_player_handler_impl.dart';

final getIt = GetIt.instance;
final AudioPlayerHandler globalAudioHandler = getIt<AudioPlayerHandler>();

Future<void> initDI() async {
  final audioPlayerHandlerImpl = AudioPlayerHandlerImpl(newList: []);

  getIt.registerSingleton<AudioPlayerHandlerImpl>(audioPlayerHandlerImpl);
  final audioHandler = await AudioService.init(
    builder: () => getIt<AudioPlayerHandlerImpl>(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );

  getIt.registerSingleton<AudioPlayerHandler>(audioHandler);
}
