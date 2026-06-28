import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/audio_player/domain/entities/audio_modes.dart';
import 'package:tilawa/features/audio_player/domain/repositories/audio_player_repository.dart';
import 'package:tilawa/features/audio_player/domain/usecases/audio_player_usecases.dart';

class MockAudioPlayerRepository extends Mock implements AudioPlayerRepository {}

void main() {
  late AudioPlayerRepository repository;
  late PlayAudioUseCase playUseCase;
  late PauseAudioUseCase pauseUseCase;
  late StopAudioUseCase stopUseCase;
  late SeekToUseCase seekToUseCase;
  late SkipToNextUseCase skipToNextUseCase;
  late SkipToPreviousUseCase skipToPreviousUseCase;
  late SetVolumeUseCase setVolumeUseCase;
  late SetPlaybackSpeedUseCase setPlaybackSpeedUseCase;
  late SetRepeatModeUseCase setRepeatModeUseCase;
  late SetShuffleModeUseCase setShuffleModeUseCase;
  late SkipToQueueItemUseCase skipToQueueItemUseCase;
  late PlayFromQueueUseCase playFromQueueUseCase;
  late UpdateQueueUseCase updateQueueUseCase;
  late MoveQueueItemUseCase moveQueueItemUseCase;
  late AddQueueItemUseCase addQueueItemUseCase;
  late RemoveQueueItemUseCase removeQueueItemUseCase;

  setUp(() {
    repository = MockAudioPlayerRepository();
    playUseCase = PlayAudioUseCase(repository);
    pauseUseCase = PauseAudioUseCase(repository);
    stopUseCase = StopAudioUseCase(repository);
    seekToUseCase = SeekToUseCase(repository);
    skipToNextUseCase = SkipToNextUseCase(repository);
    skipToPreviousUseCase = SkipToPreviousUseCase(repository);
    setVolumeUseCase = SetVolumeUseCase(repository);
    setPlaybackSpeedUseCase = SetPlaybackSpeedUseCase(repository);
    setRepeatModeUseCase = SetRepeatModeUseCase(repository);
    setShuffleModeUseCase = SetShuffleModeUseCase(repository);
    skipToQueueItemUseCase = SkipToQueueItemUseCase(repository);
    playFromQueueUseCase = PlayFromQueueUseCase(repository);
    updateQueueUseCase = UpdateQueueUseCase(repository);
    moveQueueItemUseCase = MoveQueueItemUseCase(repository);
    addQueueItemUseCase = AddQueueItemUseCase(repository);
    removeQueueItemUseCase = RemoveQueueItemUseCase(repository);
  });

  const tAudio = AudioEntity(
    id: '1',
    title: 'Test Title',
    url: 'https://test.com/audio.mp3',
    duration: Duration(seconds: 100),
  );

  group('AudioPlayerUseCases', () {
    test('PlayAudioUseCase should call repository.play', () async {
      when(() => repository.play()).thenAnswer((_) async => const Right(null));
      final Either<Failure, void> result = await playUseCase();
      expect(result, const Right<Failure, void>(null));
      verify(() => repository.play()).called(1);
    });

    test('PauseAudioUseCase should call repository.pause', () async {
      when(() => repository.pause()).thenAnswer((_) async => const Right(null));
      final Either<Failure, void> result = await pauseUseCase();
      expect(result, const Right<Failure, void>(null));
      verify(() => repository.pause()).called(1);
    });

    test('StopAudioUseCase should call repository.stop', () async {
      when(() => repository.stop()).thenAnswer((_) async => const Right(null));
      final Either<Failure, void> result = await stopUseCase();
      expect(result, const Right<Failure, void>(null));
      verify(() => repository.stop()).called(1);
    });

    test('SeekToUseCase should call repository.seek', () async {
      const position = Duration(seconds: 10);
      when(
        () => repository.seek(position),
      ).thenAnswer((_) async => const Right(null));
      final Either<Failure, void> result = await seekToUseCase(position);
      expect(result, const Right<Failure, void>(null));
      verify(() => repository.seek(position)).called(1);
    });

    test('SkipToNextUseCase should call repository.next', () async {
      when(() => repository.next()).thenAnswer((_) async => const Right(null));
      final Either<Failure, void> result = await skipToNextUseCase();
      expect(result, const Right<Failure, void>(null));
      verify(() => repository.next()).called(1);
    });

    test('SkipToPreviousUseCase should call repository.previous', () async {
      when(
        () => repository.previous(),
      ).thenAnswer((_) async => const Right(null));
      final Either<Failure, void> result = await skipToPreviousUseCase();
      expect(result, const Right<Failure, void>(null));
      verify(() => repository.previous()).called(1);
    });

    test('SetVolumeUseCase should call repository.setVolume', () async {
      const volume = 0.5;
      when(
        () => repository.setVolume(volume),
      ).thenAnswer((_) async => const Right(null));
      final Either<Failure, void> result = await setVolumeUseCase(volume);
      expect(result, const Right<Failure, void>(null));
      verify(() => repository.setVolume(volume)).called(1);
    });

    test('SetPlaybackSpeedUseCase should call repository.setSpeed', () async {
      const speed = 1.5;
      when(
        () => repository.setSpeed(speed),
      ).thenAnswer((_) async => const Right(null));
      final Either<Failure, void> result = await setPlaybackSpeedUseCase(speed);
      expect(result, const Right<Failure, void>(null));
      verify(() => repository.setSpeed(speed)).called(1);
    });

    test('SetRepeatModeUseCase should call repository.setRepeatMode', () async {
      const AudioRepeatMode mode = AudioRepeatMode.all;
      when(
        () => repository.setRepeatMode(mode),
      ).thenAnswer((_) async => const Right(null));
      final Either<Failure, void> result = await setRepeatModeUseCase(mode);
      expect(result, const Right<Failure, void>(null));
      verify(() => repository.setRepeatMode(mode)).called(1);
    });

    test(
      'SetShuffleModeUseCase should call repository.setShuffleMode',
      () async {
        const AudioShuffleMode mode = AudioShuffleMode.all;
        when(
          () => repository.setShuffleMode(mode),
        ).thenAnswer((_) async => const Right(null));
        final Either<Failure, void> result = await setShuffleModeUseCase(mode);
        expect(result, const Right<Failure, void>(null));
        verify(() => repository.setShuffleMode(mode)).called(1);
      },
    );

    test(
      'SkipToQueueItemUseCase should call repository.skipToQueueItem',
      () async {
        const index = 2;
        when(
          () => repository.skipToQueueItem(index),
        ).thenAnswer((_) async => const Right(null));
        final Either<Failure, void> result = await skipToQueueItemUseCase(
          index,
        );
        expect(result, const Right<Failure, void>(null));
        verify(() => repository.skipToQueueItem(index)).called(1);
      },
    );

    test('PlayFromQueueUseCase should call repository.playFromQueue', () async {
      final queue = [tAudio];
      const index = 0;
      when(
        () => repository.playFromQueue(queue, index),
      ).thenAnswer((_) async => const Right(null));
      final Either<Failure, void> result = await playFromQueueUseCase(
        queue,
        index,
      );
      expect(result, const Right<Failure, void>(null));
      verify(() => repository.playFromQueue(queue, index)).called(1);
    });

    test('UpdateQueueUseCase should call repository.updateQueue', () async {
      final queue = [tAudio];
      when(
        () => repository.updateQueue(queue),
      ).thenAnswer((_) async => const Right(null));
      final Either<Failure, void> result = await updateQueueUseCase(queue);
      expect(result, const Right<Failure, void>(null));
      verify(() => repository.updateQueue(queue)).called(1);
    });

    test('MoveQueueItemUseCase should call repository.moveQueueItem', () async {
      const currentIndex = 0;
      const newIndex = 1;
      when(
        () => repository.moveQueueItem(currentIndex, newIndex),
      ).thenAnswer((_) async => const Right(null));
      final Either<Failure, void> result = await moveQueueItemUseCase(
        currentIndex,
        newIndex,
      );
      expect(result, const Right<Failure, void>(null));
      verify(() => repository.moveQueueItem(currentIndex, newIndex)).called(1);
    });

    test('AddQueueItemUseCase should call repository.addQueueItem', () async {
      when(
        () => repository.addQueueItem(tAudio),
      ).thenAnswer((_) async => const Right(null));
      final Either<Failure, void> result = await addQueueItemUseCase(tAudio);
      expect(result, const Right<Failure, void>(null));
      verify(() => repository.addQueueItem(tAudio)).called(1);
    });

    test(
      'RemoveQueueItemUseCase should call repository.removeQueueItem',
      () async {
        when(
          () => repository.removeQueueItem(tAudio),
        ).thenAnswer((_) async => const Right(null));
        final Either<Failure, void> result = await removeQueueItemUseCase(
          tAudio,
        );
        expect(result, const Right<Failure, void>(null));
        verify(() => repository.removeQueueItem(tAudio)).called(1);
      },
    );
  });
}
