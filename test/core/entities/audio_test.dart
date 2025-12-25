import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/entities/audio.dart';

void main() {
  group('AudioEntity', () {
    test('should create instance with all required fields', () {
      // arrange & act
      const audio = AudioEntity(
        id: '1',
        title: 'Test Audio',
        url: 'https://example.com/audio.mp3',
        duration: Duration(minutes: 5),
      );

      // assert
      expect(audio.id, '1');
      expect(audio.title, 'Test Audio');
      expect(audio.url, 'https://example.com/audio.mp3');
      expect(audio.duration, const Duration(minutes: 5));
      expect(audio.artist, null);
      expect(audio.album, null);
      expect(audio.artUri, null);
    });

    test('should create instance with optional fields', () {
      // arrange & act
      const audio = AudioEntity(
        id: '1',
        title: 'Test Audio',
        url: 'https://example.com/audio.mp3',
        duration: Duration(minutes: 5),
        artist: 'Test Artist',
        album: 'Test Album',
        artUri: 'https://example.com/art.jpg',
      );

      // assert
      expect(audio.artist, 'Test Artist');
      expect(audio.album, 'Test Album');
      expect(audio.artUri, 'https://example.com/art.jpg');
    });

    test('should support value equality', () {
      // arrange
      const audio1 = AudioEntity(
        id: '1',
        title: 'Test Audio',
        url: 'https://example.com/audio.mp3',
        duration: Duration(minutes: 5),
      );

      const audio2 = AudioEntity(
        id: '1',
        title: 'Test Audio',
        url: 'https://example.com/audio.mp3',
        duration: Duration(minutes: 5),
      );

      // assert
      expect(audio1, audio2);
    });

    test('props should contain all fields including nullable ones', () {
      // arrange
      const audio = AudioEntity(
        id: '1',
        title: 'Test Audio',
        url: 'https://example.com/audio.mp3',
        duration: Duration(minutes: 5),
        artist: 'Artist',
      );

      // assert
      expect(audio.props.length, 7);
      expect(audio.props, [
        '1',
        'Test Audio',
        'https://example.com/audio.mp3',
        const Duration(minutes: 5),
        'Artist',
        null,
        null,
      ]);
    });
  });

  group('PlaybackStateEntity', () {
    const tAudio = AudioEntity(
      id: '1',
      title: 'Test Audio',
      url: 'https://example.com/audio.mp3',
      duration: Duration(minutes: 5),
    );

    test('should create instance with all required fields', () {
      // arrange & act
      const state = PlaybackStateEntity(
        isPlaying: true,
        position: Duration(seconds: 30),
        duration: Duration(minutes: 5),
        currentIndex: 0,
        queue: [tAudio],
      );

      // assert
      expect(state.isPlaying, true);
      expect(state.position, const Duration(seconds: 30));
      expect(state.duration, const Duration(minutes: 5));
      expect(state.currentIndex, 0);
      expect(state.queue, [tAudio]);
    });

    test('should support value equality', () {
      // arrange
      const state1 = PlaybackStateEntity(
        isPlaying: true,
        position: Duration(seconds: 30),
        duration: Duration(minutes: 5),
        currentIndex: 0,
        queue: [tAudio],
      );

      const state2 = PlaybackStateEntity(
        isPlaying: true,
        position: Duration(seconds: 30),
        duration: Duration(minutes: 5),
        currentIndex: 0,
        queue: [tAudio],
      );

      // assert
      expect(state1, state2);
    });

    test('should not be equal when properties differ', () {
      // arrange
      const state1 = PlaybackStateEntity(
        isPlaying: true,
        position: Duration(seconds: 30),
        duration: Duration(minutes: 5),
        currentIndex: 0,
        queue: [tAudio],
      );

      const state2 = PlaybackStateEntity(
        isPlaying: false,
        position: Duration(seconds: 60),
        duration: Duration(minutes: 5),
        currentIndex: 1,
        queue: [],
      );

      // assert
      expect(state1, isNot(state2));
    });

    test('props should contain all fields in correct order', () {
      // arrange
      const state = PlaybackStateEntity(
        isPlaying: true,
        position: Duration(seconds: 30),
        duration: Duration(minutes: 5),
        currentIndex: 0,
        queue: [tAudio],
      );

      // assert
      expect(state.props, [
        true,
        const Duration(seconds: 30),
        const Duration(minutes: 5),
        0,
        const [tAudio],
      ]);
    });
  });
}
