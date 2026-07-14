import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa/features/auth/domain/entities/server_session_snapshot.dart';
import 'package:tilawa/features/auth/domain/entities/session_validity_result.dart';
import 'package:tilawa/features/auth/domain/repositories/session_validity_repository.dart';
import 'package:tilawa/features/auth/domain/services/token_sync_cache.dart';
import 'package:tilawa/features/auth/domain/usecases/check_session_validity_use_case.dart';

class MockTokenSyncCache extends Mock implements TokenSyncCache {}

class MockSessionValidityRepository extends Mock
    implements SessionValidityRepository {}

void main() {
  late CheckSessionValidityUseCase useCase;
  late MockSessionValidityRepository mockRepository;
  late MockTokenSyncCache mockCache;

  setUp(() {
    mockRepository = MockSessionValidityRepository();
    mockCache = MockTokenSyncCache();
    useCase = CheckSessionValidityUseCase(mockRepository, mockCache);
  });

  void stubLocal({required int epoch, String? deviceId}) {
    when(() => mockCache.getSessionEpoch()).thenAnswer((_) async => epoch);
    when(() => mockCache.getActiveDeviceId()).thenAnswer((_) async => deviceId);
  }

  void stubServer({required int epoch, required String deviceId}) {
    when(() => mockRepository.fetchServerSession(any())).thenAnswer(
      (_) async => Right(
        ServerSessionSnapshot(epoch: epoch, activeDeviceId: deviceId),
      ),
    );
  }

  test(
    'returns valid when local epoch and active device match server',
    () async {
      stubLocal(epoch: 3, deviceId: 'device_1');
      stubServer(epoch: 3, deviceId: 'device_1');

      final result = await useCase('user_1');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (validity) {
        expect(validity, SessionValidityResult.valid);
      });
    },
  );

  test('returns stale when local epoch is stale', () async {
    stubLocal(epoch: 1, deviceId: 'device_1');
    stubServer(epoch: 4, deviceId: 'device_1');

    final result = await useCase('user_1');

    result.fold((_) => fail('expected Right'), (validity) {
      expect(validity, SessionValidityResult.stale);
    });
  });

  test('returns stale when active device differs', () async {
    stubLocal(epoch: 4, deviceId: 'device_1');
    stubServer(epoch: 4, deviceId: 'device_2');

    final result = await useCase('user_1');

    result.fold((_) => fail('expected Right'), (validity) {
      expect(validity, SessionValidityResult.stale);
    });
  });

  test(
    'returns verificationUnknown when local device registration is incomplete',
    () async {
      stubLocal(epoch: 0, deviceId: null);
      stubServer(epoch: 1, deviceId: 'device_1');

      final result = await useCase('user_1');

      result.fold((_) => fail('expected Right'), (validity) {
        expect(validity, SessionValidityResult.verificationUnknown);
      });
      verifyNever(() => mockRepository.fetchServerSession(any()));
    },
  );

  test(
    'returns verificationUnknown when server session doc lags after first login',
    () async {
      stubLocal(epoch: 2, deviceId: 'device_1');
      stubServer(epoch: 0, deviceId: '');

      final result = await useCase('user_1');

      result.fold((_) => fail('expected Right'), (validity) {
        expect(validity, SessionValidityResult.verificationUnknown);
      });
    },
  );

  test(
    'returns verificationUnknown when repository reports network failure',
    () async {
      stubLocal(epoch: 3, deviceId: 'device_1');
      when(() => mockRepository.fetchServerSession(any())).thenAnswer(
        (_) async => const Left(
          ServerFailure(SessionValidityFailureKey.network),
        ),
      );

      final result = await useCase('user_1');

      result.fold((_) => fail('expected Right'), (validity) {
        expect(validity, SessionValidityResult.verificationUnknown);
      });
    },
  );

  test(
    'returns verificationUnknown for raw connectivity errors from cache',
    () async {
      when(() => mockCache.getSessionEpoch()).thenThrow(
        Exception(
          'SocketException: Failed host lookup: firestore.googleapis.com',
        ),
      );

      final result = await useCase('user_1');

      result.fold((_) => fail('expected Right'), (validity) {
        expect(validity, SessionValidityResult.verificationUnknown);
      });
    },
  );

  test(
    'propagates typed ServerFailure from repository',
    () async {
      stubLocal(epoch: 3, deviceId: 'device_1');
      when(() => mockRepository.fetchServerSession(any())).thenAnswer(
        (_) async => const Left(
          ServerFailure('session_validity_check_permission-denied'),
        ),
      );

      final result = await useCase('user_1');

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, contains('permission-denied'));
        },
        (_) => fail('expected Left'),
      );
    },
  );

  test(
    'returns a typed UnexpectedFailure for unknown cache errors',
    () async {
      when(() => mockCache.getSessionEpoch()).thenThrow(
        StateError('schema drift'),
      );

      final result = await useCase('user_1');

      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (_) => fail('expected Left'),
      );
    },
  );
}
