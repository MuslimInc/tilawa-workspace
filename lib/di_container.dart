import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:muzakri/audio_player_handler.dart';
import 'package:muzakri/audio_player_handler_impl.dart';
import 'package:muzakri/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import 'package:muzakri/bloc/localization/localization_bloc.dart';
import 'package:muzakri/bloc/reciter_details/reciter_details_bloc.dart';
import 'package:muzakri/bloc/reciters/reciters_bloc.dart';

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

  // Register Blocs
  getIt.registerFactory<LocalizationBloc>(() => LocalizationBloc());
  getIt.registerFactory<RecitersBloc>(() => RecitersBloc());
  getIt.registerFactory<ReciterDetailsBloc>(() => ReciterDetailsBloc());
  getIt.registerFactory<AlphabetScrollbarBloc>(() => AlphabetScrollbarBloc());
}
