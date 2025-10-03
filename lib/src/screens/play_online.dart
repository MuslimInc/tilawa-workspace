import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../widgets/play_pause_button.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

class PlayOnline extends StatefulWidget {
  const PlayOnline({
    required this.surahTitle,
    required this.rewaya,
    required this.singleSurahUrl,
    required this.reciterName,
  });
  final String surahTitle;
  final String rewaya;
  final String singleSurahUrl;
  final String reciterName;

  @override
  State<PlayOnline> createState() => _PlayOnlineState();
}

class _PlayOnlineState extends State<PlayOnline> {
  @override
  void initState() {
    super.initState();
    print('I am player: ${widget.singleSurahUrl} end');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Container(
            decoration: const BoxDecoration(
              // gradient: LinearGradient(
              //   colors: [
              //     Colors.pink.shade800,
              //     Colors.purple.shade900,
              //   ],
              // ),
            ),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // const SizedBox(height: 30),
                // _BackButton(),
                const SizedBox(height: 30),
                _SurahDetails(
                  surahTitle: widget.surahTitle,
                  rewaya: widget.rewaya,
                ),
                const SizedBox(height: 30),
                _PlayerWidget(
                  urlAudio: widget.singleSurahUrl,
                  reciterName: widget.reciterName,
                ),
                const SizedBox(height: 10.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahDetails extends StatelessWidget {
  const _SurahDetails({required this.surahTitle, required this.rewaya});
  final String surahTitle;
  final String rewaya;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          // color: Color(0xFF323777).withOpacity(0.39),
          borderRadius: BorderRadius.all(Radius.circular(7.0)),
        ),
        child: Column(
          children: [
            Text(
              surahTitle.toString(),
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              rewaya.toString(),
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerWidget extends StatefulWidget {
  const _PlayerWidget({required this.urlAudio, required this.reciterName});
  final String urlAudio;

  final String reciterName;
  @override
  __PlayerWidgetState createState() => __PlayerWidgetState();
}

class __PlayerWidgetState extends State<_PlayerWidget> {
  AudioPlayer justPlayer = AudioPlayer();

  List<AudioPlayer> audioPlayers = [AudioPlayer()];

  @override
  void initState() {
    super.initState();
    // justPlayer = AudioPlayer();

    initAudio();
    // justPlayer.setUrl(widget.urlAudio).then((value) => justPlayer.play());
    // disposeMe(justPlayer);

    // // Test
    // AudioSession.instance.then((audioSession) async {
    //   // This line configures the app's audio session, indicating to the OS the
    //   // type of audio we intend to play. Using the "speech" recipe rather than
    //   // "music" since we are playing a podcast.
    //   await audioSession.configure(AudioSessionConfiguration.speech());
    //   // Listen to audio interruptions and pause or duck as appropriate.
    //   justPlayer.playingStream.first.then((value) {
    //     if (value == true) {
    //       justPlayer.stop();
    //     } else {
    //       justPlayer.setUrl(widget.urlAudio).then(
    //         (value) {
    //           // return justPlayer.play();
    //         },
    //       );
    //     }
    //   });
    //   _handleInterruptions(audioSession);
    //   // Use another plugin to load audio to play.
    // });
  }

  Future<void> disposeMe(AudioPlayer player) async {
    player.playingStream.forEach((playingStatus) {
      print('Playing status: $playingStatus end');
      if (playingStatus == true) {
        if (mounted) {
          setState(() {
            // player.dispose();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            // player.play();
          });
        }
      }
    });
    // if (isPlaying != null && isPlaying == true) {
    //   await player.dispose();
    // }
  }

  Future<void> initAudio() async {
    try {
      if (justPlayer.playing) {
        print('I am playinnnng!');
        // await justPlayer
        //     .setUrl(widget.urlAudio)
        //     .then((value) => justPlayer.play());
      } else if (!justPlayer.playing && widget.urlAudio != '') {
        await justPlayer
            .setUrl(widget.urlAudio)
            .then((value) => justPlayer.play());
      }
    } catch (e) {
      print('I am errooor: ${e.toString()} end');
    }
  }

  @override
  void dispose() {
    // justPlayer.dispose();
    super.dispose();
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        justPlayer.positionStream,
        justPlayer.bufferedPositionStream,
        justPlayer.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.57,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        decoration: const BoxDecoration(
          // color: Color(0xFF292927),
          borderRadius: BorderRadius.all(Radius.circular(7)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.reciterName.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'TheSans',
                fontSize: 30.0,
              ),
            ),
            const SizedBox(height: 70.0),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFF323746),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.skip_next, color: Colors.white),
                  ),
                  // Container(
                  //   child: StreamBuilder(
                  //     stream: justPlayer.playingStream,
                  //     builder: (BuildContext context, AsyncSnapshot snapshot) {
                  //       if (snapshot.data == null) {
                  //         return Container();
                  //       }
                  //       return Container(
                  //         height: 120,
                  //         child: Text(
                  //           '${snapshot.data.toString()}',
                  //           style: TextStyle(
                  //             color: Colors.white,
                  //             fontSize: 39,
                  //           ),
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),
                  StreamBuilder<PlayerState>(
                    stream: justPlayer.playerStateStream,
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final PlayerState playerState = snapshot.data;
                        print('I AM: $playerState END');
                        return PlayPauseButton(
                          playerState: playerState,
                          audioPlayer: justPlayer,
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.all(7.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFF323746),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.skip_previous, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),
            // ProgressBar
            StreamBuilder<PositionData>(
              stream: _positionDataStream,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final PositionData positionData = snapshot.data;
                  return ProgressBar(
                    progress: positionData.position,
                    buffered: positionData.bufferedPosition,
                    total: positionData.duration,
                    onSeek: justPlayer.seek,
                    timeLabelPadding: 17.0,
                    timeLabelTextStyle: const TextStyle(color: Colors.white),
                    progressBarColor: const Color(0xFF355AA2),
                    baseBarColor: const Color(0xFF323746),
                    bufferedBarColor: const Color(
                      0xFF323746,
                    ).withValues(alpha: 0.7),
                    thumbColor: Colors.white,
                    barHeight: 2.5,
                    thumbRadius: 5.0,
                    thumbGlowRadius: 14.0,
                  );
                }
                return ProgressBar(
                  progress: const Duration(seconds: 0),
                  buffered: const Duration(seconds: 0),
                  total: const Duration(seconds: 0),
                  timeLabelPadding: 17.0,
                  timeLabelTextStyle: const TextStyle(color: Colors.white),
                  progressBarColor: const Color(0xFF355AA2),
                  baseBarColor: const Color(0xFF323746),
                  bufferedBarColor: const Color(
                    0xFF323746,
                  ).withValues(alpha: 0.7),
                  thumbColor: Colors.white,
                  barHeight: 2.5,
                  thumbRadius: 5.0,
                  thumbGlowRadius: 14.0,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
