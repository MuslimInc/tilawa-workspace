import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/audio_player/domain/entities/audio_modes.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/shared/models/position_data.dart';
import 'package:tilawa/shared/widgets/quran_player_transport_controls.dart';
import 'package:tilawa_core/entities/audio.dart';

AudioPlayerState _baseState({
  AudioRepeatMode repeatMode = AudioRepeatMode.none,
  AudioShuffleMode shuffleMode = AudioShuffleMode.none,
}) {
  return AudioPlayerState(
    status: AudioPlayerStatus.success,
    currentAudio: const AudioEntity(
      id: '1',
      title: 'Al-Fatiha',
      url: 'https://example.com/1.mp3',
      duration: Duration(minutes: 3),
    ),
    repeatMode: repeatMode,
    shuffleMode: shuffleMode,
  );
}

void main() {
  group('QuranPlayerTransportControls.repeatIcon', () {
    test('none uses repeat_outlined', () {
      expect(
        QuranPlayerTransportControls.repeatIcon(AudioRepeatMode.none),
        Icons.repeat_outlined,
      );
    });

    test('all uses repeat_on', () {
      expect(
        QuranPlayerTransportControls.repeatIcon(AudioRepeatMode.all),
        Icons.repeat_on,
      );
    });

    test('one uses repeat_one', () {
      expect(
        QuranPlayerTransportControls.repeatIcon(AudioRepeatMode.one),
        Icons.repeat_one,
      );
    });
  });

  group('QuranPlayerTransportControls.shuffleIcon', () {
    test('uses shuffle glyph for off and on', () {
      expect(
        QuranPlayerTransportControls.shuffleIcon(AudioShuffleMode.none),
        Icons.shuffle,
      );
      expect(
        QuranPlayerTransportControls.shuffleIcon(AudioShuffleMode.all),
        Icons.shuffle,
      );
    });
  });

  group('QuranPlayerTransportControls shuffle visuals', () {
    testWidgets('off is muted, on uses foreground color', (tester) async {
      const Color enabled = Colors.black;
      const Color disabled = Color(0xFFB0B0B0);

      Future<void> pumpShuffle(AudioShuffleMode mode) async {
        final bool on = QuranPlayerTransportControls.shuffleActive(mode);
        await tester.pumpWidget(
          MaterialApp(
            home: Icon(
              QuranPlayerTransportControls.shuffleIcon(mode),
              color: on ? enabled : disabled,
            ),
          ),
        );
      }

      await pumpShuffle(AudioShuffleMode.none);
      Icon offIcon = tester.widget(find.byType(Icon));
      expect(offIcon.icon, Icons.shuffle);
      expect(offIcon.color, disabled);

      await pumpShuffle(AudioShuffleMode.all);
      final Icon onIcon = tester.widget(find.byType(Icon));
      expect(onIcon.icon, Icons.shuffle);
      expect(onIcon.color, enabled);
    });
  });

  group('QuranPlayerTransportControls.repeatActive', () {
    test('false when repeat is off', () {
      expect(
        QuranPlayerTransportControls.repeatActive(AudioRepeatMode.none),
        isFalse,
      );
    });

    test('true when repeat all or one', () {
      expect(
        QuranPlayerTransportControls.repeatActive(AudioRepeatMode.all),
        isTrue,
      );
      expect(
        QuranPlayerTransportControls.repeatActive(AudioRepeatMode.one),
        isTrue,
      );
    });
  });

  group('QuranPlayerTransportControls.shuffleActive', () {
    test('false when shuffle is off', () {
      expect(
        QuranPlayerTransportControls.shuffleActive(AudioShuffleMode.none),
        isFalse,
      );
    });

    test('true when shuffle is on', () {
      expect(
        QuranPlayerTransportControls.shuffleActive(AudioShuffleMode.all),
        isTrue,
      );
    });
  });

  group('QuranPlayerTransportControls.nextRepeatMode', () {
    test('cycles none -> all -> one -> none', () {
      expect(
        QuranPlayerTransportControls.nextRepeatMode(AudioRepeatMode.none),
        AudioRepeatMode.all,
      );
      expect(
        QuranPlayerTransportControls.nextRepeatMode(AudioRepeatMode.all),
        AudioRepeatMode.one,
      );
      expect(
        QuranPlayerTransportControls.nextRepeatMode(AudioRepeatMode.one),
        AudioRepeatMode.none,
      );
    });
  });

  group('QuranPlayerTransportControls.nextShuffleMode', () {
    test('toggles between none and all', () {
      expect(
        QuranPlayerTransportControls.nextShuffleMode(AudioShuffleMode.none),
        AudioShuffleMode.all,
      );
      expect(
        QuranPlayerTransportControls.nextShuffleMode(AudioShuffleMode.all),
        AudioShuffleMode.none,
      );
    });
  });

  group('QuranPlayerTransportControls.playerTreeBuildWhen', () {
    test('rebuilds when repeat mode changes', () {
      final AudioPlayerState previous = _baseState();
      final AudioPlayerState current = _baseState(
        repeatMode: AudioRepeatMode.all,
      );

      expect(
        QuranPlayerTransportControls.playerTreeBuildWhen(previous, current),
        isTrue,
      );
    });

    test('rebuilds when shuffle mode changes', () {
      final AudioPlayerState previous = _baseState();
      final AudioPlayerState current = _baseState(
        shuffleMode: AudioShuffleMode.all,
      );

      expect(
        QuranPlayerTransportControls.playerTreeBuildWhen(previous, current),
        isTrue,
      );
    });

    test('does not rebuild when only playback position would change', () {
      final AudioPlayerState previous = _baseState();
      final AudioPlayerState current = previous.copyWith(
        positionData: const PositionData(
          position: Duration(seconds: 30),
          bufferedPosition: Duration(seconds: 45),
          duration: Duration(minutes: 3),
        ),
      );

      expect(
        QuranPlayerTransportControls.playerTreeBuildWhen(previous, current),
        isFalse,
      );
    });
  });
}
