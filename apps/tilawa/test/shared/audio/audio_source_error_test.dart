import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/analytics_service.dart';
import 'package:tilawa/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/shared/audio/audio_player_handler_impl.dart';

import 'audio_player_handler_impl_test.mocks.dart';

/// Test cases to validate and reproduce the Firebase crash:
/// Fatal Exception: io.flutter.plugins.firebase.crashlytics.FlutterError: (0) Source error
/// This crash occurs when just_audio tries to load an invalid or malformed URL
@GenerateMocks([
  AnalyticsService,
  SharedPreferencesAsync,
  RecitersRepository,
  DownloadsRepository,
  AudioPlayer,
  AudioSession,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.just_audio.methods'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'init') {
              return {'id': 'mock_player_id'};
            }
            return null;
          },
        );
  });

  provideDummy<Either<Failure, List<ReciterEntity>>>(const Right([]));

  late AudioPlayerHandlerImpl handler;
  late MockAnalyticsService mockAnalytics;
  late MockSharedPreferencesAsync mockPrefs;
  late MockRecitersRepository mockRepo;
  late MockDownloadsRepository mockDownloadsRepo;
  late MockAudioPlayer mockPlayer;
  late MockAudioSession mockAudioSession;

  // Stream subjects for the mock player
  late BehaviorSubject<int?> currentIndexSubject;
  late BehaviorSubject<ProcessingState> processingStateSubject;
  late BehaviorSubject<Duration?> durationSubject;
  late BehaviorSubject<bool> shuffleModeEnabledSubject;
  late BehaviorSubject<List<int>> shuffleIndicesSubject;
  late BehaviorSubject<PlaybackEvent> playbackEventSubject;
  late BehaviorSubject<List<IndexedAudioSource>> sequenceSubject;

  setUp(() async {
    mockAnalytics = MockAnalyticsService();
    mockPrefs = MockSharedPreferencesAsync();
    mockRepo = MockRecitersRepository();
    mockDownloadsRepo = MockDownloadsRepository();
    mockPlayer = MockAudioPlayer();
    mockAudioSession = MockAudioSession();

    // Mock downloads repository to return null (no downloaded files) by default
    when(
      mockDownloadsRepo.getDownloadedFilePath(any, any),
    ).thenAnswer((_) async => null);

    currentIndexSubject = BehaviorSubject<int?>.seeded(null);
    processingStateSubject = BehaviorSubject<ProcessingState>.seeded(
      ProcessingState.idle,
    );
    durationSubject = BehaviorSubject<Duration?>.seeded(null);
    shuffleModeEnabledSubject = BehaviorSubject<bool>.seeded(false);
    shuffleIndicesSubject = BehaviorSubject<List<int>>.seeded([]);
    playbackEventSubject = BehaviorSubject<PlaybackEvent>.seeded(
      PlaybackEvent(updateTime: DateTime.now()),
    );
    sequenceSubject = BehaviorSubject<List<IndexedAudioSource>>.seeded([]);

    // Setup mock player streams
    when(
      mockPlayer.currentIndexStream,
    ).thenAnswer((_) => currentIndexSubject.stream);
    when(
      mockPlayer.processingStateStream,
    ).thenAnswer((_) => processingStateSubject.stream);
    when(mockPlayer.durationStream).thenAnswer((_) => durationSubject.stream);
    when(
      mockPlayer.shuffleModeEnabledStream,
    ).thenAnswer((_) => shuffleModeEnabledSubject.stream);
    when(
      mockPlayer.shuffleIndicesStream,
    ).thenAnswer((_) => shuffleIndicesSubject.stream);
    when(
      mockPlayer.playbackEventStream,
    ).thenAnswer((_) => playbackEventSubject.stream);
    when(mockPlayer.playerStateStream).thenAnswer(
      (_) => BehaviorSubject<PlayerState>.seeded(
        PlayerState(false, ProcessingState.idle),
      ).stream,
    );
    when(mockPlayer.sequenceStream).thenAnswer((_) => sequenceSubject.stream);

    // Mock player values
    when(mockPlayer.currentIndex).thenAnswer((_) => currentIndexSubject.value);
    when(
      mockPlayer.processingState,
    ).thenAnswer((_) => processingStateSubject.value);
    when(
      mockPlayer.playbackEvent,
    ).thenAnswer((_) => playbackEventSubject.value);
    when(mockPlayer.shuffleModeEnabled).thenReturn(false);
    when(mockPlayer.shuffleIndices).thenReturn([]);
    when(mockPlayer.playing).thenReturn(false);
    when(mockPlayer.effectiveIndices).thenReturn([]);
    when(mockPlayer.position).thenReturn(Duration.zero);
    when(mockPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(mockPlayer.speed).thenReturn(1.0);

    // Mock player methods - default to success
    when(
      mockPlayer.setAudioSources(any, initialIndex: anyNamed('initialIndex')),
    ).thenAnswer((invocation) async {
      final sources = invocation.positionalArguments[0] as List<AudioSource>;
      final List<IndexedAudioSource> indexedSources = sources
          .cast<IndexedAudioSource>()
          .toList();
      sequenceSubject.add(indexedSources);
      return null;
    });
    when(mockPlayer.addAudioSource(any)).thenAnswer((_) async {});

    handler = AudioPlayerHandlerImpl(
      [],
      mockAnalytics,
      mockPrefs,
      mockRepo,
      mockDownloadsRepo,
      player: mockPlayer,
      audioSession: mockAudioSession,
    );

    // Allow _init to run
    await Future.delayed(Duration.zero);
    clearInteractions(mockPlayer);
  });

  tearDown(() async {
    await currentIndexSubject.close();
    await processingStateSubject.close();
    await durationSubject.close();
    await shuffleModeEnabledSubject.close();
    await shuffleIndicesSubject.close();
    await playbackEventSubject.close();
    await sequenceSubject.close();
  });

  group('Audio Source Error - URL Validation', () {
    test('should throw error when MediaItem has empty URL', () async {
      // Simulate the crash scenario: empty URL
      const invalidItem = MediaItem(
        id: '', // Empty ID
        title: 'Test Surah',
        artist: 'Test Reciter',
        extras: <String, dynamic>{'url': ''}, // Empty URL
      );

      // This should throw an error or handle gracefully
      // Currently, this will cause a crash in just_audio
      expect(
        () => handler.addQueueItem(invalidItem),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw error when MediaItem has null URL', () async {
      // Simulate the crash scenario: null URL extracted
      const invalidItem = MediaItem(
        id: '', // Empty ID, and no URL in extras
        title: 'Test Surah',
        artist: 'Test Reciter',
        // No 'url' in extras, will fall back to empty id
      );

      expect(
        () => handler.addQueueItem(invalidItem),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw error when MediaItem has malformed URL', () async {
      // Malformed URL that cannot be parsed
      const invalidItem = MediaItem(
        id: 'not-a-valid-url',
        title: 'Test Surah',
        artist: 'Test Reciter',
        extras: <String, dynamic>{'url': 'ht!tp://invalid url with spaces'},
      );

      expect(
        () => handler.addQueueItem(invalidItem),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw error when URL has no scheme', () async {
      const invalidItem = MediaItem(
        id: 'example.com/audio.mp3',
        title: 'Test Surah',
        artist: 'Test Reciter',
        extras: <String, dynamic>{'url': 'example.com/audio.mp3'},
      );

      expect(
        () => handler.addQueueItem(invalidItem),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw error when HTTP URL has no host', () async {
      const invalidItem = MediaItem(
        id: 'http://',
        title: 'Test Surah',
        artist: 'Test Reciter',
        extras: <String, dynamic>{'url': 'http://'},
      );

      expect(
        () => handler.addQueueItem(invalidItem),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should accept valid HTTP URL', () async {
      const validItem = MediaItem(
        id: 'http://example.com/audio.mp3',
        title: 'Test Surah',
        artist: 'Test Reciter',
        extras: <String, dynamic>{'url': 'http://example.com/audio.mp3'},
      );

      // Should not throw
      await handler.addQueueItem(validItem);

      // Verify it was added
      verify(mockPlayer.addAudioSource(any)).called(1);
    });

    test('should accept valid HTTPS URL', () async {
      const validItem = MediaItem(
        id: 'https://example.com/audio.mp3',
        title: 'Test Surah',
        artist: 'Test Reciter',
        extras: <String, dynamic>{'url': 'https://example.com/audio.mp3'},
      );

      // Should not throw
      await handler.addQueueItem(validItem);

      verify(mockPlayer.addAudioSource(any)).called(1);
    });

    test('should accept valid file URI', () async {
      const validItem = MediaItem(
        id: 'file:///path/to/audio.mp3',
        title: 'Test Surah',
        artist: 'Test Reciter',
        extras: <String, dynamic>{'url': 'file:///path/to/audio.mp3'},
      );

      // Should not throw
      await handler.addQueueItem(validItem);

      verify(mockPlayer.addAudioSource(any)).called(1);
    });
  });

  group('Audio Source Error - Reciter Data with Invalid URLs', () {
    test('should skip reciters with malformed server URLs', () async {
      // Simulate reciter data with malformed server URL
      const reciterWithInvalidUrl = ReciterEntity(
        id: 1,
        name: 'Test Reciter',
        letter: 'T',
        date: '2023',
        moshaf: [
          MoshafEntity(
            id: 1,
            name: 'Test Moshaf',
            server: '', // Empty server URL - will create invalid URLs
            surahList: '1,2,3',
            moshafType: 1,
            surahTotal: 114,
          ),
        ],
      );

      when(
        mockRepo.getReciters(),
      ).thenAnswer((_) async => const Right([reciterWithInvalidUrl]));

      final List<AudioEntity>? result = await handler.getReciters();

      // Should return empty list or skip invalid entries
      // The current implementation will create URLs like "001.mp3" which is invalid
      expect(result, isNotNull);
      // Verify that invalid URLs are filtered out
      if (result != null && result.isNotEmpty) {
        for (final AudioEntity audio in result) {
          // Each audio URL should be valid
          expect(audio.url, isNotEmpty);
          expect(
            Uri.tryParse(audio.url)?.hasScheme ?? false,
            isTrue,
            reason: 'URL ${audio.url} should have a valid scheme',
          );
        }
      }
    });

    test('should skip reciters with URL containing only scheme', () async {
      const reciterWithSchemeOnly = ReciterEntity(
        id: 1,
        name: 'Test Reciter',
        letter: 'T',
        date: '2023',
        moshaf: [
          MoshafEntity(
            id: 1,
            name: 'Test Moshaf',
            server: 'http://', // Invalid - no host
            surahList: '1',
            moshafType: 1,
            surahTotal: 114,
          ),
        ],
      );

      when(
        mockRepo.getReciters(),
      ).thenAnswer((_) async => const Right([reciterWithSchemeOnly]));

      final List<AudioEntity>? result = await handler.getReciters();

      expect(result, isNotNull);
      // Should filter out invalid URLs
      if (result != null && result.isNotEmpty) {
        for (final AudioEntity audio in result) {
          final Uri? uri = Uri.tryParse(audio.url);
          expect(uri, isNotNull);
          if (uri != null && uri.scheme == 'http' || uri?.scheme == 'https') {
            expect(uri!.host, isNotEmpty, reason: 'HTTP URL must have a host');
          }
        }
      }
    });
  });

  group('Audio Source Error - Error State Broadcasting', () {
    test('should broadcast error state when audio loading fails', () async {
      when(
        mockPlayer.setAudioSources(any, initialIndex: anyNamed('initialIndex')),
      ).thenThrow(Exception('Failed to load audio source'));

      const item = MediaItem(
        id: 'http://example.com/audio.mp3',
        title: 'Test',
        extras: <String, dynamic>{'url': 'http://example.com/audio.mp3'},
      );

      try {
        await handler.updateQueue([item]);
      } catch (_) {
        // [_safeSetAudioSources] rethrows after broadcasting error.
      }

      await Future.delayed(const Duration(milliseconds: 150));

      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.error,
      );
    });

    test('should handle play error gracefully', () async {
      when(mockPlayer.play()).thenThrow(Exception('Source error'));

      const item = MediaItem(
        id: 'http://example.com/audio.mp3',
        title: 'Test',
        artist: 'Artist',
        extras: <String, dynamic>{'url': 'http://example.com/audio.mp3'},
      );

      handler.mediaItem.add(item);

      // Should catch error and broadcast error state
      expect(() => handler.play(), throwsException);

      // Verify error state is broadcast
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.error,
      );
    });
  });

  group('Audio Source Error - Integration with playFromQueue', () {
    test('should handle invalid URL in queue gracefully', () async {
      final mixedQueue = [
        const MediaItem(
          id: 'http://example.com/valid.mp3',
          title: 'Valid',
          extras: <String, dynamic>{'url': 'http://example.com/valid.mp3'},
        ),
        const MediaItem(
          id: '', // Invalid
          title: 'Invalid',
          extras: <String, dynamic>{'url': ''},
        ),
        const MediaItem(
          id: 'https://example.com/another-valid.mp3',
          title: 'Another Valid',
          extras: <String, dynamic>{
            'url': 'https://example.com/another-valid.mp3',
          },
        ),
      ];

      // Should throw error for invalid item in queue
      expect(
        () => handler.playFromQueue(mixedQueue, 0),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Audio Source Error - Edge Cases', () {
    test('should handle URLs with special characters', () async {
      const itemWithSpecialChars = MediaItem(
        id: 'http://example.com/audio%20file.mp3',
        title: 'Test',
        extras: <String, dynamic>{'url': 'http://example.com/audio%20file.mp3'},
      );

      // URL-encoded characters should be valid
      await handler.addQueueItem(itemWithSpecialChars);

      verify(mockPlayer.addAudioSource(any)).called(1);
    });

    test('should reject URLs with unencoded spaces', () async {
      const itemWithSpaces = MediaItem(
        id: 'http://example.com/audio file.mp3',
        title: 'Test',
        extras: <String, dynamic>{'url': 'http://example.com/audio file.mp3'},
      );

      // Unencoded spaces should be invalid
      // Note: Uri.parse may or may not throw, but our validation should catch it
      expect(
        () => handler.addQueueItem(itemWithSpaces),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should handle very long URLs', () async {
      final longUrl = 'http://example.com/${'a' * 2000}.mp3';
      final itemWithLongUrl = MediaItem(
        id: longUrl,
        title: 'Test',
        extras: <String, dynamic>{'url': longUrl},
      );

      // Long but valid URLs should work
      await handler.addQueueItem(itemWithLongUrl);

      verify(mockPlayer.addAudioSource(any)).called(1);
    });
  });
}
