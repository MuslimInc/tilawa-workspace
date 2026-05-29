import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/auth/domain/entities/user_entity.dart';
import 'package:tilawa/features/auth/domain/repositories/auth_repository.dart';
import 'package:tilawa/features/reciters/data/datasources/reciters_favorites_datasource.dart';
import 'package:tilawa/features/reciters/data/datasources/reciters_local_datasource.dart';
import 'package:tilawa/features/reciters/data/datasources/reciters_remote_datasource.dart';
import 'package:tilawa/features/reciters/data/models/reciter_model.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_prompt_moment.dart';
import 'package:tilawa/features/app_review/domain/entities/app_review_signal.dart';
import 'package:tilawa/features/app_review/domain/services/app_review_trigger_manager.dart';
import 'package:tilawa/features/reciters/data/repositories/reciters_repository_impl.dart';
import 'package:tilawa_core/errors/failures.dart';

class MockRecitersRemoteDataSource extends Mock
    implements RecitersRemoteDataSource {}

class MockRecitersLocalDataSource extends Mock
    implements RecitersLocalDataSource {}

class MockRecitersFavoritesDataSource extends Mock
    implements RecitersFavoritesDataSource {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

class MockAppReviewTriggerManager extends Mock
    implements AppReviewTriggerManager {}

UserEntity _testUser(String id) => UserEntity(
  id: id,
  email: 'test@tilawa.app',
  displayName: 'Test User',
  createdAt: DateTime(2024),
);

void main() {
  late RecitersRepositoryImpl repository;
  late MockRecitersRemoteDataSource mockRemote;
  late MockRecitersLocalDataSource mockLocal;
  late MockRecitersFavoritesDataSource mockFavorites;
  late MockAuthRepository mockAuth;
  late MockSharedPreferencesAsync mockPrefs;
  late MockAppReviewTriggerManager mockAppReviewTriggerManager;

  const int tReciterId = 7;
  const String tUserId = 'user-offline';
  const tReciterModel = ReciterModel(
    id: tReciterId,
    name: 'Offline Reciter',
    letter: 'O',
    date: '2024',
    moshaf: [],
  );

  setUpAll(() {
    registerFallbackValue(tReciterModel);
    registerFallbackValue(AppReviewSignal.favoriteReciterAdded);
    registerFallbackValue(AppReviewPromptMoment.favoriteReciterAdded);
  });

  setUp(() {
    mockRemote = MockRecitersRemoteDataSource();
    mockLocal = MockRecitersLocalDataSource();
    mockFavorites = MockRecitersFavoritesDataSource();
    mockAuth = MockAuthRepository();
    mockPrefs = MockSharedPreferencesAsync();
    mockAppReviewTriggerManager = MockAppReviewTriggerManager();
    when(() => mockAppReviewTriggerManager.onSessionStarted())
        .thenAnswer((_) async {});
    when(
      () => mockAppReviewTriggerManager.recordSignal(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockAppReviewTriggerManager.tryPromptIfEligible(any()),
    ).thenAnswer((_) async => false);
    repository = RecitersRepositoryImpl(
      mockRemote,
      mockLocal,
      mockFavorites,
      mockAuth,
      mockPrefs,
      mockAppReviewTriggerManager,
    );
    when(() => mockPrefs.getString(any())).thenAnswer((_) async => null);
  });

  group('toggleFavoriteReciter', () {
    test('guest saves locally and does not call remote favorites', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockLocal.getFavoriteReciterIds()).thenAnswer((_) async => []);
      when(
        () => mockLocal.saveFavoriteReciterId(tReciterId),
      ).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository
          .toggleFavoriteReciter(
            tReciterId,
          );

      expect(result.isRight, isTrue);
      verify(() => mockLocal.saveFavoriteReciterId(tReciterId)).called(1);
      verifyNever(
        () => mockFavorites.getFavoriteReciterIds(userId: any(named: 'userId')),
      );
      verifyNever(
        () => mockFavorites.addFavoriteReciter(
          userId: any(named: 'userId'),
          reciterId: any(named: 'reciterId'),
          reciterName: any(named: 'reciterName'),
        ),
      );
    });

    test(
      'signed-in user persists locally when remote favorites are unavailable',
      () async {
        when(() => mockAuth.currentUser).thenReturn(_testUser(tUserId));
        when(
          () => mockLocal.getFavoriteReciterIds(),
        ).thenAnswer((_) async => []);
        when(
          () => mockLocal.saveFavoriteReciterId(tReciterId),
        ).thenAnswer((_) async {});
        when(
          () => mockLocal.getReciters(language: any(named: 'language')),
        ).thenAnswer((_) async => [tReciterModel]);
        when(
          () => mockFavorites.addFavoriteReciter(
            userId: tUserId,
            reciterId: tReciterId,
            reciterName: tReciterModel.name,
          ),
        ).thenThrow(Exception('no network'));

        final Either<Failure, void> result = await repository
            .toggleFavoriteReciter(tReciterId);

        expect(result.isRight, isTrue);
        verify(() => mockLocal.saveFavoriteReciterId(tReciterId)).called(1);
      },
    );

    test(
      'signed-in user syncs add to remote after local save when online',
      () async {
        when(() => mockAuth.currentUser).thenReturn(_testUser(tUserId));
        when(
          () => mockLocal.getFavoriteReciterIds(),
        ).thenAnswer((_) async => []);
        when(
          () => mockLocal.saveFavoriteReciterId(tReciterId),
        ).thenAnswer((_) async {});
        when(
          () => mockLocal.getReciters(language: any(named: 'language')),
        ).thenAnswer((_) async => [tReciterModel]);
        when(
          () => mockFavorites.addFavoriteReciter(
            userId: tUserId,
            reciterId: tReciterId,
            reciterName: tReciterModel.name,
          ),
        ).thenAnswer((_) async {});

        final Either<Failure, void> result = await repository
            .toggleFavoriteReciter(tReciterId);

        expect(result.isRight, isTrue);
        verify(() => mockLocal.saveFavoriteReciterId(tReciterId)).called(1);
        verify(
          () => mockFavorites.addFavoriteReciter(
            userId: tUserId,
            reciterId: tReciterId,
            reciterName: tReciterModel.name,
          ),
        ).called(1);
      },
    );

    test(
      'signed-in user removes locally and from remote when unfavoriting',
      () async {
        when(() => mockAuth.currentUser).thenReturn(_testUser(tUserId));
        when(
          () => mockLocal.getFavoriteReciterIds(),
        ).thenAnswer((_) async => [tReciterId.toString()]);
        when(
          () => mockLocal.removeFavoriteReciterId(tReciterId),
        ).thenAnswer((_) async {});
        when(
          () => mockFavorites.removeFavoriteReciter(
            userId: tUserId,
            reciterId: tReciterId,
          ),
        ).thenAnswer((_) async {});

        final Either<Failure, void> result = await repository
            .toggleFavoriteReciter(tReciterId);

        expect(result.isRight, isTrue);
        verify(() => mockLocal.removeFavoriteReciterId(tReciterId)).called(1);
        verify(
          () => mockFavorites.removeFavoriteReciter(
            userId: tUserId,
            reciterId: tReciterId,
          ),
        ).called(1);
      },
    );
  });

  group('getFavoriteReciterIds', () {
    test('guest reads favorites from local storage only', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      when(
        () => mockLocal.getFavoriteReciterIds(),
      ).thenAnswer((_) async => ['7', '9']);

      final Either<Failure, List<String>> result = await repository
          .getFavoriteReciterIds();

      expect(result.isRight, isTrue);
      expect(result.getOrElse(() => []), ['7', '9']);
      verifyNever(
        () => mockFavorites.getFavoriteReciterIds(userId: any(named: 'userId')),
      );
    });

    test(
      'signed-in user falls back to local ids when remote merge fails',
      () async {
        when(() => mockAuth.currentUser).thenReturn(_testUser(tUserId));
        when(
          () => mockFavorites.getFavoriteReciterIds(userId: tUserId),
        ).thenThrow(Exception('offline'));
        when(
          () => mockLocal.getFavoriteReciterIds(),
        ).thenAnswer((_) async => ['7']);

        final Either<Failure, List<String>> result = await repository
            .getFavoriteReciterIds();

        expect(result.isRight, isTrue);
        expect(result.getOrElse(() => []), ['7']);
        verify(() => mockLocal.getFavoriteReciterIds()).called(1);
      },
    );
  });
}
