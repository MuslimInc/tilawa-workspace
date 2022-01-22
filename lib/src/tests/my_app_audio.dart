// import 'dart:ui' as ui;

// import 'package:audio_session/audio_session.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:just_audio/just_audio.dart';

// class MyApps extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'مذكري',
//       localizationsDelegates: [
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//       ],
//       supportedLocales: [
//         Locale('ar', 'AE'),
//       ],
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         accentColor: Colors.greenAccent,
//         fontFamily: 'TheSans',
//         backgroundColor: Colors.red,
//         textTheme: TextTheme(
//           headline4: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         appBarTheme: AppBarTheme(
//           backgroundColor: Colors.transparent,
//           elevation: 0.0,
//           textTheme: TextTheme(),
//         ),
//       ),
//       home: AudioPage(),
//     );
//   }
// }

// class AudioPage extends StatefulWidget {
//   @override
//   _AudioPageState createState() => _AudioPageState();
// }

// class _AudioPageState extends State<AudioPage>
//     with SingleTickerProviderStateMixin, WidgetsBindingObserver {
//   AudioPlayer advancedPlayer = AudioPlayer();

//   bool isPlaying = false;
//   late Duration _startPosition = Duration(seconds: 0);

//   late Duration _endPosition = Duration(seconds: 0);

//   // Test stop audio on phone call
//   _checkPhoneCall() async {
//     final session = await AudioSession.instance;
//     await session.configure(AudioSessionConfiguration.music());
//     session.interruptionEventStream.listen((event) {
//       if (event.begin) {
//         print('I am ssstate1: ${event.type}');
//         switch (event.type) {
//           case AudioInterruptionType.duck:
//             advancedPlayer.pause();
//             // Another app started playing audio and we should duck.
//             break;
//           case AudioInterruptionType.pause:
//           case AudioInterruptionType.unknown:
//             advancedPlayer.pause();
//             // Another app started playing audio and we should pause.
//             break;
//         }
//       } else {
//         print('I am ssstate2: ${event.type}');
//         switch (event.type) {
//           case AudioInterruptionType.duck:
//             advancedPlayer.play(audioPath);
//             // The interruption ended and we should unduck.
//             break;
//           case AudioInterruptionType.pause:
//             advancedPlayer.play(audioPath);
//             break;
//           // The interruption ended and we should resume.
//           case AudioInterruptionType.unknown:
//             // The interruption ended but we should not resume.
//             break;
//         }
//       }
//     });
//   }

//   String audioPath =
//       'https://server14.mp3quran.net/swlim/Rewayat-Hafs-A-n-Assem/001.mp3';

//   late Animation<double> _animation;
//   late AnimationController _controller;

//   late ui.Image customImage;
//   Future<ui.Image> loadImage(String imageUrl) async {
//     ByteData data = await rootBundle.load(imageUrl);
//     ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
//     ui.FrameInfo fi = await codec.getNextFrame();
//     return fi.image;
//   }

//   @override
//   void initState() {
//     super.initState();
//     _checkPhoneCall();
//     loadImage('assets/images/green_slider.png').then((image) {
//       setState(() {
//         customImage = image;
//       });
//     });
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 250),
//       reverseDuration: const Duration(milliseconds: 250),
//     )..addListener(() {
//         setState(() {
//           print('Listener!');
//         });
//       });
//     _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
//     advancedPlayer.onDurationChanged.listen((duration) {
//       if (mounted)
//         setState(() {
//           _endPosition = duration;
//         });
//     });

//     advancedPlayer.onAudioPositionChanged.listen((position) {
//       if (mounted)
//         setState(() {
//           _startPosition = position;
//         });
//     });

//     // Playing is complete
//     advancedPlayer.onPlayerCompletion.listen((complete) {
//       if (mounted)
//         setState(() {
//           // _position = Duration(seconds: 0);
//           isPlaying = false;
//           // _controller.reset();
//           _controller.reverse();
//         });
//     });

//     WidgetsBinding.instance!.addObserver(this);
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     print('I am staus: $state end');
//     // if (state == AppLifecycleState.detached) {
//     //   advancedPlayer.pause();
//     //   print('I am stats: ${state.toString()}');
//     //   print('advancedPlayer: ${advancedPlayer.state}');
//     // } else if (state == AppLifecycleState.paused) {
//     //   advancedPlayer.pause();
//     //   print('I am stats: ${state.toString()}');
//     //   print('advancedPlayer: ${advancedPlayer.state}');
//     // } else {
//     //   print('I am stats: ${state.toString()}');
//     //   print('advancedPlayer: ${advancedPlayer.state}');
//     // }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         body: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             const SizedBox(height: 3.0),
//             Padding(
//               padding: const EdgeInsets.all(10.0),
//               child: Align(
//                 alignment: Alignment.topRight,
//                 child: TextButton(
//                   onPressed: () {},
//                   child: Icon(
//                     Icons.arrow_back,
//                     color: Color(0xFFDDF3FF),
//                   ),
//                   style: ButtonStyle(
//                     backgroundColor: MaterialStateProperty.all(
//                       Color(0xFF3F4550),
//                     ),
//                     shape: MaterialStateProperty.all(
//                       const CircleBorder(),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             Text(
//               'سورة الفاتحة',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 20.0,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'حفص عن عاصم - مرتل',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 20.0,
//               ),
//             ),
//             const SizedBox(height: 30),
//             Padding(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 20.0,
//               ),
//               child: Container(
//                 height: 350,
//                 decoration: BoxDecoration(
//                   color: Color(0xFF202020),
//                   borderRadius: const BorderRadius.all(
//                     Radius.circular(20.0),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     const SizedBox(height: 50),
//                     Text(
//                       'ياسر الدوسري',
//                       style: Theme.of(context).textTheme.headline4,
//                     ),
//                     // Playing slider
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         // Playing time
//                         Expanded(
//                           child: Container(
//                             // color: Colors.red,
//                             child: Text(
//                               '${_startPosition.toString().split('.')[0]}',
//                               textAlign: TextAlign.left,
//                               textDirection: ui.TextDirection.ltr,
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                           flex: 4,
//                           child: Padding(
//                             padding:
//                                 const EdgeInsets.symmetric(horizontal: 20.0),
//                             child: SliderTheme(
//                               data: SliderThemeData(
//                                 activeTickMarkColor: Colors.pink,
//                                 thumbColor: Colors.black,
//                               ),
//                               child: Slider(
//                                 // activeColor: Colors.green,
//                                 // inactiveColor: Colors.green.shade100,
//                                 onChanged: (double val) {
//                                   setState(() {
//                                     Duration duration =
//                                         Duration(seconds: val.toInt());
//                                     advancedPlayer.seek(duration);
//                                   });
//                                 },
//                                 value: _startPosition.inSeconds.toDouble(),
//                                 min: 0.0,
//                                 max: _endPosition.inSeconds.toDouble(),
//                               ),
//                             ),
//                           ),
//                         ),
//                         Expanded(
//                             child: Text(
//                                 '${_endPosition.toString().split('.')[0]}')),
//                       ],
//                     ),

//                     const SizedBox(height: 50),
//                     IconButton(
//                       onPressed: () async {
//                         if (isPlaying == false) {
//                           await advancedPlayer.play(audioPath);
//                           setState(() {
//                             isPlaying = true;
//                             _controller.forward();
//                             print('is Playing');
//                           });
//                         } else if (isPlaying == true) {
//                           advancedPlayer.pause();
//                           setState(() {
//                             isPlaying = false;
//                             _controller.reverse();
//                             print('is Not Playing');
//                           });
//                         }
//                       },
//                       icon: AnimatedIcon(
//                         icon: AnimatedIcons.play_pause,
//                         progress: _animation,
//                         size: 50,
//                       ),
//                     ),

//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class SliderThumbImage extends SliderComponentShape {
//   final ui.Image image;

//   SliderThumbImage(this.image);

//   @override
//   Size getPreferredSize(bool isEnabled, bool isDiscrete) {
//     return Size(0, 0);
//   }

//   @override
//   void paint(PaintingContext context, Offset center,
//       {required Animation<double> activationAnimation,
//       required Animation<double> enableAnimation,
//       required bool isDiscrete,
//       required TextPainter labelPainter,
//       required RenderBox parentBox,
//       required SliderThemeData sliderTheme,
//       required TextDirection textDirection,
//       required double value,
//       required double textScaleFactor,
//       required Size sizeWithOverflow}) {
//     final canvas = context.canvas;
//     final imageWidth = image.width;
//     final imageHeight = image.height;

//     Offset imageOffset = Offset(
//       center.dx - (imageWidth / 2),
//       center.dy - (imageHeight / 2),
//     );

//     Paint paint = Paint()..filterQuality = FilterQuality.high;

//     canvas.drawImage(image, imageOffset, paint);
//   }
// }
