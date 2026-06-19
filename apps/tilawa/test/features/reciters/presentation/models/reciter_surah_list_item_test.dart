import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa/features/reciters/presentation/models/reciter_surah_list_item.dart';
import 'package:tilawa/features/surah/domain/entities/surah_entity.dart';

void main() {
  const audio = AudioEntity(
    id: 'https://cdn.example.com/001.mp3',
    title: 'Al-Fatiha',
    artist: 'Abdul Basit',
    url: 'https://cdn.example.com/001.mp3',
    duration: Duration(seconds: 95),
    extras: {'surahId': 1},
  );

  const surah = SurahEntity(
    audio: audio,
    isDownloaded: true,
    isDownloading: false,
    downloadProgress: 1,
  );

  test('fromSurahEntity maps display and download fields for widgets', () {
    final item = ReciterSurahListItem.fromSurahEntity(
      surah,
      reciterId: 7,
      reciterName: 'Abdul Basit',
      listIndex: 0,
    );

    expect(item.audioId, audio.id);
    expect(item.audioUrl, audio.url);
    expect(item.displayName, 'Al-Fatiha');
    expect(item.formattedNumber, '001');
    expect(item.semanticsKey, '001');
    expect(item.reciterId, 7);
    expect(item.reciterName, 'Abdul Basit');
    expect(item.isDownloaded, isTrue);
    expect(item.downloadProgress, 1);
  });

  test('fromSurahEntity falls back semantics key to list index', () {
    const audioWithoutNumericId = AudioEntity(
      id: 'custom-track',
      title: 'Track',
      url: 'u',
      duration: Duration.zero,
    );

    final item = ReciterSurahListItem.fromSurahEntity(
      const SurahEntity(audio: audioWithoutNumericId),
      reciterId: 1,
      reciterName: 'Reciter',
      listIndex: 4,
    );

    expect(item.formattedNumber, '5');
    expect(item.semanticsKey, '5');
  });
}
