import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../network/network_info.dart';
import 'internet_status_event.dart';
import 'internet_status_state.dart';

@injectable
class InternetStatusBloc
    extends Bloc<InternetStatusEvent, InternetStatusState> {
  InternetStatusBloc(this._networkInfo)
    : super(const InternetStatusState.connected()) {
    on<InternetStatusEvent>((event, emit) async {
      await event.when(
        statusChanged: (isConnected) {
          emit(
            isConnected
                ? const InternetStatusState.connected()
                : const InternetStatusState.disconnected(),
          );
        },
      );
    });

    _subscription = _networkInfo.onConnectivityChanged.listen((isConnected) {
      add(InternetStatusEvent.statusChanged(isConnected));
    });
  }
  final NetworkInfo _networkInfo;
  StreamSubscription<bool>? _subscription;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
