import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';

void main() {
  const tAudio = AudioEntity(
    id: 'https://example.com/quran/abdulbasit/001.mp3',
    title: 'Al-Fatiha',
    artist: 'Abdul Basit',
    album: 'Mujawwad',
    url: 'https://example.com/quran/abdulbasit/001.mp3',
    duration: Duration(seconds: 95),
  );

  group('SurahEntity', () {
    test('defaults isDownloaded/isDownloading/progress and exposes audio getters', () {
      const surah = SurahEntity(audio: tAudio);

      expect(surah.isDownloaded, isFalse);
      expect(surah.isDownloading, isFalse);
      expect(surah.downloadProgress, 0.0);
      expect(surah.downloadId, isNull);

      expect(surah.id, tAudio.id);
      expect(surah.name, tAudio.title);
      expect(surah.nameEn, tAudio.title);
      expect(surah.nameAr, tAudio.artist);
      expect(surah.reciterName, tAudio.artist);
    });

    test('falls back to empty string when artist-derived fields are null', () {
      const audioNoArtist = AudioEntity(
        id: '001',
        title: 'Al-Fatiha',
        url: 'u',
        duration: Duration.zero,
      );
      const surah = SurahEntity(audio: audioNoArtist);

      expect(surah.nameAr, '');
      expect(surah.reciterName, '');
    });

    group('formattedId', () {
      test('zero-pads numeric basename derived from id path', () {
        const a = AudioEntity(
          id: 'audio/12.mp3',
          title: 't',
          url: 'u',
          duration: Duration.zero,
        );
        expect(const SurahEntity(audio: a).formattedId, '012');
      });

      test('returns empty when basename is not numeric', () {
        const a = AudioEntity(
          id: 'audio/al-fatiha.mp3',
          title: 't',
          url: 'u',
          duration: Duration.zero,
        );
        expect(const SurahEntity(audio: a).formattedId, '');
      });

      test('handles ids without slashes or extensions', () {
        const a = AudioEntity(
          id: '7',
          title: 't',
          url: 'u',
          duration: Duration.zero,
        );
        expect(const SurahEntity(audio: a).formattedId, '007');
      });
    });

    test('copyWith updates only the requested fields', () {
      const surah = SurahEntity(audio: tAudio);

      final updated = surah.copyWith(
        isDownloaded: true,
        downloadProgress: 0.5,
        downloadId: 'd-1',
      );

      expect(updated.isDownloaded, isTrue);
      expect(updated.downloadProgress, 0.5);
      expect(updated.downloadId, 'd-1');
      // Unchanged
      expect(updated.audio, surah.audio);
      expect(updated.isDownloading, surah.isDownloading);
    });

    test('value equality (freezed) holds for identical field sets', () {
      const a = SurahEntity(audio: tAudio, isDownloaded: true);
      const b = SurahEntity(audio: tAudio, isDownloaded: true);
      const c = SurahEntity(audio: tAudio);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('toJson / fromJson round-trips faithfully', () {
      const original = SurahEntity(
        audio: tAudio,
        isDownloaded: true,
        isDownloading: false,
        downloadProgress: 0.75,
        downloadId: 'd-42',
      );

      final json = original.toJson();
      final restored = SurahEntity.fromJson(json);

      expect(restored, equals(original));
    });
  });
}
