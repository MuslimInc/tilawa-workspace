import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';
import 'package:tilawa/shared/services/audio_position_service.dart';

class _FakeAudioPlayerHandler implements AudioPlayerHandler {
  _FakeAudioPlayerHandler({
    required this.mediaItem,
    required this.playbackState,
  });

  @override
  final ValueStream<audio_service.MediaItem?> mediaItem;

  @override
  final ValueStream<audio_service.PlaybackState> playbackState;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unused member: ${invocation.memberName}');
  }
}

void main() {
  group('AudioPositionServiceImpl', () {
    late _FakeAudioPlayerHandler audioHandler;
    late BehaviorSubject<audio_service.MediaItem?> mediaItemSubject;
    late BehaviorSubject<audio_service.PlaybackState> playbackStateSubject;

    setUp(() {
      mediaItemSubject = BehaviorSubject<audio_service.MediaItem?>.seeded(null);
      playbackStateSubject =
          BehaviorSubject<audio_service.PlaybackState>.seeded(
            audio_service.PlaybackState(),
          );
      audioHandler = _FakeAudioPlayerHandler(
        mediaItem: mediaItemSubject,
        playbackState: playbackStateSubject,
      );
    });

    tearDown(() async {
      await mediaItemSubject.close();
      await playbackStateSubject.close();
    });

    test(
      'position returns a duration stream derived from the audio handler',
      () {
        final AudioPositionService service = AudioPositionServiceImpl(
          audioHandler,
        );

        expect(service.position, isA<Stream<Duration>>());
      },
    );

    test('position stream filters duplicate durations', () async {
      final AudioPositionService service = AudioPositionServiceImpl(
        audioHandler,
      );

      final emittedPositions = <Duration>[];
      final subscription = service.position
          .where((position) => position > Duration.zero)
          .listen(emittedPositions.add);

      await Future<void>.delayed(Duration.zero);

      playbackStateSubject.add(
        audio_service.PlaybackState(updatePosition: Duration(seconds: 1)),
      );
      await Future<void>.delayed(Duration.zero);

      playbackStateSubject.add(
        audio_service.PlaybackState(updatePosition: Duration(seconds: 1)),
      );
      await Future<void>.delayed(Duration.zero);

      playbackStateSubject.add(
        audio_service.PlaybackState(updatePosition: Duration(seconds: 2)),
      );
      await Future<void>.delayed(Duration.zero);

      expect(emittedPositions, <Duration>[
        const Duration(seconds: 1),
        const Duration(seconds: 2),
      ]);
      await subscription.cancel();
    });

    test('emits position when paused but ready with active media', () async {
      final AudioPositionService service = AudioPositionServiceImpl(
        audioHandler,
      );

      final emittedPositions = <Duration>[];
      final subscription = service.position.listen(emittedPositions.add);

      await Future<void>.delayed(Duration.zero);

      mediaItemSubject.add(
        const audio_service.MediaItem(
          id: '1',
          title: 'Test',
          duration: Duration(minutes: 5),
        ),
      );
      playbackStateSubject.add(
        audio_service.PlaybackState(
          updatePosition: const Duration(minutes: 3),
          playing: false,
          processingState: audio_service.AudioProcessingState.ready,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(emittedPositions, contains(const Duration(minutes: 3)));
      await subscription.cancel();
    });
  });
}
