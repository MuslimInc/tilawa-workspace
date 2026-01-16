import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/crashlytics_service.dart';

/// BlocObserver that reports errors and breadcrumbs to Crashlytics
class CrashlyticsBlocObserver extends BlocObserver {
  CrashlyticsBlocObserver(this._crashlyticsService);

  final CrashlyticsService _crashlyticsService;

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _crashlyticsService.setBreadcrumb(
      'Bloc Event: (${bloc.runtimeType}) > $event',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _crashlyticsService.setBreadcrumb(
      'Bloc Transition: (${bloc.runtimeType}) > $transition',
    );
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
