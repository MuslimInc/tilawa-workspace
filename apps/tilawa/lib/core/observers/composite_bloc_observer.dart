import 'package:hydrated_bloc/hydrated_bloc.dart';

class CompositeBlocObserver extends BlocObserver {
  CompositeBlocObserver({required this.observers});

  final List<BlocObserver> observers;

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    for (final observer in observers) {
      observer.onCreate(bloc);
    }
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    for (final observer in observers) {
      observer.onEvent(bloc, event);
    }
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    for (final observer in observers) {
      observer.onChange(bloc, change);
    }
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    for (final observer in observers) {
      observer.onTransition(bloc, transition);
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    for (final observer in observers) {
      observer.onError(bloc, error, stackTrace);
    }
  }

  @override
  void onDone(
    Bloc bloc,
    Object? event, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    super.onDone(bloc, event, error, stackTrace);
    for (final observer in observers) {
      observer.onDone(bloc, event, error, stackTrace);
    }
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    for (final observer in observers) {
      observer.onClose(bloc);
    }
  }
}
