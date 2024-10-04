import 'package:flutter/material.dart';
import 'package:muzakri/src/screens/reciter_page.dart';
import 'package:provider/provider.dart';

import '../model/test_rectiters.dart';
import '../shared/custom_page_route.dart';
import 'custom_button.dart';
import 'custom_card.dart';

// FROM SPLASH SCREEN
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late RecitersModel recitersModel;
  late Future<Reciter> list;

  @override
  void initState() {
    super.initState();
    recitersModel = RecitersModel();
    recitersModel.getNames();
  }

  @override
  Widget build(BuildContext context) {
    var reciters = context.watch<RecitersModel>();
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.search,
              color: Color(0xFFD2E5E8),
            ),
          ),
          title: const Text(
            'القرآن الكريم',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () => Future.delayed(
              const Duration(seconds: 1), reciters.getAllReciters),
          backgroundColor: Colors.white10,
          color: Colors.greenAccent,
          child: FutureBuilder<List<Reciter>>(
              future: reciters.getAllReciters(),
              builder: (context, snapshot) {
                if (!snapshot.hasData && snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    final name = snapshot.data![index].name;
                    final rewaya = snapshot.data![index].rewaya;
                    final server = snapshot.data![index].server;
                    final List<String> suras =
                        snapshot.data![index].suras.split(',');
                    return CustomCard(
                      title: name.toString(),
                      child: CustomButton(
                        title: rewaya.toString(),
                        color: const Color(0xFF00DBFF),
                        onTap: () => Navigator.push(
                          context,
                          CustomPageRoute(
                            // child: QuranList(
                            //   // title: 'ياسر الدوسري',
                            //   title: '${name.toString()}',
                            //   server: '${server.toString()}',
                            //   listSuras: suras,
                            //   reciterName: "reciterName",
                            // ),
                            child: ReciterPage(
                              urlList: suras,
                              server: server.toString(),
                            ),
                            // child: PlayPage(),
                          ),
                        ),
                      ),
                    );

                    // return GestureDetector(
                    //   onTap: () async {
                    //     for (int i = 0; i < surahList.length; i++) {
                    //       if (surahList[index].isPlaying == i) {
                    //         if (widget.audioPlayer != null) {
                    //           result = await widget.audioPlayer!.stop();
                    //         }
                    //         result = await widget.audioPlayer!
                    //             .play(surahList[index].url!, isLocal: true);
                    //         setState(() {
                    //           for (int i = 0; i < surahList.length; i++) {
                    //             surahList[i].isPlaying = 0;
                    //           }
                    //           surahList[index].isPlaying = 1;
                    //         });
                    //       } else if (surahList[index].isPlaying == 1) {
                    //         result = await widget.audioPlayer!.stop();
                    //         setState(() {
                    //           for (int i = 0; i < surahList.length; i++) {
                    //             surahList[i].isPlaying = 0;
                    //           }
                    //         });
                    //       }
                    //     }
                    //     // if (surahList[index].isPlaying == 0) {
                    //     //   result = await widget.audioPlayer!.stop();
                    //     //   result = await widget.audioPlayer!
                    //     //       .play(surahList[index].url!, isLocal: true);
                    //     //   setState(() {
                    //     //     for (int i = 0; i < surahList.length; i++) {
                    //     //       surahList[i].isPlaying = 0;
                    //     //     }
                    //     //     surahList[index].isPlaying = 1;
                    //     //   });
                    //     // } else if (surahList[index].isPlaying == 1) {
                    //     //   result = await widget.audioPlayer!.stop();
                    //     //   setState(() {
                    //     //     for (int i = 0; i < surahList.length; i++) {
                    //     //       surahList[i].isPlaying = 0;
                    //     //     }
                    //     //   });
                    //     // }
                    //     // if (surahList[index].isPlaying == 0) {
                    //     //   result = await widget.audioPlayer!.stop();
                    //     //   result = await widget.audioPlayer!
                    //     //       .play(surahList[index].url!, isLocal: true);
                    //     //   setState(() {
                    //     //     for (int i = 0; i < surahList.length; i++) {
                    //     //       surahList[i].isPlaying = 0;
                    //     //     }
                    //     //     surahList[index].isPlaying = 1;
                    //     //   });
                    //     // } else if (surahList[index].isPlaying == 1) {
                    //     //   result = await widget.audioPlayer!.stop();
                    //     //   setState(() {
                    //     //     for (int i = 0; i < surahList.length; i++) {
                    //     //       surahList[i].isPlaying = 0;
                    //     //     }
                    //     //   });
                    //     // }
                    //   },
                    //   child: ListTile(
                    //     leading: Icon(Icons.music_note_outlined),
                    //     title: Text(surahList[index].title!),
                    //     subtitle: Text(surahList[index].description!),
                    //     trailing: surahList[index].isPlaying == 0
                    //         ? Icon(Icons.play_arrow)
                    //         : Icon(Icons.pause),
                    //   ),
                    // );
                  },
                );

                // return ListView.builder(
                //   physics: BouncingScrollPhysics(),
                //   padding: EdgeInsets.symmetric(vertical: 20),
                //   itemCount: snapshot.data!.length,
                //   itemBuilder: (context, index) {
                //     final name = snapshot.data![index].name;
                //     final rewaya = snapshot.data![index].rewaya;
                //     final server = snapshot.data![index].server;
                //     final reciterName = snapshot.data![index].name;
                //     final List<String> suras =
                //         snapshot.data![index].suras.split(',');

                //     // print('I am list: ${snapshot.data![index]} end');

                //     return CustomCard(
                //       title: '${name.toString()}',
                //       child: Column(
                //         children: [
                //           CustomButton(
                //             onTap: () => Navigator.push(
                //                 context,
                //                 CustomPageRoute(
                //                   child: QuranList(
                //                     // title: 'ياسر الدوسري',
                //                     title: '${name.toString()}',
                //                     server: '${server.toString()}',
                //                     listSuras: suras,
                //                     reciterName: reciterName,
                //                   ),
                //                 )),
                //             title: '${rewaya.toString()}',
                //             color: Color(0xFF00DBFF),
                //           ),
                //           const SizedBox(height: 10),
                //           reciters.hasAnotherRewaya
                //               ? CustomButton(
                //                   onTap: () {},
                //                   title: '${rewaya.toString()}',
                //                   color: Color(0xFFFEAA00),
                //                 )
                //               : Container(),
                //           reciters.hasAnotherRewaya
                //               ? CustomButton(
                //                   onTap: () {},
                //                   title: '${rewaya.toString()}',
                //                   color: Color(0xFFFEAA00),
                //                 )
                //               : Container(),
                //         ],
                //       ),
                //     );
                //   },
                // );
              }),
        ),
      ),
    );
  }
}

// // FROM SPLASH SCREEN
// class Home extends StatefulWidget {
//   @override
//   _HomeState createState() => _HomeState();
// }

// class _HomeState extends State<Home> {
//   late RecitersModel recitersModel;
//   late Future<Reciter> list;

//   @override
//   void initState() {
//     super.initState();
//     recitersModel = RecitersModel();
//     recitersModel.getNames();
//   }

//   @override
//   Widget build(BuildContext context) {
//     var reciters = context.watch<RecitersModel>();
//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           centerTitle: true,
//           leading: IconButton(
//             onPressed: () {},
//             icon: Icon(
//               Icons.search,
//               color: Color(0xFFD2E5E8),
//             ),
//           ),
//           title: Text(
//             'القرآن الكريم',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 24,
//               color: Colors.white,
//               fontWeight: FontWeight.normal,
//             ),
//           ),
//         ),
//         body: RefreshIndicator(
//           onRefresh: () =>
//               Future.delayed(Duration(seconds: 1), reciters.getAllReciters),
//           backgroundColor: Colors.white10,
//           color: Colors.greenAccent,
//           child: FutureBuilder<List<Reciter>>(
//               future: reciters.getAllReciters(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData && snapshot.data == null) {
//                   return Center(child: CircularProgressIndicator());
//                 }
//                 return ListView.builder(
//                   itemCount: snapshot.data!.length,
//                   itemBuilder: (BuildContext context, int index) {
//                     final name = snapshot.data![index].name;
//                     final rewaya = snapshot.data![index].rewaya;
//                     final server = snapshot.data![index].server;
//                     final reciterName = snapshot.data![index].name;
//                     final List<String> suras =
//                         snapshot.data![index].suras.split(',');
//                     return CustomCard(
//                       title: '${name.toString()}',
//                       child: Column(
//                         children: [
//                           CustomButton(
//                             onTap: () => Navigator.push(
//                               context,
//                               CustomPageRoute(
//                                 child: QuranList(
//                                   // title: 'ياسر الدوسري',
//                                   title: '${name.toString()}',
//                                   server: '${server.toString()}',
//                                   listSuras: suras,
//                                   reciterName: reciterName,
//                                 ),
//                               ),
//                             ),
//                             title: '${rewaya.toString()}',
//                             color: Color(0xFF00DBFF),
//                           ),
//                           const SizedBox(height: 10),
//                           reciters.hasAnotherRewaya
//                               ? CustomButton(
//                                   onTap: () {},
//                                   title: '${rewaya.toString()}',
//                                   color: Color(0xFFFEAA00),
//                                 )
//                               : Container(),
//                           reciters.hasAnotherRewaya
//                               ? CustomButton(
//                                   onTap: () {},
//                                   title: '${rewaya.toString()}',
//                                   color: Color(0xFFFEAA00),
//                                 )
//                               : Container(),
//                         ],
//                       ),
//                     );

//                     // return GestureDetector(
//                     //   onTap: () async {
//                     //     for (int i = 0; i < surahList.length; i++) {
//                     //       if (surahList[index].isPlaying == i) {
//                     //         if (widget.audioPlayer != null) {
//                     //           result = await widget.audioPlayer!.stop();
//                     //         }
//                     //         result = await widget.audioPlayer!
//                     //             .play(surahList[index].url!, isLocal: true);
//                     //         setState(() {
//                     //           for (int i = 0; i < surahList.length; i++) {
//                     //             surahList[i].isPlaying = 0;
//                     //           }
//                     //           surahList[index].isPlaying = 1;
//                     //         });
//                     //       } else if (surahList[index].isPlaying == 1) {
//                     //         result = await widget.audioPlayer!.stop();
//                     //         setState(() {
//                     //           for (int i = 0; i < surahList.length; i++) {
//                     //             surahList[i].isPlaying = 0;
//                     //           }
//                     //         });
//                     //       }
//                     //     }
//                     //     // if (surahList[index].isPlaying == 0) {
//                     //     //   result = await widget.audioPlayer!.stop();
//                     //     //   result = await widget.audioPlayer!
//                     //     //       .play(surahList[index].url!, isLocal: true);
//                     //     //   setState(() {
//                     //     //     for (int i = 0; i < surahList.length; i++) {
//                     //     //       surahList[i].isPlaying = 0;
//                     //     //     }
//                     //     //     surahList[index].isPlaying = 1;
//                     //     //   });
//                     //     // } else if (surahList[index].isPlaying == 1) {
//                     //     //   result = await widget.audioPlayer!.stop();
//                     //     //   setState(() {
//                     //     //     for (int i = 0; i < surahList.length; i++) {
//                     //     //       surahList[i].isPlaying = 0;
//                     //     //     }
//                     //     //   });
//                     //     // }
//                     //     // if (surahList[index].isPlaying == 0) {
//                     //     //   result = await widget.audioPlayer!.stop();
//                     //     //   result = await widget.audioPlayer!
//                     //     //       .play(surahList[index].url!, isLocal: true);
//                     //     //   setState(() {
//                     //     //     for (int i = 0; i < surahList.length; i++) {
//                     //     //       surahList[i].isPlaying = 0;
//                     //     //     }
//                     //     //     surahList[index].isPlaying = 1;
//                     //     //   });
//                     //     // } else if (surahList[index].isPlaying == 1) {
//                     //     //   result = await widget.audioPlayer!.stop();
//                     //     //   setState(() {
//                     //     //     for (int i = 0; i < surahList.length; i++) {
//                     //     //       surahList[i].isPlaying = 0;
//                     //     //     }
//                     //     //   });
//                     //     // }
//                     //   },
//                     //   child: ListTile(
//                     //     leading: Icon(Icons.music_note_outlined),
//                     //     title: Text(surahList[index].title!),
//                     //     subtitle: Text(surahList[index].description!),
//                     //     trailing: surahList[index].isPlaying == 0
//                     //         ? Icon(Icons.play_arrow)
//                     //         : Icon(Icons.pause),
//                     //   ),
//                     // );
//                   },
//                 );

//                 // return ListView.builder(
//                 //   physics: BouncingScrollPhysics(),
//                 //   padding: EdgeInsets.symmetric(vertical: 20),
//                 //   itemCount: snapshot.data!.length,
//                 //   itemBuilder: (context, index) {
//                 //     final name = snapshot.data![index].name;
//                 //     final rewaya = snapshot.data![index].rewaya;
//                 //     final server = snapshot.data![index].server;
//                 //     final reciterName = snapshot.data![index].name;
//                 //     final List<String> suras =
//                 //         snapshot.data![index].suras.split(',');

//                 //     // print('I am list: ${snapshot.data![index]} end');

//                 //     return CustomCard(
//                 //       title: '${name.toString()}',
//                 //       child: Column(
//                 //         children: [
//                 //           CustomButton(
//                 //             onTap: () => Navigator.push(
//                 //                 context,
//                 //                 CustomPageRoute(
//                 //                   child: QuranList(
//                 //                     // title: 'ياسر الدوسري',
//                 //                     title: '${name.toString()}',
//                 //                     server: '${server.toString()}',
//                 //                     listSuras: suras,
//                 //                     reciterName: reciterName,
//                 //                   ),
//                 //                 )),
//                 //             title: '${rewaya.toString()}',
//                 //             color: Color(0xFF00DBFF),
//                 //           ),
//                 //           const SizedBox(height: 10),
//                 //           reciters.hasAnotherRewaya
//                 //               ? CustomButton(
//                 //                   onTap: () {},
//                 //                   title: '${rewaya.toString()}',
//                 //                   color: Color(0xFFFEAA00),
//                 //                 )
//                 //               : Container(),
//                 //           reciters.hasAnotherRewaya
//                 //               ? CustomButton(
//                 //                   onTap: () {},
//                 //                   title: '${rewaya.toString()}',
//                 //                   color: Color(0xFFFEAA00),
//                 //                 )
//                 //               : Container(),
//                 //         ],
//                 //       ),
//                 //     );
//                 //   },
//                 // );
//               }),
//         ),
//       ),
//     );
//   }
// }
