import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa_core/network/network_info_impl.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late NetworkInfoImpl networkInfo;
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockConnectivity = MockConnectivity();
  });

  group('isConnected', () {
    test(
      'should return true when connectivity is not none',
      () async {
        // arrange
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        networkInfo = NetworkInfoImpl(
          mockConnectivity,
        );

        // act
        final bool result = await networkInfo.isConnected;

        // assert
        expect(result, true);
        verify(() => mockConnectivity.checkConnectivity());
      },
    );

    test('should return false when connectivity result is none', () async {
      // arrange
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      networkInfo = NetworkInfoImpl(
        mockConnectivity,
      );

      // act
      final bool result = await networkInfo.isConnected;

      // assert
      expect(result, false);
      verify(() => mockConnectivity.checkConnectivity());
    });

    test(
      'should return false when checkConnectivity throws Exception',
      () async {
        // arrange
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenThrow(Exception('Connectivity error'));

        networkInfo = NetworkInfoImpl(
          mockConnectivity,
        );

        // act
        final bool result = await networkInfo.isConnected;

        // assert
        expect(result, false);
      },
    );

    test('reuses the cached result within the TTL', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      networkInfo = NetworkInfoImpl(
        mockConnectivity,
      );

      expect(await networkInfo.isConnected, true);
      expect(await networkInfo.isConnected, true);
      expect(await networkInfo.isConnected, true);

      verify(() => mockConnectivity.checkConnectivity()).called(1);
    });

    test('caches an offline result for rapid repeated checks', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      networkInfo = NetworkInfoImpl(mockConnectivity);

      expect(await networkInfo.isConnected, false);
      expect(await networkInfo.isConnected, false);

      verify(() => mockConnectivity.checkConnectivity()).called(1);
    });

    test('re-probes after the cache TTL expires', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      DateTime current = DateTime(2026, 7, 2, 12);
      networkInfo = NetworkInfoImpl(
        mockConnectivity,
        now: () => current,
      );

      expect(await networkInfo.isConnected, true);
      current = current.add(
        NetworkInfoImpl.resultCacheTtl + const Duration(seconds: 1),
      );
      expect(await networkInfo.isConnected, true);

      verify(() => mockConnectivity.checkConnectivity()).called(2);
    });

    test('deduplicates concurrent checks into one probe', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      final Completer<List<ConnectivityResult>> connectivityCompleter =
          Completer<List<ConnectivityResult>>();
      int checkCalls = 0;
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) {
        checkCalls++;
        return connectivityCompleter.future;
      });

      networkInfo = NetworkInfoImpl(
        mockConnectivity,
      );

      final Future<bool> first = networkInfo.isConnected;
      final Future<bool> second = networkInfo.isConnected;

      connectivityCompleter.complete([ConnectivityResult.wifi]);

      expect(await first, true);
      expect(await second, true);
      expect(checkCalls, 1);
    });
  });

  group('onConnectivityChanged', () {
    test(
      'should emit true when connectivity results do not contain none',
      () async {
        // arrange
        final List<ConnectivityResult> results = [
          ConnectivityResult.wifi,
          ConnectivityResult.mobile,
        ];
        when(
          () => mockConnectivity.onConnectivityChanged,
        ).thenAnswer((_) => Stream.value(results));

        networkInfo = NetworkInfoImpl(mockConnectivity);

        // act
        final bool result = await networkInfo.onConnectivityChanged.first;

        // assert
        expect(result, true);
      },
    );

    test('should emit false when connectivity results contain none', () async {
      // arrange
      final List<ConnectivityResult> results = [ConnectivityResult.none];
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => Stream.value(results));

      networkInfo = NetworkInfoImpl(mockConnectivity);

      // act
      final bool result = await networkInfo.onConnectivityChanged.first;

      // assert
      expect(result, false);
    });
  });
}
