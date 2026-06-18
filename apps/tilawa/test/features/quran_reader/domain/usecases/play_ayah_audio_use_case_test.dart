import 'package:dartz_plus/dartz_plus.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:tilawa/features/audio_player/domain/usecases/audio_player_usecases.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/play_ayah_audio_use_case.dart';
import 'package:tilawa_core/entities/audio.dart';

class _MockPlayFromQueueUseCase extends Mock implements PlayFromQueueUseCase {}

void main() {
  late _MockPlayFromQueueUseCase playFromQueue;
  late PlayAyahAudioUseCase useCase;

  const AyahEntity ayah = AyahEntity(
    number: 1,
    numberInSurah: 1,
    surahNumber: 1,
    text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
  );

  setUpAll(() {
    registerFallbackValue(<AudioEntity>[]);
    registerFallbackValue(const AudioEntity(
      id: 'id',
      title: 'title',
      url: 'url',
      duration: Duration.zero,
    ));
  });

  setUp(() {
    playFromQueue = _MockPlayFromQueueUseCase();
    useCase = PlayAyahAudioUseCase(playFromQueue);
  });

  test('plays verse audio from everyayah for the active reciter', () async {
    when(
      () => playFromQueue(any(), any(), initialPosition: any(named: 'initialPosition')),
    ).thenAnswer((_) async => const Right(null));

    final result = await useCase(
      ayah: ayah,
      currentAudio: const AudioEntity(
        id: 'https://server.mp3quran.net/afs/001.mp3',
        title: 'Al-Fatiha',
        url: 'https://server.mp3quran.net/afs/001.mp3',
        duration: Duration.zero,
        artist: 'Mishary Rashid Alafasy',
        extras: {'reciterId': '7'},
      ),
    );

    expect(result, isA<Right<Object?, void>>());

    final captured = verify(
      () => playFromQueue(captureAny(), 0, initialPosition: any(named: 'initialPosition')),
    ).captured.single as List<AudioEntity>;

    expect(
      captured.single.url,
      'https://everyayah.com/data/Alafasy_128kbps/001001.mp3',
    );
    expect(captured.single.extras?['ayahNumber'], 1);
  });

  test('falls back to default reciter when no audio is active', () async {
    when(
      () => playFromQueue(any(), any(), initialPosition: any(named: 'initialPosition')),
    ).thenAnswer((_) async => const Right(null));

    await useCase(ayah: ayah);

    final captured = verify(
      () => playFromQueue(captureAny(), 0, initialPosition: any(named: 'initialPosition')),
    ).captured.single as List<AudioEntity>;

    expect(captured.single.url, contains('Alafasy_128kbps'));
  });
}
