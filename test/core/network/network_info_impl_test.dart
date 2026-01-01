import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/core/network/network_info_impl.dart';

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
