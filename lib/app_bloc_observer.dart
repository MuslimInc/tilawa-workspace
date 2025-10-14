import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/main.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    logger.d('[BlocObserver] onEvent: $event');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    logger.d('[BlocObserver] onTransition: $transition');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    logger.d('[BlocObserver] onError: $error');
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    logger.d('[BlocObserver] onClose: $bloc');
  }

  @override
  void onDone(
    Bloc bloc,
    Object? event, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    super.onDone(bloc, event);
    logger.d('[BlocObserver] onDone: $event');
  }
}
