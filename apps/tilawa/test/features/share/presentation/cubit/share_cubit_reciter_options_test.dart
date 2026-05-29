import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_reader/domain/entities/entities.dart';
import 'package:tilawa/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa/features/reciters/domain/usecases/get_reciters_use_case.dart';
import 'package:tilawa/features/share/domain/entities/audio_clip_config.dart';
import 'package:tilawa/features/share/domain/entities/share_cancel_token.dart';
import 'package:tilawa/features/share/domain/entities/share_content.dart';
import 'package:tilawa/features/share/domain/entities/share_footer_colors.dart';
import 'package:tilawa/features/share/domain/entities/share_progress_messages.dart';
import 'package:tilawa/features/share/domain/entities/widget_capture_handle.dart';
import 'package:tilawa/features/share/domain/repositories/share_repository.dart';
import 'package:tilawa/features/share/domain/usecases/capture_screenshot_use_case.dart';
import 'package:tilawa/features/share/domain/usecases/generate_audio_clip_use_case.dart';
import 'package:tilawa/features/share/domain/usecases/generate_video_use_case.dart';
import 'package:tilawa/features/share/domain/usecases/get_share_ayahs_use_case.dart';
import 'package:tilawa/features/share/domain/usecases/prepare_share_range_use_case.dart';
import 'package:tilawa/features/share/domain/usecases/share_content_use_case.dart';
import 'package:tilawa/features/share/presentation/cubit/share_cubit.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';

void main() {
  late ShareCubit cubit;
  late _FakeRecitersRepository recitersRepository;

  setUp(() {
    recitersRepository = _FakeRecitersRepository();
    final shareRepository = _FakeShareRepository();

    cubit = ShareCubit(
      CaptureScreenshotUseCase(shareRepository),
      GenerateAudioClipUseCase(shareRepository),
      GenerateVideoUseCase(shareRepository),
      const PrepareShareRangeUseCase(),
      GetShareAyahsUseCase(_FakeQuranReaderRepository()),
      ShareContentUseCase(shareRepository),
      GetRecitersUseCase(recitersRepository),
    );
  });

  tearDown(() => cubit.close());

  group('reciter options', () {
    test(
      'loadReciterOptions populates mapped reciters for current surah',
      () async {
        cubit.configureAudioClip(
          surahNumber: 2,
          fromAyah: 1,
          toAyah: 1,
          minAyah: 1,
          maxAyah: 286,
          reciterName: 'Al-Afasy',
          serverUrl: 'https://server8.mp3quran.net/afs/002.mp3',
        );

        await cubit.loadReciterOptions();

        expect(cubit.state.isLoadingReciters, isFalse);
        expect(cubit.state.reciterOptions, hasLength(1));
        expect(cubit.state.reciterOptions.single.name, 'Al-Afasy');
        expect(
          cubit.state.reciterOptions.single.serverUrl,
          'https://server8.mp3quran.net/afs/002.mp3',
        );
      },
    );

    test(
      'configureAudioClip clears previously loaded reciter options',
      () async {
        cubit.configureAudioClip(
          surahNumber: 2,
          fromAyah: 1,
          toAyah: 1,
          minAyah: 1,
          maxAyah: 286,
          reciterName: 'Al-Afasy',
          serverUrl: 'https://server8.mp3quran.net/afs/002.mp3',
        );
        await cubit.loadReciterOptions();
        expect(cubit.state.reciterOptions, isNotEmpty);

        cubit.configureAudioClip(
          surahNumber: 3,
          fromAyah: 1,
          toAyah: 1,
          minAyah: 1,
          maxAyah: 200,
          reciterName: 'Al-Afasy',
          serverUrl: 'https://server8.mp3quran.net/afs/003.mp3',
        );

        expect(cubit.state.reciterOptions, isEmpty);
        expect(cubit.state.isLoadingReciters, isFalse);
      },
    );
  });
}

class _FakeRecitersRepository implements RecitersRepository {
  static const _reciters = <ReciterEntity>[
    ReciterEntity(
      id: 1,
      name: 'Al-Afasy',
      letter: 'A',
      date: '2024',
      moshaf: <MoshafEntity>[
        MoshafEntity(
          id: 11,
          name: 'Main',
          server: 'https://server8.mp3quran.net/afs/',
          surahTotal: 114,
          moshafType: 1,
          surahList: '1,2,3',
        ),
      ],
    ),
  ];

  @override
  Future<Either<Failure, List<ReciterEntity>>> getReciters() async {
    return const Right(_reciters);
  }

  @override
  Future<Either<Failure, void>> clearFavoriteReciters() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<ReciterEntity>>> getFavoriteReciters() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<String>>> getFavoriteReciterIds() {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, ReciterEntity?>> getReciterById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<ReciterEntity>>> getRecitersByLetter(
    String letter,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<ReciterEntity>>> searchReciters(String query) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> toggleFavoriteReciter(int id) {
    throw UnimplementedError();
  }
}

class _FakeQuranReaderRepository implements QuranReaderRepository {
  @override
  Future<SurahContentEntity> getSurahContent(int surahNumber) async {
    return SurahContentEntity(
      number: surahNumber,
      name: 'سورة',
      nameEnglish: 'Surah',
      nameTranslation: 'Surah',
      revelationType: 'Medinan',
      numberOfAyahs: 286,
      ayahs: List<AyahEntity>.generate(
        286,
        (index) => AyahEntity(
          number: index + 1,
          numberInSurah: index + 1,
          surahNumber: surahNumber,
          text: 'ayah ${index + 1}',
        ),
      ),
    );
  }

  @override
  Future<AyahEntity?> getAyah({
    required int surahNumber,
    required int ayahNumber,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<({int? ayahNumber, int? page, int? surahNumber})>
  getLastReadPosition() {
    throw UnimplementedError();
  }

  @override
  Future<QuranPageEntity> getPage(int pageNumber) {
    throw UnimplementedError();
  }

  @override
  int getStartPageForSurah(int surahNumber) {
    throw UnimplementedError();
  }

  @override
  Future<List<AyahEntity>> getJuz(int juzNumber) {
    throw UnimplementedError();
  }

  @override
  Future<String?> getTranslation({
    required int surahNumber,
    required int ayahNumber,
    required String language,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<int, String>> getSurahTranslations({
    required int surahNumber,
    required String language,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ReaderSettingsEntity> loadSettings() {
    throw UnimplementedError();
  }

  @override
  Future<void> saveLastReadPosition({
    required int surahNumber,
    int? ayahNumber,
    int? page,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveSettings(ReaderSettingsEntity settings) {
    throw UnimplementedError();
  }

  @override
  Future<List<AyahEntity>> searchAyahs(String query) {
    throw UnimplementedError();
  }
}

class _FakeShareRepository implements ShareRepository {
  @override
  Future<ShareContent> captureScreenshot({
    required WidgetCaptureHandle handle,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
    bool brandCapture = true,
    ShareFooterColors? footerColors,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> cleanup() {
    throw UnimplementedError();
  }

  @override
  Future<ShareContent> generateAudioClip({
    required AudioClipConfig config,
    required AudioClipProgressMessages progressMessages,
    int? maxDurationSeconds,
    void Function(double progress, String message)? onProgress,
    ShareCancelToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ShareContent> generateVideo({
    required List<WidgetCaptureHandle> handles,
    required AudioClipConfig config,
    required String appName,
    required String sharedViaLabel,
    required ShareProgressMessages progressMessages,
    int? maxDurationSeconds,
    void Function(double progress, String message)? onProgress,
    void Function(int index)? onFrameCaptureStarted,
    ShareCancelToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> shareContent(ShareContent content) {
    throw UnimplementedError();
  }

  @override
  Future<String> exportContent(ShareContent content) {
    // TODO: implement exportContent
    throw UnimplementedError();
  }
}
