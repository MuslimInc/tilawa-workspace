import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tilawa/core/network/network_info.dart';
import 'package:tilawa/core/presentation/bloc/internet_status/internet_status_bloc.dart';
import 'package:tilawa/core/presentation/bloc/internet_status/internet_status_state.dart';

import 'internet_status_bloc_test.mocks.dart';

@GenerateMocks([NetworkInfo])
void main() {
  late InternetStatusBloc bloc;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockNetworkInfo = MockNetworkInfo();
  });

  group('InternetStatusBloc', () {
    test('initial state is connected', () {
      when(
        mockNetworkInfo.onConnectivityChanged,
      ).thenAnswer((_) => Stream.value(true));
      bloc = InternetStatusBloc(mockNetworkInfo);
      expect(bloc.state, const InternetStatusState.connected());
    });

    blocTest<InternetStatusBloc, InternetStatusState>(
      'emits [disconnected] when onConnectivityChanged emits false',
      build: () {
        when(
          mockNetworkInfo.onConnectivityChanged,
        ).thenAnswer((_) => Stream.value(false));
        return InternetStatusBloc(mockNetworkInfo);
      },
      act: (bloc) => Future.delayed(Duration.zero), // Wait for stream listener
      expect: () => [const InternetStatusState.disconnected()],
    );

    blocTest<InternetStatusBloc, InternetStatusState>(
      'emits [connected] when onConnectivityChanged emits true',
      build: () {
        when(
          mockNetworkInfo.onConnectivityChanged,
        ).thenAnswer((_) => Stream.value(true));
        return InternetStatusBloc(mockNetworkInfo);
      },
      act: (bloc) => Future.delayed(Duration.zero),
      expect: () => [const InternetStatusState.connected()],
    );
  });
}
