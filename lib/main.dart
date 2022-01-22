import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:muzakri/player/play_page.dart';
import 'package:provider/provider.dart';

import 'player/services/audio_services.dart';
import 'src/model/test_rectiters.dart';
import 'src/screens/home_page.dart';
import 'src/services/quran_services.dart';

late AudioPlayerHandler globalAudioHandler;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initalization audio handler
  globalAudioHandler = await AudioService.init(
    builder: () => AudioPlayerHandlerImpl(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.shadow.blackhole.channel.audio',
      androidNotificationChannelName: 'Muzakri',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_stat_music_note',
      androidShowNotificationBadge: true,
      notificationColor: Colors.grey[900],
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        // ChangeNotifierProvider(
        //   create: (context) => PageManager(),
        // ),
        ChangeNotifierProvider(
          create: (context) => RecitersModel(),
        ),
      ],
      child: MyApp(),
    ),
  );
  WidgetsFlutterBinding.ensureInitialized();
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  QuranServices quranServices = QuranServices();
  var myReciters = '';
  @override
  void initState() {
    super.initState();
    // myReciters = quranServices.allReciters;
    quranServices.getAllReciters();
    // print('myReciters: $myReciters end');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مذكري',
      theme: ThemeData(
        fontFamily: 'TheSans',
        scaffoldBackgroundColor: const Color(0xFF1E1F23),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1F23),
          elevation: 0.0,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''),
      ],
      home: HomePage(),
    );
  }
}
