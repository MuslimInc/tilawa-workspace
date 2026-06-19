import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/audio_player/domain/usecases/audio_player_usecases.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/play_ayah_audio_use_case.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/audio_extras_keys.dart';
import 'package:tilawa_core/errors/failures.dart';

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
    registerFallbackValue(
      const AudioEntity(
        id: 'id',
        title: 'title',
        url: 'url',
        duration: Duration.zero,
      ),
    );
  });

  setUp(() {
    playFromQueue = _MockPlayFromQueueUseCase();
    useCase = PlayAyahAudioUseCase(playFromQueue);
  });

  test('plays verse audio from everyayah for the active reciter', () async {
    _arrangeQueueResult(playFromQueue);

    final result = await useCase(
      ayah: ayah,
      currentAudio: _currentAudio(
        url: 'https://server.mp3quran.net/afs/001.mp3',
        artist: 'Mishary Rashid Alafasy',
        extras: const {AudioExtrasKeys.reciterId: '7'},
      ),
    );

    expect(result, isA<Right<Object?, void>>());

    final AudioEntity queuedAudio = _captureQueuedAudio(playFromQueue);
    expect(
      queuedAudio.id,
      'https://everyayah.com/data/Alafasy_128kbps/001001.mp3',
    );
    expect(queuedAudio.title, 'سورة الفاتحة — 1');
    expect(queuedAudio.url, queuedAudio.id);
    expect(queuedAudio.duration, Duration.zero);
    expect(queuedAudio.artist, 'Mishary Rashid Alafasy');
    expect(queuedAudio.extras, <String, dynamic>{
      AudioExtrasKeys.surahId: 1,
      AudioExtrasKeys.ayahNumber: 1,
      AudioExtrasKeys.reciterId: '7',
    });
  });

  test('falls back to default reciter when no audio is active', () async {
    _arrangeQueueResult(playFromQueue);

    await useCase(ayah: ayah);

    final AudioEntity queuedAudio = _captureQueuedAudio(playFromQueue);

    expect(queuedAudio.url, contains('Alafasy_128kbps'));
    expect(queuedAudio.artist, 'Mishary Rashid Alafasy');
    expect(queuedAudio.extras, <String, dynamic>{
      AudioExtrasKeys.surahId: 1,
      AudioExtrasKeys.ayahNumber: 1,
    });
  });

  test('normalizes reciter id and preserves moshaf id as int', () async {
    _arrangeQueueResult(playFromQueue);

    final result = await useCase(
      ayah: ayah,
      currentAudio: _currentAudio(
        url: 'https://server.mp3quran.net/afs/001.mp3',
        artist: 'Mishary Rashid Alafasy',
        extras: {'reciterId': 7, 'moshafId': 1},
      ),
    );

    expect(result, isA<Right<Object?, void>>());

    final AudioEntity queuedAudio = _captureQueuedAudio(playFromQueue);

    expect(queuedAudio.extras?[AudioExtrasKeys.reciterId], '7');
    expect(queuedAudio.extras?[AudioExtrasKeys.moshafId], 1);
  });

  test('parses string moshaf id before queueing ayah audio', () async {
    _arrangeQueueResult(playFromQueue);

    await useCase(
      ayah: ayah,
      currentAudio: _currentAudio(
        url: 'https://server.mp3quran.net/afs/001.mp3',
        extras: const {AudioExtrasKeys.moshafId: '1'},
      ),
    );

    final AudioEntity queuedAudio = _captureQueuedAudio(playFromQueue);

    expect(queuedAudio.extras?[AudioExtrasKeys.moshafId], 1);
  });

  test('uses mapped reciter folder and padded ayah path', () async {
    _arrangeQueueResult(playFromQueue);

    const AyahEntity ayah = AyahEntity(
      number: 262,
      numberInSurah: 255,
      surahNumber: 2,
      text: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
    );

    await useCase(
      ayah: ayah,
      currentAudio: _currentAudio(
        url: 'https://server.mp3quran.net/basit/Mujawwad/002.mp3',
        artist: 'Abdul Basit',
      ),
    );

    final AudioEntity queuedAudio = _captureQueuedAudio(playFromQueue);

    expect(
      queuedAudio.url,
      'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/002255.mp3',
    );
    expect(queuedAudio.title, 'سورة البقرة — 255');
    expect(queuedAudio.artist, 'Abdul Basit');
    expect(queuedAudio.extras?[AudioExtrasKeys.surahId], 2);
    expect(queuedAudio.extras?[AudioExtrasKeys.ayahNumber], 255);
  });

  test('uses default artist when active audio has no artist', () async {
    _arrangeQueueResult(playFromQueue);

    await useCase(
      ayah: ayah,
      currentAudio: _currentAudio(
        url: 'https://server.mp3quran.net/husary/001.mp3',
      ),
    );

    final AudioEntity queuedAudio = _captureQueuedAudio(playFromQueue);

    expect(queuedAudio.url, contains('Husary_128kbps'));
    expect(queuedAudio.artist, 'Mishary Rashid Alafasy');
  });

  test('returns play queue failure without swallowing it', () async {
    const failure = AudioFailure('playback failed');
    _arrangeQueueResult(playFromQueue, result: const Left(failure));

    final result = await useCase(ayah: ayah);

    expect(result, const Left<Failure, void>(failure));
    _captureQueuedAudio(playFromQueue);
  });
}

void _arrangeQueueResult(
  _MockPlayFromQueueUseCase playFromQueue, {
  Either<Failure, void> result = const Right(null),
}) {
  when(
    () => playFromQueue(
      any(),
      any(),
      initialPosition: any(named: 'initialPosition'),
    ),
  ).thenAnswer((_) async => result);
}

AudioEntity _captureQueuedAudio(_MockPlayFromQueueUseCase playFromQueue) {
  final captured =
      verify(
            () => playFromQueue(
              captureAny(),
              0,
              initialPosition: any(named: 'initialPosition'),
            ),
          ).captured.single
          as List<AudioEntity>;

  expect(captured, hasLength(1));
  return captured.single;
}

AudioEntity _currentAudio({
  required String url,
  String? artist,
  Map<String, dynamic>? extras,
}) {
  return AudioEntity(
    id: url,
    title: 'Current recitation',
    url: url,
    duration: Duration.zero,
    artist: artist,
    extras: extras,
  );
}
