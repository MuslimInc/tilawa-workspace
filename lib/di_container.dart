import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:muzakri/audio_player_handler.dart';
import 'package:muzakri/audio_player_handler_impl.dart';

final getIt = GetIt.instance;
final AudioPlayerHandler globalAudioHandler = getIt<AudioPlayerHandler>();

Future<void> initDI() async {
  final audioPlayerHandlerImpl = AudioPlayerHandlerImpl(
    newList: [
      MediaItem(
        id: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        title: 'Song 1333333333',
      ),
      MediaItem(
        id: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        title: 'Song 25555555555',
      ),
      MediaItem(
        id: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        title: 'Song 3555343434',
      ),
    ],
  );

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
