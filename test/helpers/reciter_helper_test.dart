import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/entities/moshaf_entity.dart';
import 'package:tilawa/core/entities/reciter_entity.dart';
import 'package:tilawa/helpers/reciter_helper.dart';
import 'package:tilawa/shared/audio/audio_player_handler.dart';

import 'reciter_helper_test.mocks.dart';

@GenerateMocks([AudioPlayerHandler])
void main() {
  late MockAudioPlayerHandler mockAudioHandler;
  late GetIt getIt;

  setUp(() {
    mockAudioHandler = MockAudioPlayerHandler();
    getIt = GetIt.instance;
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('ReciterHelper.getReciterFromMediaItem', () {
    const testMoshaf = MoshafEntity(
      id: 1,
      name: 'Test Moshaf',
      server: 'https://server.com/',
      surahList: '1,2,3',
      moshafType: 1,
      surahTotal: 114,
    );

    const testReciter = ReciterEntity(
      id: 1,
      name: 'Abdul Basit',
      letter: 'أ',
      date: '2023',
      moshaf: [testMoshaf],
    );

    test('returns reciter when found by artist name', () async {
      // Arrange
      getIt.registerSingleton<AudioPlayerHandler>(mockAudioHandler);
      const mediaItem = MediaItem(
        id: 'https://server.com/001.mp3',
        title: 'Al-Fatiha',
        artist: 'Abdul Basit',
      );

      when(
        mockAudioHandler.getRecitersData(
          languageCode: anyNamed('languageCode'),
        ),
      ).thenAnswer((_) async => [testReciter]);

      // Act
      final ReciterEntity? result = await ReciterHelper.getReciterFromMediaItem(
        mediaItem,
      );

      // Assert
      expect(result, equals(testReciter));
      verify(mockAudioHandler.getRecitersData()).called(1);
    });

    test('returns reciter when found by server URL fallback', () async {
      // Arrange
      getIt.registerSingleton<AudioPlayerHandler>(mockAudioHandler);
      const mediaItem = MediaItem(
        id: 'https://server.com/001.mp3',
        title: 'Al-Fatiha',
        artist: '', // Empty artist, should use server fallback
      );

      when(
        mockAudioHandler.getRecitersData(
          languageCode: anyNamed('languageCode'),
        ),
      ).thenAnswer((_) async => [testReciter]);

      // Act
      final ReciterEntity? result = await ReciterHelper.getReciterFromMediaItem(
        mediaItem,
      );

      // Assert
      expect(result, equals(testReciter));
    });

    test(
      'returns null when AudioPlayerHandler not available in GetIt',
      () async {
        // Arrange - Don't register the handler
        const mediaItem = MediaItem(
          id: 'https://server.com/001.mp3',
          title: 'Al-Fatiha',
          artist: 'Abdul Basit',
        );

        // Act
        final ReciterEntity? result =
            await ReciterHelper.getReciterFromMediaItem(mediaItem);

        // Assert
        expect(result, isNull);
      },
    );

    test('returns null when getRecitersData returns null', () async {
      // Arrange
      getIt.registerSingleton<AudioPlayerHandler>(mockAudioHandler);
      const mediaItem = MediaItem(
        id: 'https://server.com/001.mp3',
        title: 'Al-Fatiha',
        artist: 'Abdul Basit',
      );

      when(
        mockAudioHandler.getRecitersData(
          languageCode: anyNamed('languageCode'),
        ),
      ).thenAnswer((_) async => null);

      // Act
      final ReciterEntity? result = await ReciterHelper.getReciterFromMediaItem(
        mediaItem,
      );

      // Assert
      expect(result, isNull);
    });

    test(
      'returns null when artist field is null and server does not match',
      () async {
        // Arrange
        getIt.registerSingleton<AudioPlayerHandler>(mockAudioHandler);
        const mediaItem = MediaItem(
          id: 'https://different-server.com/001.mp3',
          title: 'Al-Fatiha',
        );

        when(
          mockAudioHandler.getRecitersData(
            languageCode: anyNamed('languageCode'),
          ),
        ).thenAnswer((_) async => [testReciter]);

        // Act
        final ReciterEntity? result =
            await ReciterHelper.getReciterFromMediaItem(mediaItem);

        // Assert
        expect(result, isNull);
      },
    );

    test('returns null when reciter not found by name', () async {
      // Arrange
      getIt.registerSingleton<AudioPlayerHandler>(mockAudioHandler);
      const mediaItem = MediaItem(
        id: 'https://different-server.com/001.mp3',
        title: 'Al-Fatiha',
        artist: 'Unknown Reciter',
      );

      when(
        mockAudioHandler.getRecitersData(
          languageCode: anyNamed('languageCode'),
        ),
      ).thenAnswer((_) async => [testReciter]);

      // Act
      final ReciterEntity? result = await ReciterHelper.getReciterFromMediaItem(
        mediaItem,
      );

      // Assert
      expect(result, isNull);
    });

    test('returns null when no reciter matches server URL', () async {
      // Arrange
      getIt.registerSingleton<AudioPlayerHandler>(mockAudioHandler);
      const mediaItem = MediaItem(
        id: 'https://different-server.com/001.mp3',
        title: 'Al-Fatiha',
        artist: '',
      );

      when(
        mockAudioHandler.getRecitersData(
          languageCode: anyNamed('languageCode'),
        ),
      ).thenAnswer((_) async => [testReciter]);

      // Act
      final ReciterEntity? result = await ReciterHelper.getReciterFromMediaItem(
        mediaItem,
      );

      // Assert
      expect(result, isNull);
    });

    test('handles exceptions gracefully', () async {
      // Arrange
      getIt.registerSingleton<AudioPlayerHandler>(mockAudioHandler);
      const mediaItem = MediaItem(
        id: 'https://server.com/001.mp3',
        title: 'Al-Fatiha',
        artist: 'Abdul Basit',
      );

      when(
        mockAudioHandler.getRecitersData(
          languageCode: anyNamed('languageCode'),
        ),
      ).thenThrow(Exception('Network error'));

      // Act
      final ReciterEntity? result = await ReciterHelper.getReciterFromMediaItem(
        mediaItem,
      );

      // Assert
      expect(result, isNull);
    });

    test('uses provided languageCode parameter', () async {
      // Arrange
      getIt.registerSingleton<AudioPlayerHandler>(mockAudioHandler);
      const mediaItem = MediaItem(
        id: 'https://server.com/001.mp3',
        title: 'Al-Fatiha',
        artist: 'Abdul Basit',
      );

      when(
        mockAudioHandler.getRecitersData(languageCode: 'ar'),
      ).thenAnswer((_) async => [testReciter]);

      // Act
      final ReciterEntity? result = await ReciterHelper.getReciterFromMediaItem(
        mediaItem,
        languageCode: 'ar',
      );

      // Assert
      expect(result, equals(testReciter));
      verify(mockAudioHandler.getRecitersData(languageCode: 'ar')).called(1);
    });

    test('matches reciter by server URL when multiple moshaf exist', () async {
      // Arrange
      getIt.registerSingleton<AudioPlayerHandler>(mockAudioHandler);

      const moshaf1 = MoshafEntity(
        id: 1,
        name: 'Moshaf 1',
        server: 'https://server1.com/',
        surahList: '1,2,3',
        moshafType: 1,
        surahTotal: 114,
      );

      const moshaf2 = MoshafEntity(
        id: 2,
        name: 'Moshaf 2',
        server: 'https://server2.com/',
        surahList: '1,2,3',
        moshafType: 1,
        surahTotal: 114,
      );

      const reciterWithMultipleMoshaf = ReciterEntity(
        id: 1,
        name: 'Abdul Basit',
        letter: 'أ',
        date: '2023',
        moshaf: [moshaf1, moshaf2],
      );

      const mediaItem = MediaItem(
        id: 'https://server2.com/001.mp3',
        title: 'Al-Fatiha',
        artist: '',
      );

      when(
        mockAudioHandler.getRecitersData(
          languageCode: anyNamed('languageCode'),
        ),
      ).thenAnswer((_) async => [reciterWithMultipleMoshaf]);

      // Act
      final ReciterEntity? result = await ReciterHelper.getReciterFromMediaItem(
        mediaItem,
      );

      // Assert
      expect(result, equals(reciterWithMultipleMoshaf));
    });
  });

  group('ReciterHelper.hasReciterInfo', () {
    test('returns true when artist field is valid and non-empty', () {
      // Arrange
      const mediaItem = MediaItem(
        id: '1',
        title: 'Test',
        artist: 'Abdul Basit',
      );

      // Act
      final bool result = ReciterHelper.hasReciterInfo(mediaItem);

      // Assert
      expect(result, isTrue);
    });

    test('returns false when artist field is null', () {
      // Arrange
      const mediaItem = MediaItem(id: '1', title: 'Test');

      // Act
      final bool result = ReciterHelper.hasReciterInfo(mediaItem);

      // Assert
      expect(result, isFalse);
    });

    test('returns false when artist field is empty', () {
      // Arrange
      const mediaItem = MediaItem(id: '1', title: 'Test', artist: '');

      // Act
      final bool result = ReciterHelper.hasReciterInfo(mediaItem);

      // Assert
      expect(result, isFalse);
    });

    test('returns true when MediaItem has .mp3 and Arabic surah pattern', () {
      // Arrange
      const mediaItem = MediaItem(
        id: 'https://server.com/001.mp3',
        title: 'سورة الفاتحة',
        artist: '',
      );

      // Act
      final bool result = ReciterHelper.hasReciterInfo(mediaItem);

      // Assert
      expect(result, isTrue);
    });

    test('returns true when MediaItem has .mp3 and English surah pattern', () {
      // Arrange
      const mediaItem = MediaItem(
        id: 'https://server.com/001.mp3',
        title: 'Surah Al-Fatiha',
        artist: '',
      );

      // Act
      final bool result = ReciterHelper.hasReciterInfo(mediaItem);

      // Assert
      expect(result, isTrue);
    });

    test('returns true when MediaItem has .mp3 and numeric pattern', () {
      // Arrange
      const mediaItem = MediaItem(
        id: 'https://server.com/001.mp3',
        title: '001',
        artist: '',
      );

      // Act
      final bool result = ReciterHelper.hasReciterInfo(mediaItem);

      // Assert
      expect(result, isTrue);
    });

    test('returns false when MediaItem has no .mp3 extension', () {
      // Arrange
      const mediaItem = MediaItem(
        id: 'https://server.com/001.wav',
        title: 'Surah Al-Fatiha',
        artist: '',
      );

      // Act
      final bool result = ReciterHelper.hasReciterInfo(mediaItem);

      // Assert
      expect(result, isFalse);
    });

    test('returns false when MediaItem does not match any pattern', () {
      // Arrange
      const mediaItem = MediaItem(
        id: 'https://server.com/random.mp3',
        title: 'Random Audio',
        artist: '',
      );

      // Act
      final bool result = ReciterHelper.hasReciterInfo(mediaItem);

      // Assert
      expect(result, isFalse);
    });

    test('returns true when artist is non-empty even without .mp3', () {
      // Arrange
      const mediaItem = MediaItem(
        id: 'https://server.com/audio',
        title: 'Test',
        artist: 'Abdul Basit',
      );

      // Act
      final bool result = ReciterHelper.hasReciterInfo(mediaItem);

      // Assert
      expect(result, isTrue);
    });
  });
}
