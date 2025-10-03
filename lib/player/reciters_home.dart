import 'package:flutter/material.dart';

class SaavnHomePage extends StatefulWidget {
  @override
  State<SaavnHomePage> createState() => _SaavnHomePageState();
}

class _SaavnHomePageState extends State<SaavnHomePage> {
  @override
  Widget build(BuildContext context) {
    final double boxSize =
        MediaQuery.of(context).size.height > MediaQuery.of(context).size.width
        ? MediaQuery.of(context).size.width
        : MediaQuery.of(context).size.height;
    return Scaffold(
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        itemCount: 1,
        itemBuilder: (context, idx) {
          return Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 10, 0, 5),
                    child: Text(
                      '123',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: boxSize / 2 + 10,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onLongPress: () {},
                      onTap: () {
                        print('I am pressed!');
                        // ShowSnackBar().showSnackBar(
                        //   context,
                        //   'Connecting!!!',
                        //   duration: const Duration(seconds: 2),
                        // );

                        // if (item['type'] == 'radio_station') {
                        //   ShowSnackBar().showSnackBar(
                        //     context,
                        //     'Connecting to Radio...',
                        //     duration: const Duration(seconds: 2),
                        //   );
                        //   SaavnAPI()
                        //       .createRadio(
                        //     item['more_info']['featured_station_type']
                        //                 .toString() ==
                        //             'artist'
                        //         ? item['more_info']['query'].toString()
                        //         : item['id'].toString(),
                        //     item['more_info']['language']?.toString() ??
                        //         'hindi',
                        //     item['more_info']['featured_station_type']
                        //         .toString(),
                        //   )
                        //       .then((value) {
                        //     if (value != null) {
                        //       SaavnAPI().getRadioSongs(value).then((value) {
                        //         //TODO: Will go to single audio
                        //         //   return Navigator.push(
                        //         //     context,
                        //         //     PageRouteBuilder(
                        //         //         opaque: false,
                        //         //         pageBuilder: (_, __, ___) => PlayPage(
                        //         //               data: {
                        //         //                 'response': value,
                        //         //                 'index': 0,
                        //         //                 'offline': false,
                        //         //               },
                        //         //               fromMiniplayer: false,
                        //         //             )),
                        //         //   );
                        //       });
                        //     }
                        //   });
                        // } else
                        // {
                      },
                      child: SizedBox(
                        width: boxSize / 2 - 30,
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                const Card(
                                  elevation: 5,
                                  clipBehavior: Clip.antiAlias,
                                ),
                                const Text(
                                  '789',
                                  textAlign: TextAlign.center,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'subTitle',
                                  textAlign: TextAlign.center,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge!.color,
                                  ),
                                ),
                              ],
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.favorite_rounded,
                                  color: Colors.red,
                                ),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
