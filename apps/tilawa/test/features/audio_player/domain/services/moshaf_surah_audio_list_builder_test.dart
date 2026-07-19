import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/features/audio_player/domain/services/moshaf_surah_audio_list_builder.dart';
import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';

import '../../../../shared/audio/audio_player_handler_impl_test.mocks.dart';

void main() {
  late MockSharedPreferencesAsync mockPrefs;
  late MoshafSurahAudioListBuilder builder;

  const MoshafEntity moshaf = MoshafEntity(
    id: 10,
    name: 'Hafs',
    server: 'https://cdn.example.com/',
    surahList: '1,2',
    surahTotal: 2,
    moshafType: 1,
  );

  setUp(() {
    mockPrefs = MockSharedPreferencesAsync();
    builder = MoshafSurahAudioListBuilder(mockPrefs);
  });

  test('build returns localized surah titles for English', () async {
    when(
      mockPrefs.getString(LanguageConfig.languageKey),
    ).thenAnswer((_) async => 'en');

    final List<AudioEntity>? tracks = await builder.build(
      moshaf,
      reciterName: 'Reciter',
      reciterId: '999999',
    );

    expect(tracks, hasLength(2));
    expect(tracks!.first.title, contains('Al-Fatiha'));
    expect(tracks.first.artist, 'Reciter');
    expect(tracks.first.artUri, isNull);
  });

  test('build attaches portrait artUri for mapped reciter ids', () async {
    when(
      mockPrefs.getString(LanguageConfig.languageKey),
    ).thenAnswer((_) async => 'en');

    final List<AudioEntity>? tracks = await builder.build(
      moshaf,
      reciterName: 'Yasser Al-Dosari',
      reciterId: '92',
    );

    expect(tracks, hasLength(2));
    expect(
      tracks!.first.artUri,
      startsWith('https://tvquran.com/uploads/authors/images/'),
    );
  });

  test('build returns localized surah titles for Arabic default', () async {
    when(
      mockPrefs.getString(LanguageConfig.languageKey),
    ).thenAnswer((_) async => null);

    final List<AudioEntity>? tracks = await builder.build(moshaf);

    expect(tracks, hasLength(2));
    expect(tracks!.first.title, isNot(contains('Al-Fatiha')));
  });
}
