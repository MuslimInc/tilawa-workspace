import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/services/crashlytics_service.dart';

/// BlocObserver that reports errors and breadcrumbs to Crashlytics
class CrashlyticsBlocObserver extends BlocObserver {
  CrashlyticsBlocObserver(this._crashlyticsService);

  final CrashlyticsService _crashlyticsService;

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    if (_shouldIgnoreEvent(event)) return;
    _crashlyticsService.setBreadcrumb(
      'Bloc Event: (${bloc.runtimeType}) > $event',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    if (_shouldIgnoreEvent(transition.event)) return;
    _crashlyticsService.setBreadcrumb(
      'Bloc Transition: (${bloc.runtimeType}) > $transition',
    );
  }

  bool _shouldIgnoreEvent(Object? event) {
    final String eventString = event.toString();
    return eventString.contains('refreshCountdown') ||
        eventString.contains('updatePosition') ||
        eventString.contains('UpdatePosition') ||
        eventString.contains('AudioTimerExpired');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _crashlyticsService.recordError(
      error,
      stackTrace,
      reason: 'Bloc Error in ${bloc.runtimeType}',
    );
  }
}
