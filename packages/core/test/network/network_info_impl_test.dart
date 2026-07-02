import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fake_async/fake_async.dart';
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
      'should return true when connectivity is not none and lookup is successful',
      () async {
        // arrange
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        final mockInternetLookup = MockInternetLookup();
        when(
          () => mockInternetLookup.call(any()),
        ).thenAnswer((_) async => [MockInternetAddress()]);

        networkInfo = NetworkInfoImpl(
          mockConnectivity,
          internetLookup: mockInternetLookup.call,
        );

        // act
        final bool result = await networkInfo.isConnected;

        // assert
        expect(result, true);
        verify(() => mockConnectivity.checkConnectivity());
        verify(() => mockInternetLookup.call('google.com'));
      },
    );

    test('should return false when connectivity result is none', () async {
      // arrange
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      final mockInternetLookup = MockInternetLookup();

      networkInfo = NetworkInfoImpl(
        mockConnectivity,
        internetLookup: mockInternetLookup.call,
      );

      // act
      final bool result = await networkInfo.isConnected;

      // assert
      expect(result, false);
      verify(() => mockConnectivity.checkConnectivity());
      verifyNever(() => mockInternetLookup.call(any()));
    });

    test('should return false when lookup throws SocketException', () async {
      // arrange
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.mobile]);

      final mockInternetLookup = MockInternetLookup();
      when(
        () => mockInternetLookup.call(any()),
      ).thenThrow(const SocketException('No internet'));

      networkInfo = NetworkInfoImpl(
        mockConnectivity,
        internetLookup: mockInternetLookup.call,
      );

      // act
      final bool result = await networkInfo.isConnected;

      // assert
      expect(result, false);
    });

    test('should return false when lookup result is empty', () async {
      // arrange
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.mobile]);

      final mockInternetLookup = MockInternetLookup();
      when(() => mockInternetLookup.call(any())).thenAnswer((_) async => []);

      networkInfo = NetworkInfoImpl(
        mockConnectivity,
        internetLookup: mockInternetLookup.call,
      );

      // act
      final bool result = await networkInfo.isConnected;

      // assert
      expect(result, false);
    });
    test('gives up on a slow lookup after lookupTimeout', () {
      fakeAsync((async) {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        final Completer<List<InternetAddress>> neverCompletes =
            Completer<List<InternetAddress>>();
        networkInfo = NetworkInfoImpl(
          mockConnectivity,
          internetLookup:
              (
                String host, {
                InternetAddressType type = InternetAddressType.any,
              }) => neverCompletes.future,
        );

        bool? result;
        networkInfo.isConnected.then((value) => result = value);

        async.elapse(
          NetworkInfoImpl.lookupTimeout - const Duration(milliseconds: 1),
        );
        expect(result, isNull);

        async.elapse(const Duration(milliseconds: 2));
        expect(result, false);
      });
    });

    test('reuses the cached result within the TTL', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      final mockInternetLookup = MockInternetLookup();
      when(
        () => mockInternetLookup.call(any()),
      ).thenAnswer((_) async => [MockInternetAddress()]);

      networkInfo = NetworkInfoImpl(
        mockConnectivity,
        internetLookup: mockInternetLookup.call,
      );

      expect(await networkInfo.isConnected, true);
      expect(await networkInfo.isConnected, true);
      expect(await networkInfo.isConnected, true);

      verify(() => mockInternetLookup.call(any())).called(1);
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

      final mockInternetLookup = MockInternetLookup();
      when(
        () => mockInternetLookup.call(any()),
      ).thenAnswer((_) async => [MockInternetAddress()]);

      DateTime current = DateTime(2026, 7, 2, 12);
      networkInfo = NetworkInfoImpl(
        mockConnectivity,
        internetLookup: mockInternetLookup.call,
        now: () => current,
      );

      expect(await networkInfo.isConnected, true);
      current = current.add(
        NetworkInfoImpl.resultCacheTtl + const Duration(seconds: 1),
      );
      expect(await networkInfo.isConnected, true);

      verify(() => mockInternetLookup.call(any())).called(2);
    });

    test('deduplicates concurrent checks into one probe', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      final Completer<List<InternetAddress>> lookupCompleter =
          Completer<List<InternetAddress>>();
      int lookupCalls = 0;
      networkInfo = NetworkInfoImpl(
        mockConnectivity,
        internetLookup:
            (
              String host, {
              InternetAddressType type = InternetAddressType.any,
            }) {
              lookupCalls++;
              return lookupCompleter.future;
            },
      );

      final Future<bool> first = networkInfo.isConnected;
      final Future<bool> second = networkInfo.isConnected;

      lookupCompleter.complete([MockInternetAddress()]);

      expect(await first, true);
      expect(await second, true);
      expect(lookupCalls, 1);
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

abstract class InternetLookupMock {
  Future<List<InternetAddress>> call(
    String host, {
    InternetAddressType type = InternetAddressType.any,
  });
}

class MockInternetLookup extends Mock implements InternetLookupMock {}

class MockInternetAddress extends Mock implements InternetAddress {
  @override
  Uint8List get rawAddress => Uint8List.fromList([1, 2, 3, 4]);
}
