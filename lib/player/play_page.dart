import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:muzakri/main.dart';
import 'package:rxdart/rxdart.dart';

import '../common.dart';

class PlayPage extends StatefulWidget {
  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<MediaItem?>(
          stream: globalAudioHandler.mediaItem,
          builder: (context, snapshot) {
            final MediaItem? mediaItem = snapshot.data;
            if (mediaItem == null) {
              return Container(
                width: 200,
                height: 500,
                color: Colors.blue,
              );
            }
            return Scaffold(
              // appBar: AppBar(),
              backgroundColor: Colors.green,
              body: Builder(builder: (BuildContext context) {
                // scaffoldContext = context;
                return LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  return NameNControls(
                    mediaItem,
                    offline: true,
                  );
                });
              }),

              // }
            );
            // );
          }),
    );
  }

  Future<dynamic> setTimer(
      BuildContext context, BuildContext? scaffoldContext) {
    return showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Center(
              child: Text(
            'Select a Duration',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary),
          )),
          children: [
            Center(
                child: SizedBox(
              height: 200,
              width: 200,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  primaryColor: Theme.of(context).colorScheme.secondary,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  onTimerDurationChanged: (value) {},
                ),
              ),
            )),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(
                  width: 10,
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Ok'),
                ),
                const SizedBox(
                  width: 20,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

class QueueState {
  static const QueueState empty =
      QueueState([], 0, [], AudioServiceRepeatMode.none);

  final List<MediaItem> queue;
  final int? queueIndex;
  final List<int>? shuffleIndices;
  final AudioServiceRepeatMode repeatMode;

  const QueueState(
      this.queue, this.queueIndex, this.shuffleIndices, this.repeatMode);

  bool get hasPrevious =>
      repeatMode != AudioServiceRepeatMode.none || (queueIndex ?? 0) > 0;
  bool get hasNext =>
      repeatMode != AudioServiceRepeatMode.none ||
      (queueIndex ?? 0) + 1 < queue.length;

  List<int> get indices =>
      shuffleIndices ?? List.generate(queue.length, (i) => i);
}

class ControlButt extends StatelessWidget {
  final AudioPlayerHandler controlAudioHandler;
  final bool shuffle;
  final bool miniplayer;

  const ControlButt(this.controlAudioHandler,
      {this.shuffle = false, this.miniplayer = false});

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<QueueState>(
            stream: controlAudioHandler.queueState,
            builder: (context, snapshot) {
              final queueState = snapshot.data ?? QueueState.empty;
              return IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: miniplayer ? 24.0 : 45.0,
                tooltip: 'Skip Previous',
                onPressed: queueState.hasPrevious
                    ? globalAudioHandler.skipToPrevious
                    : null,
              );
            },
          ),
          SizedBox(
            height: miniplayer ? 40.0 : 65.0,
            width: miniplayer ? 40.0 : 65.0,
            child: StreamBuilder<PlaybackState>(
                stream: controlAudioHandler.playbackState,
                builder: (context, snapshot) {
                  final playbackState = snapshot.data;
                  final processingState = playbackState?.processingState;
                  final playing = playbackState?.playing ?? false;
                  return Stack(
                    children: [
                      if (processingState == AudioProcessingState.loading ||
                          processingState == AudioProcessingState.buffering)
                        Center(
                          child: SizedBox(
                            height: miniplayer ? 40.0 : 65.0,
                            width: miniplayer ? 40.0 : 65.0,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.secondary),
                            ),
                          ),
                        ),
                      if (miniplayer)
                        Center(
                            child: playing
                                ? IconButton(
                                    tooltip: 'Pause',
                                    onPressed: globalAudioHandler.pause,
                                    icon: const Icon(
                                      Icons.pause_rounded,
                                    ),
                                  )
                                : IconButton(
                                    tooltip: 'Play',
                                    onPressed: controlAudioHandler.play,
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                    ),
                                  ))
                      else
                        Center(
                          child: SizedBox(
                              height: 59,
                              width: 59,
                              child: Center(
                                child: playing
                                    ? FloatingActionButton(
                                        elevation: 10,
                                        tooltip: 'Pause',
                                        onPressed: globalAudioHandler.pause,
                                        child: const Icon(
                                          Icons.pause_rounded,
                                          size: 40.0,
                                          color: Colors.white,
                                        ),
                                      )
                                    : FloatingActionButton(
                                        elevation: 10,
                                        tooltip: 'Play',
                                        onPressed: controlAudioHandler.play,
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 40.0,
                                          color: Colors.white,
                                        ),
                                      ),
                              )),
                        ),
                    ],
                  );
                }),
          ),
          StreamBuilder<QueueState>(
            stream: controlAudioHandler.queueState,
            builder: (context, snapshot) {
              final queueState = snapshot.data ?? QueueState.empty;
              return IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: miniplayer ? 24.0 : 45.0,
                tooltip: 'Skip Next',
                onPressed:
                    queueState.hasNext ? globalAudioHandler.skipToNext : null,
              );
            },
          ),
        ]);
  }
}

abstract class AudioPlayerHandler implements AudioHandler {
  Stream<QueueState> get queueState;
  Future<void> moveQueueItem(int currentIndex, int newIndex);
  ValueStream<double> get volume;
  Future<void> setVolume(double volume);
  ValueStream<double> get speed;
}

class NowPlayingStream extends StatelessWidget {
  final AudioPlayerHandler audioHandlers;
  final bool hideHeader;

  const NowPlayingStream(this.audioHandlers, {this.hideHeader = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QueueState>(
        stream: audioHandlers.queueState,
        builder: (context, snapshot) {
          final queueState = snapshot.data ?? QueueState.empty;
          final queue = queueState.queue;
          return ReorderableListView.builder(
              header: hideHeader
                  ? null
                  : SizedBox(
                      key: const Key('head'),
                      height: 50,
                      child: Center(
                        child: SizedBox.expand(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).iconTheme.color,
                              backgroundColor: Colors.transparent,
                              elevation: 0.0,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Now Playing',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              onReorder: (int oldIndex, int newIndex) {
                if (oldIndex < newIndex) {
                  newIndex--;
                }
                audioHandlers.moveQueueItem(oldIndex, newIndex);
              },
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 10),
              shrinkWrap: true,
              itemCount: queue.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: ValueKey(queue[index].id),
                  direction: index == queueState.queueIndex
                      ? DismissDirection.none
                      : DismissDirection.horizontal,
                  onDismissed: (dir) {
                    audioHandlers.removeQueueItemAt(index);
                  },
                  child: ListTileTheme(
                    selectedColor: Theme.of(context).colorScheme.secondary,
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.only(left: 16.0, right: 10.0),
                      selected: index == queueState.queueIndex,
                      trailing: index == queueState.queueIndex
                          ? IconButton(
                              icon: const Icon(
                                Icons.bar_chart_rounded,
                              ),
                              tooltip: 'Playing',
                              onPressed: () {},
                            )
                          : queue[index]
                                  .extras!['url']
                                  .toString()
                                  .startsWith('http')
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    // DownloadButton(icon: 'download', data: {
                                    //   'id': queue[index].id.toString(),
                                    //   'artist': queue[index].artist.toString(),
                                    //   'album': queue[index].album.toString(),
                                    //   'image': queue[index].artUri.toString(),
                                    //   'duration': queue[index]
                                    //       .duration!
                                    //       .inSeconds
                                    //       .toString(),
                                    //   'title': queue[index].title.toString(),
                                    //   'url': queue[index]
                                    //       .extras?['url']
                                    //       .toString(),
                                    //   'year': queue[index]
                                    //       .extras?['year']
                                    //       .toString(),
                                    //   'language': queue[index]
                                    //       .extras?['language']
                                    //       .toString(),
                                    //   'genre': queue[index].genre?.toString(),
                                    //   '320kbps':
                                    //       queue[index].extras?['320kbps'],
                                    //   'has_lyrics':
                                    //       queue[index].extras?['has_lyrics'],
                                    //   'release_date':
                                    //       queue[index].extras?['release_date'],
                                    //   'album_id':
                                    //       queue[index].extras?['album_id'],
                                    //   'subtitle':
                                    //       queue[index].extras?['subtitle']
                                    // })
                                  ],
                                )
                              : const SizedBox(),
                      leading: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (queue[index].artUri == null)
                            ? const SizedBox(
                                height: 50.0,
                                width: 50.0,
                                child: Image(
                                  image: AssetImage('assets/cover.jpg'),
                                ),
                              )
                            : SizedBox(
                                height: 50.0,
                                width: 50.0,
                                child: queue[index]
                                        .artUri
                                        .toString()
                                        .startsWith('file:')
                                    ? Image(
                                        fit: BoxFit.cover,
                                        image: FileImage(File(
                                            queue[index].artUri!.toFilePath())))
                                    : CachedNetworkImage(
                                        fit: BoxFit.cover,
                                        errorWidget:
                                            (BuildContext context, _, __) =>
                                                const Image(
                                          image: AssetImage('assets/cover.jpg'),
                                        ),
                                        placeholder:
                                            (BuildContext context, _) =>
                                                const Image(
                                          image: AssetImage('assets/cover.jpg'),
                                        ),
                                        imageUrl:
                                            queue[index].artUri.toString(),
                                      ),
                              ),
                      ),
                      title: Text(
                        queue[index].title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: index == queueState.queueIndex
                                ? FontWeight.w600
                                : FontWeight.normal),
                      ),
                      subtitle: Text(
                        queue[index].artist!,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        audioHandlers.skipToQueueItem(index);
                      },
                    ),
                  ),
                );
              });
        });
  }
}

// class ArtWorkWidget extends StatefulWidget {
//   final GlobalKey<FlipCardState> cardKey;
//   final MediaItem mediaItem;
//   final bool offline;
//   final double width;

//   const ArtWorkWidget(this.cardKey, this.mediaItem, this.width,
//       {this.offline = false});

//   @override
//   _ArtWorkWidgetState createState() => _ArtWorkWidgetState();
// }

// class _ArtWorkWidgetState extends State<ArtWorkWidget> {
//   final ValueNotifier<bool> dragging = ValueNotifier<bool>(false);
//   final ValueNotifier<bool> done = ValueNotifier<bool>(false);
//   Map lyrics = {'id': '', 'lyrics': ''};

//   Future<String> fetchLyrics() async {
//     return Lyrics().getLyrics(
//         widget.mediaItem.title.toString(), widget.mediaItem.artist.toString());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: widget.width * 0.9,
//       child: Align(
//         alignment: Alignment.topCenter,
//         child: SizedBox(
//           height: widget.width * 0.85,
//           width: widget.width * 0.85,
//           child: Hero(
//             tag: 'currentArtwork',
//             child: FlipCard(
//               key: widget.cardKey,
//               flipOnTouch: false,
//               onFlipDone: (value) {
//                 if (lyrics['id'] != widget.mediaItem.id ||
//                     (!value && lyrics['lyrics'] == '' && !done.value)) {
//                   done.value = false;
//                   fetchLyrics().then((value) {
//                     lyrics['lyrics'] = value;
//                     lyrics['id'] = widget.mediaItem.id;
//                     done.value = true;
//                   });
//                 }
//               },
//               back: GestureDetector(
//                 onTap: () => widget.cardKey.currentState!.toggleCard(),
//                 onDoubleTap: () => widget.cardKey.currentState!.toggleCard(),
//                 child: Card(
//                   elevation: 10.0,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15.0)),
//                   clipBehavior: Clip.antiAlias,
//                   child: GradientContainer(
//                     child: ShaderMask(
//                       shaderCallback: (rect) {
//                         return const LinearGradient(
//                           begin: Alignment.center,
//                           end: Alignment.bottomCenter,
//                           colors: [Colors.black, Colors.transparent],
//                         ).createShader(
//                             Rect.fromLTRB(0, 0, rect.width, rect.height));
//                       },
//                       blendMode: BlendMode.dstIn,
//                       child: Center(
//                         child: SingleChildScrollView(
//                           physics: const BouncingScrollPhysics(),
//                           padding: const EdgeInsets.fromLTRB(10, 20, 10, 50),
//                           child: widget.offline
//                               ? FutureBuilder(
//                                   future: Lyrics().getOffLyrics(
//                                     widget.mediaItem.id.toString(),
//                                   ),
//                                   builder: (BuildContext context,
//                                       AsyncSnapshot<String> snapshot) {
//                                     if (snapshot.connectionState ==
//                                         ConnectionState.done) {
//                                       final String lyrics = snapshot.data ?? '';

//                                       return SelectableText(
//                                         lyrics,
//                                         textAlign: TextAlign.center,
//                                       );
//                                     }
//                                     return CircularProgressIndicator(
//                                       valueColor: AlwaysStoppedAnimation<Color>(
//                                           Theme.of(context)
//                                               .colorScheme
//                                               .secondary),
//                                     );
//                                   })
//                               : widget.mediaItem.extras?['has_lyrics'] == 'true'
//                                   ? FutureBuilder(
//                                       future: Lyrics().getSaavnLyrics(
//                                           widget.mediaItem.id.toString()),
//                                       builder: (BuildContext context,
//                                           AsyncSnapshot<String> snapshot) {
//                                         String? lyrics;
//                                         if (snapshot.connectionState ==
//                                             ConnectionState.done) {
//                                           lyrics = snapshot.data;
//                                           return Text(
//                                             lyrics!,
//                                             textAlign: TextAlign.center,
//                                           );
//                                         }
//                                         return CircularProgressIndicator(
//                                           valueColor:
//                                               AlwaysStoppedAnimation<Color>(
//                                                   Theme.of(context)
//                                                       .colorScheme
//                                                       .secondary),
//                                         );
//                                       })
//                                   : ValueListenableBuilder(
//                                       valueListenable: done,
//                                       builder: (BuildContext context,
//                                           bool value, Widget? child) {
//                                         return Text(
//                                           lyrics['lyrics'].toString(),
//                                           textAlign: TextAlign.center,
//                                         );
//                                       }),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               front: StreamBuilder<QueueState>(
//                   stream: globalAudioHandler.queueState,
//                   builder: (context, snapshot) {
//                     final queueState = snapshot.data ?? QueueState.empty;
//                     return GestureDetector(
//                       onTap: () {
//                         globalAudioHandler.playbackState.value.playing
//                             ? globalAudioHandler.pause()
//                             : globalAudioHandler.play();
//                       },
//                       onDoubleTap: () =>
//                           widget.cardKey.currentState!.toggleCard(),
//                       onHorizontalDragEnd: (DragEndDetails details) {
//                         if ((details.primaryVelocity ?? 0) > 100) {
//                           if (queueState.hasPrevious) {
//                             globalAudioHandler.skipToPrevious();
//                           }
//                         }

//                         if ((details.primaryVelocity ?? 0) < -100) {
//                           if (queueState.hasNext) {
//                             globalAudioHandler.skipToNext();
//                           }
//                         }
//                       },
//                       onLongPress: () {},
//                       onVerticalDragStart: (_) {
//                         dragging.value = true;
//                       },
//                       onVerticalDragEnd: (_) {
//                         dragging.value = false;
//                       },
//                       onVerticalDragUpdate: (DragUpdateDetails details) {
//                         if (details.delta.dy != 0.0) {
//                           double volume = globalAudioHandler.volume.value;
//                           volume -= details.delta.dy / 150;
//                           if (volume < 0) {
//                             volume = 0;
//                           }
//                           if (volume > 1.0) {
//                             volume = 1.0;
//                           }
//                           globalAudioHandler.setVolume(volume);
//                         }
//                       },
//                       child: Stack(
//                         children: [
//                           Card(
//                             elevation: 10.0,
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(15.0)),
//                             clipBehavior: Clip.antiAlias,
//                             child: widget.mediaItem.artUri
//                                     .toString()
//                                     .startsWith('file')
//                                 ? Image(
//                                     fit: BoxFit.cover,
//                                     height: widget.width * 0.85,
//                                     width: widget.width * 0.85,
//                                     image: FileImage(File(
//                                         widget.mediaItem.artUri!.toFilePath())))
//                                 : CachedNetworkImage(
//                                     fit: BoxFit.cover,
//                                     errorWidget:
//                                         (BuildContext context, _, __) =>
//                                             const Image(
//                                       image: AssetImage('assets/cover.jpg'),
//                                     ),
//                                     placeholder: (BuildContext context, _) =>
//                                         const Image(
//                                       image: AssetImage('assets/cover.jpg'),
//                                     ),
//                                     imageUrl:
//                                         widget.mediaItem.artUri.toString(),
//                                     height: widget.width * 0.85,
//                                   ),
//                           ),
//                           ValueListenableBuilder(
//                               valueListenable: dragging,
//                               builder: (BuildContext context, bool value,
//                                   Widget? child) {
//                                 return Visibility(
//                                   visible: value,
//                                   child: StreamBuilder<double>(
//                                       stream: globalAudioHandler.volume,
//                                       builder: (context, snapshot) {
//                                         final double volumeValue =
//                                             snapshot.data ?? 1.0;
//                                         return Center(
//                                           child: SizedBox(
//                                             width: 60.0,
//                                             height: MediaQuery.of(context)
//                                                     .size
//                                                     .width *
//                                                 0.7,
//                                             child: Card(
//                                               color: Colors.black87,
//                                               shape: RoundedRectangleBorder(
//                                                 borderRadius:
//                                                     BorderRadius.circular(10.0),
//                                               ),
//                                               clipBehavior: Clip.antiAlias,
//                                               child: Column(
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment.center,
//                                                 mainAxisSize: MainAxisSize.min,
//                                                 children: [
//                                                   Expanded(
//                                                     child: FittedBox(
//                                                       fit: BoxFit.fitHeight,
//                                                       child: RotatedBox(
//                                                         quarterTurns: -1,
//                                                         child: SliderTheme(
//                                                           data: SliderTheme.of(
//                                                                   context)
//                                                               .copyWith(
//                                                             thumbShape:
//                                                                 HiddenThumbComponentShape(),
//                                                             activeTrackColor:
//                                                                 Theme.of(
//                                                                         context)
//                                                                     .colorScheme
//                                                                     .secondary,
//                                                             inactiveTrackColor:
//                                                                 Theme.of(
//                                                                         context)
//                                                                     .colorScheme
//                                                                     .secondary
//                                                                     .withOpacity(
//                                                                         0.4),
//                                                             trackShape:
//                                                                 const RoundedRectSliderTrackShape(),
//                                                           ),
//                                                           child:
//                                                               ExcludeSemantics(
//                                                             child: Slider(
//                                                               value:
//                                                                   globalAudioHandler
//                                                                       .volume
//                                                                       .value,
//                                                               onChanged: (_) {},
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ),
//                                                   Padding(
//                                                     padding:
//                                                         const EdgeInsets.only(
//                                                             bottom: 20.0),
//                                                     child: Icon(volumeValue == 0
//                                                         ? Icons
//                                                             .volume_off_rounded
//                                                         : volumeValue > 0.6
//                                                             ? Icons
//                                                                 .volume_up_rounded
//                                                             : Icons
//                                                                 .volume_down_rounded),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           ),
//                                         );
//                                       }),
//                                 );
//                               }),
//                         ],
//                       ),
//                     );
//                   }),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class NameNControls extends StatelessWidget {
  final MediaItem mediaItem;
  final bool offline;

  const NameNControls(this.mediaItem, {this.offline = false});

  Stream<Duration> get _bufferedPositionStream =>
      globalAudioHandler.playbackState
          .map((state) => state.bufferedPosition)
          .distinct();
  Stream<Duration?> get _durationStream =>
      globalAudioHandler.mediaItem.map((item) => item?.duration).distinct();
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          AudioService.position,
          _bufferedPositionStream,
          _durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        /// Title and subtitle
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(35, 5, 35, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  /// Title container
                  Text(
                    mediaItem.title.split(' (')[0],
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),

                  /// Subtitle container
                  Text(
                    mediaItem.artist ?? 'Unknown',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

        /// Seekbar starts from here
        StreamBuilder<PositionData>(
          stream: _positionDataStream,
          builder: (context, snapshot) {
            final positionData = snapshot.data ??
                PositionData(Duration.zero, Duration.zero,
                    mediaItem.duration ?? Duration.zero);
            return SeekBar(
              duration: positionData.duration,
              position: positionData.position,
              onChangeEnd: (newPosition) {
                globalAudioHandler.seek(newPosition);
              },
            );
          },
        ),

        /// Final row starts from here
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 6.0),
                  StreamBuilder<bool>(
                    stream: globalAudioHandler.playbackState
                        .map((state) =>
                            state.shuffleMode == AudioServiceShuffleMode.all)
                        .distinct(),
                    builder: (context, snapshot) {
                      final shuffleModeEnabled = snapshot.data ?? false;
                      return IconButton(
                        icon: shuffleModeEnabled
                            ? Icon(Icons.shuffle,
                                color: Theme.of(context).colorScheme.secondary)
                            : const Icon(
                                Icons.shuffle,
                              ),
                        tooltip: 'Shuffle!!!',
                        onPressed: () async {
                          final enable = !shuffleModeEnabled;
                          await globalAudioHandler.setShuffleMode(enable
                              ? AudioServiceShuffleMode.all
                              : AudioServiceShuffleMode.none);
                        },
                      );
                    },
                  ),
                ],
              ),
              ControlButt(globalAudioHandler),
              Column(
                children: [
                  const SizedBox(height: 6.0),
                  StreamBuilder<AudioServiceRepeatMode>(
                    stream: globalAudioHandler.playbackState
                        .map((state) => state.repeatMode)
                        .distinct(),
                    builder: (context, snapshot) {
                      final repeatMode =
                          snapshot.data ?? AudioServiceRepeatMode.none;
                      const texts = ['None', 'All', 'One'];
                      final icons = [
                        const Icon(
                          Icons.repeat_rounded,
                        ),
                        Icon(Icons.repeat_rounded,
                            color: Theme.of(context).colorScheme.secondary),
                        Icon(Icons.repeat_one_rounded,
                            color: Theme.of(context).colorScheme.secondary),
                      ];
                      const cycleModes = [
                        AudioServiceRepeatMode.none,
                        AudioServiceRepeatMode.all,
                        AudioServiceRepeatMode.one,
                      ];
                      final index = cycleModes.indexOf(repeatMode);
                      return IconButton(
                        icon: icons[index],
                        tooltip: 'Repeat ${texts[(index + 1) % texts.length]}',
                        onPressed: () {
                          globalAudioHandler.setRepeatMode(cycleModes[
                              (cycleModes.indexOf(repeatMode) + 1) %
                                  cycleModes.length]);
                        },
                      );
                    },
                  ),
                  // if (!offline)
                  // DownloadButton(data: {
                  //   'id': mediaItem.id.toString(),
                  //   'artist': mediaItem.artist.toString(),
                  //   'album': mediaItem.album.toString(),
                  //   'image': mediaItem.artUri.toString(),
                  //   'duration': mediaItem.duration?.inSeconds.toString(),
                  //   'title': mediaItem.title.toString(),
                  //   'url': mediaItem.extras!['url'].toString(),
                  //   'year': mediaItem.extras!['year'].toString(),
                  //   'language': mediaItem.extras!['language'].toString(),
                  //   'genre': mediaItem.genre?.toString(),
                  //   '320kbps': mediaItem.extras?['320kbps'],
                  //   'has_lyrics': mediaItem.extras?['has_lyrics'],
                  //   'release_date': mediaItem.extras!['release_date'],
                  //   'album_id': mediaItem.extras!['album_id'],
                  //   'subtitle': mediaItem.extras!['subtitle']
                  // })
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
