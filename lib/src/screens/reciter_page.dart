import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:muzakri/player/play_page.dart';
import 'package:muzakri/src/widgets/common.dart';
import 'package:muzakri/src/widgets/control_player.dart';
import 'package:rxdart/rxdart.dart';

import '../../main.dart';

class ReciterPage extends StatefulWidget {
  const ReciterPage({required this.urlList, required this.server});

  final List<String> urlList;
  final String server;

  @override
  State<ReciterPage> createState() => _ReciterPageState();
}

class _ReciterPageState extends State<ReciterPage> with WidgetsBindingObserver {
  late AudioPlayer _player;

  late AudioSource _audioSource;

  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();
    ambiguate(WidgetsBinding.instance)!.addObserver(this);
    _audioSource = AudioSource.uri(
      Uri.parse(
        "${widget.server}/${widget.urlList[0].toString().padLeft(3, '0')}.mp3",
      ),
      tag: MediaItem(
        id: "789",
        album: 'https://server8.mp3quran.net/ahmad_huth/001.mp3',
        title: "الفاااااتحة",
        duration: const Duration(milliseconds: 60000),
      ),
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.black),
    );
    _init();
  }

  @override
  void dispose() {
    ambiguate(WidgetsBinding.instance)?.removeObserver(this);
    // _audioPlayer!.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    _player.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace stackTrace) {
        print('A stream error occurred: $e');
      },
    );
    try {
      bool isPlaying = _player.playerState.playing;
      print('isPlaying: $isPlaying end');
      if (!isPlaying) {
        _player.setAudioSources([_audioSource]);
      } else {
        print('I am _audioPlayer: $_player end');
      }
    } on PlatformException catch (e) {
      print('I am error ${e.toString()} end');
    }
    // catch (e, stackTrace) {
    //   // Catch load errors: 404, invalid url ...
    //   print("Error loading playlist: $e");
    //   print(stackTrace);
    // }
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [
          // IconButton(
          //     onPressed: () => Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => Home(),
          //         )),
          //     icon: Icon(
          //       Icons.arrow_back,
          //     )),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Playlist
            Container(
              color: Colors.red,
              height: 350.0,
              child: StreamBuilder<QueueState>(
                stream: globalAudioHandler.queueState,
                builder: (context, snapshot) {
                  final queueState = snapshot.data ?? QueueState.empty;
                  final queue = queueState.queue;
                  return ReorderableListView(
                    onReorder: (int oldIndex, int newIndex) {
                      if (oldIndex < newIndex) newIndex--;
                      globalAudioHandler.moveQueueItem(oldIndex, newIndex);
                    },
                    children: [
                      for (var i = 0; i < queue.length; i++)
                        Dismissible(
                          key: ValueKey(queue[i].id),
                          background: Container(
                            color: Colors.redAccent,
                            alignment: Alignment.centerRight,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                          ),
                          onDismissed: (dismissDirection) {
                            globalAudioHandler.removeQueueItemAt(i);
                          },
                          child: Material(
                            color: i == queueState.queueIndex
                                ? Colors.grey.shade300
                                : null,
                            child: ListTile(
                              title: Text(queue[i].title),
                              onTap: () =>
                                  globalAudioHandler.skipToQueueItem(i),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Expanded(
            //   child: Container(
            //     height: 333,
            //     child: StreamBuilder<SequenceState?>(
            //       stream: _audioPlayer!.sequenceStateStream,
            //       builder: (context, snapshot) {
            //         final state = snapshot.data;
            //         final sequence = state?.sequence ?? [];

            //         return ListView.builder(
            //           itemCount: sequence.length,
            //           itemBuilder: (context, index) {
            //             return Card(
            //               child: ListTile(
            //                 title: Text(sequence[index].tag.title as String),
            //                 onTap: () async {
            //                   //TODO: play me
            //                   await _audioPlayer!
            //                       .seek(
            //                     Duration.zero,
            //                     index: index,
            //                   )
            //                       .then((value) {
            //                     globalAudioHandler.play();
            //                   });
            //                 },
            //               ),
            //             );
            //           },
            //         );
            //       },
            //     ),
            //   ),
            // ),

            // Player & Slider
            Column(
              children: [
                // ControlButt(globalAudioHandler),
                // _ControlButtons(globalAudioHandler),
                ControlButtons(globalAudioHandler),

                // Slider
                Container(
                  color: Colors.green,
                  child: StreamBuilder<PositionData>(
                    stream: _positionDataStream,
                    builder: (context, snapshot) {
                      final positionData = snapshot.data;
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: ProgressBar(
                          progress: positionData?.position ?? Duration.zero,
                          total: positionData?.duration ?? Duration.zero,
                          onSeek: (duration) {
                            globalAudioHandler.seek(duration);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
