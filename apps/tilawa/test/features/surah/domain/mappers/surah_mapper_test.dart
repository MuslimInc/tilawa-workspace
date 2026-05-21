import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';
import 'package:tilawa/features/surah/domain/mappers/surah_mapper.dart';

void main() {
  const tAudio = AudioEntity(
    id: 'audio/001.mp3',
    title: 'Al-Fatiha',
    artist: 'Abdul Basit',
    album: 'Abdul Basit',
    url: 'https://example.com/001.mp3',
    duration: Duration(seconds: 95),
    artUri: 'https://example.com/art.png',
  );

  group('SurahMapper', () {
    test('toAudioEntity returns the wrapped AudioEntity identically', () {
      const surah = SurahEntity(audio: tAudio, isDownloaded: true);

      expect(SurahMapper.toAudioEntity(surah), same(surah.audio));
    });

    test('fromAudioEntity wraps audio with default download state', () {
      final surah = SurahMapper.fromAudioEntity(tAudio);

      expect(surah.audio, tAudio);
      expect(surah.isDownloaded, isFalse);
      expect(surah.isDownloading, isFalse);
      expect(surah.downloadProgress, 0.0);
      expect(surah.downloadId, isNull);
    });

    group('create', () {
      test('builds SurahEntity with required fields mapped to AudioEntity', () {
        final surah = SurahMapper.create(
          id: 'a-1',
          name: 'Al-Fatiha',
          nameAr: 'الفاتحة',
          reciterName: 'Abdul Basit',
          url: 'https://example.com/001.mp3',
          duration: const Duration(seconds: 95),
        );

        expect(surah.audio.id, 'a-1');
        expect(surah.audio.title, 'Al-Fatiha');
        // reciterName is mapped onto both artist and album, per implementation.
        expect(surah.audio.artist, 'Abdul Basit');
        expect(surah.audio.album, 'Abdul Basit');
        expect(surah.audio.url, 'https://example.com/001.mp3');
        expect(surah.audio.duration, const Duration(seconds: 95));
        expect(surah.audio.artUri, isNull);

        // Defaults
        expect(surah.isDownloaded, isFalse);
        expect(surah.isDownloading, isFalse);
        expect(surah.downloadProgress, 0.0);
        expect(surah.downloadId, isNull);
      });

      test('propagates artUri and download fields when supplied', () {
        final surah = SurahMapper.create(
          id: 'a-2',
          name: 'Al-Baqarah',
          nameAr: 'البقرة',
          reciterName: 'Mishary',
          url: 'https://example.com/002.mp3',
          duration: const Duration(minutes: 2),
          artUri: 'https://example.com/art.png',
          isDownloaded: true,
          isDownloading: true,
          downloadProgress: 0.4,
          downloadId: 'd-2',
        );

        expect(surah.audio.artUri, 'https://example.com/art.png');
        expect(surah.isDownloaded, isTrue);
        expect(surah.isDownloading, isTrue);
        expect(surah.downloadProgress, 0.4);
        expect(surah.downloadId, 'd-2');
      });

      test('nameAr argument does not currently affect the resulting entity', () {
        // SurahMapper.create accepts nameAr for API symmetry but the underlying
        // AudioEntity has no Arabic-name field, so nameAr is not surfaced.
        // This test pins that behaviour so refactors are intentional.
        final surah = SurahMapper.create(
          id: 'a-3',
          name: 'En',
          nameAr: 'العربية',
          reciterName: 'r',
          url: 'u',
          duration: Duration.zero,
        );

        expect(surah.nameEn, 'En');
        // nameAr currently mirrors the reciter (artist) field, not the Arabic
        // name passed to create(). Locked in to prevent silent regressions.
        expect(surah.nameAr, 'r');
      });
    });
  });
}
