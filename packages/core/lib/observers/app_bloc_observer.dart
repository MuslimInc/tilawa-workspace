import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_core/logger.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    logger.d('[BlocObserver] onEvent: (${bloc.runtimeType}) > $event');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    // logger.d(
    //   '[BlocObserver] onTransition: (${bloc.runtimeType}) > $transition',
    // );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    logger.d(
      '[BlocObserver] onError: (${bloc.runtimeType}) > $error',
      stackTrace: stackTrace,
    );
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    logger.d('[BlocObserver] onClose: (${bloc.runtimeType})');
  }

  @override
  void onDone(
    Bloc bloc,
    Object? event, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    super.onDone(bloc, event);
    // logger.d(
    //   '[BlocObserver] onDone: (${bloc.runtimeType}) > $event',
    //   error: error,
    //   stackTrace: stackTrace,
    // );
  }
}
