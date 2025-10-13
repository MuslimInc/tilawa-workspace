import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/audio_player_handler.dart';
import 'package:muzakri/audio_player_handler_impl.dart';
import 'package:muzakri/core/services/firebase_initialization_service.dart';
import 'package:muzakri/features/premium/data/services/subscription_plans_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class ExternalDependenciesModule {
  @singleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  @singleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @singleton
  GoogleSignIn get googleSignIn => GoogleSignIn.instance;

  @preResolve
  @singleton
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();

  @singleton
  SubscriptionPlansService subscriptionPlansService(
    FirebaseFirestore firestore,
  ) => SubscriptionPlansService(firestore: firestore);

  @singleton
  FirebaseInitializationService firebaseInitializationService(
    FirebaseFirestore firestore,
    SubscriptionPlansService subscriptionPlansService,
  ) => FirebaseInitializationService(
    firestore: firestore,
    subscriptionPlansService: subscriptionPlansService,
  );

  @singleton
  List<MediaItem> mediaItemList() => [];

  @preResolve
  @singleton
  Future<AudioPlayerHandler> audioPlayerHandler(
    List<MediaItem> mediaItems,
  ) async {
    try {
      print('Initializing audio service...');
      final audioPlayerHandlerImpl = AudioPlayerHandlerImpl(mediaItems);

      final audioHandler = await AudioService.init(
        builder: () => audioPlayerHandlerImpl,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
          androidNotificationChannelName: 'Audio playback',
          androidNotificationOngoing: true,
        ),
      );
      print('Audio service initialized successfully');
      return audioHandler;
    } catch (e) {
      print('Warning: Could not initialize audio service: $e');
      // Register a fallback handler to prevent crashes
      final fallbackHandler = AudioPlayerHandlerImpl([]);
      print('Fallback AudioPlayerHandler registered');
      return fallbackHandler;
    }
  }
}
