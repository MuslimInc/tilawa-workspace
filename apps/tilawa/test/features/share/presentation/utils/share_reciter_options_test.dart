import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/share/presentation/utils/share_reciter_options.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

void main() {
  group('buildShareReciterOptions', () {
    test('returns only reciters that support the selected surah', () {
      const List<ReciterEntity> reciters = <ReciterEntity>[
        ReciterEntity(
          id: 1,
          name: 'Reciter One',
          letter: 'R',
          date: '2024',
          moshaf: <MoshafEntity>[
            MoshafEntity(
              id: 11,
              name: 'Primary',
              server: 'https://server8.mp3quran.net/afs/',
              surahTotal: 114,
              moshafType: 1,
              surahList: '1,2,3',
            ),
          ],
        ),
        ReciterEntity(
          id: 2,
          name: 'Reciter Two',
          letter: 'R',
          date: '2024',
          moshaf: <MoshafEntity>[
            MoshafEntity(
              id: 22,
              name: 'Primary',
              server: 'https://server-b.example/',
              surahTotal: 114,
              moshafType: 1,
              surahList: '4,5,6',
            ),
          ],
        ),
      ];

      final List<ShareReciterOption> options = buildShareReciterOptions(
        reciters: reciters,
        surahNumber: 2,
      );

      expect(options, hasLength(1));
      expect(options.single.name, 'Reciter One');
      expect(
        options.single.serverUrl,
        'https://server8.mp3quran.net/afs/002.mp3',
      );
    });

    test('prefers the moshaf matching the selected reciter url', () {
      const ReciterEntity reciter = ReciterEntity(
        id: 1,
        name: 'Reciter One',
        letter: 'R',
        date: '2024',
        moshaf: <MoshafEntity>[
          MoshafEntity(
            id: 11,
            name: 'Primary',
            server: 'https://server8.mp3quran.net/afs/',
            surahTotal: 114,
            moshafType: 1,
            surahList: '1,2,3',
          ),
          MoshafEntity(
            id: 12,
            name: 'Alternate',
            server: 'https://server8.mp3quran.net/husary/',
            surahTotal: 114,
            moshafType: 1,
            surahList: '1,2,3',
          ),
        ],
      );

      final List<ShareReciterOption> options = buildShareReciterOptions(
        reciters: const <ReciterEntity>[reciter],
        surahNumber: 1,
        selectedReciterName: 'Reciter One',
        selectedServerUrl: 'https://server8.mp3quran.net/husary/001.mp3',
      );

      expect(options, hasLength(1));
      expect(
        options.single.serverUrl,
        'https://server8.mp3quran.net/husary/001.mp3',
      );
    });

    test(
      'filters out reciters that are not supported by the share audio map',
      () {
        const List<ReciterEntity> reciters = <ReciterEntity>[
          ReciterEntity(
            id: 1,
            name: 'Mapped Reciter',
            letter: 'M',
            date: '2024',
            moshaf: <MoshafEntity>[
              MoshafEntity(
                id: 11,
                name: 'Primary',
                server: 'https://server8.mp3quran.net/afs/',
                surahTotal: 114,
                moshafType: 1,
                surahList: '1,2,3',
              ),
            ],
          ),
          ReciterEntity(
            id: 2,
            name: 'Unsupported Reciter',
            letter: 'U',
            date: '2024',
            moshaf: <MoshafEntity>[
              MoshafEntity(
                id: 22,
                name: 'Primary',
                server: 'https://example.com/custom-reciter/',
                surahTotal: 114,
                moshafType: 1,
                surahList: '1,2,3',
              ),
            ],
          ),
        ];

        final List<ShareReciterOption> options = buildShareReciterOptions(
          reciters: reciters,
          surahNumber: 1,
        );

        expect(options, hasLength(1));
        expect(options.single.name, 'Mapped Reciter');
      },
    );
  });

  group('matchesShareReciterOption', () {
    test('matches by normalized reciter name when url is unavailable', () {
      const ShareReciterOption option = ShareReciterOption(
        name: 'Reciter One',
        serverUrl: 'https://server8.mp3quran.net/afs/001.mp3',
      );

      expect(
        matchesShareReciterOption(
          option,
          selectedReciterName: '  reciter one  ',
        ),
        isTrue,
      );
    });
  });
}
