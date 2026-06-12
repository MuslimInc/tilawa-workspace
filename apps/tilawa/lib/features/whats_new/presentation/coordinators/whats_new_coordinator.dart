import 'package:injectable/injectable.dart';
import 'package:tilawa/core/logging/app_logger.dart';
import 'package:tilawa/features/tour_guide/domain/services/tour_flow_guard.dart';
import 'package:tilawa/router/app_router.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../domain/entities/changelog_release.dart';
import '../../domain/entities/whats_new_eligibility.dart';
import '../../domain/entities/whats_new_source.dart';
import '../../domain/usecases/get_current_changelog_release_use_case.dart';
import '../../domain/usecases/get_whats_new_eligibility_use_case.dart';
import '../../domain/usecases/mark_whats_new_seen_use_case.dart';
import '../services/whats_new_presenter.dart';

/// Orchestrates when and how the what's new sheet is shown.
@singleton
class WhatsNewCoordinator {
  WhatsNewCoordinator(
    this._getEligibility,
    this._getCurrentRelease,
    this._markSeen,
    this._presenter,
    this._analytics,
    this._flowGuard,
  );

  final GetWhatsNewEligibilityUseCase _getEligibility;
  final GetCurrentChangelogReleaseUseCase _getCurrentRelease;
  final MarkWhatsNewSeenUseCase _markSeen;
  final WhatsNewPresenter _presenter;
  final AnalyticsService _analytics;
  final TourFlowGuard _flowGuard;

  bool _autoPromptShownThisSession = false;
  Future<void>? _inFlightShow;

  Future<void> maybeShowAfterLaunch() async {
    if (_inFlightShow != null) {
      await _inFlightShow;
      return;
    }

    final Future<void> showFuture = _maybeShowAfterLaunchInternal();
    _inFlightShow = showFuture;
    try {
      await showFuture;
    } finally {
      if (identical(_inFlightShow, showFuture)) {
        _inFlightShow = null;
      }
    }
  }

  Future<void> showFromSettings() async {
    final ChangelogRelease? release = await _resolveCurrentRelease();
    if (release == null) {
      await _logLoadFailed('missing_release');
      return;
    }

    await _logEvent(
      AnalyticsEvents.whatsNewOpenSettings,
      _releaseAnalyticsParams(release),
    );

    await _presentRelease(release: release, source: WhatsNewSource.settings);
  }

  Future<void> _maybeShowAfterLaunchInternal() async {
    final String? routePath = _currentRoutePath();
    if (routePath == null) {
      // The launch timer fired before the router resolved its first route
      // (seen on slow devices). The app is still on a launch surface, so
      // treat it like a blocked route and retry on the next launch.
      await _logSkipped(WhatsNewSkipReason.blockedRoute);
      return;
    }
    final WhatsNewEligibility eligibility = await _getEligibility(
      currentRoutePath: routePath,
      sacredFlowBlocked: _flowGuard.isBlocked,
      sessionAlreadyShown: _autoPromptShownThisSession,
    );

    if (!eligibility.shouldShow) {
      if (eligibility.skipReason != null) {
        await _logSkipped(eligibility.skipReason!);
      }
      return;
    }

    final ChangelogRelease release = eligibility.release!;
    _autoPromptShownThisSession = true;

    await _presentRelease(release: release, source: WhatsNewSource.auto);
  }

  Future<ChangelogRelease?> _resolveCurrentRelease() async {
    final result = await _getCurrentRelease();
    return result.fold(
      (_) => null,
      (ChangelogRelease value) => value,
    );
  }

  Future<void> _presentRelease({
    required ChangelogRelease release,
    required WhatsNewSource source,
  }) async {
    final DateTime shownAt = DateTime.now();

    await _logEvent(
      AnalyticsEvents.whatsNewShown,
      <String, Object>{
        ..._releaseAnalyticsParams(release),
        AnalyticsParams.source: source.name,
        AnalyticsParams.count: release.highlightsFor('en').length,
      },
    );

    try {
      await _presenter.show(
        release: release,
        onDismissed: () async {
          final int dwellMs = DateTime.now().difference(shownAt).inMilliseconds;
          await _markSeen(release.id);
          await _logEvent(
            AnalyticsEvents.whatsNewDismissed,
            <String, Object>{
              ..._releaseAnalyticsParams(release),
              AnalyticsParams.source: source.name,
              AnalyticsParams.elapsedMs: dwellMs,
            },
          );
        },
      );
    } catch (e) {
      logger.e('[WhatsNewCoordinator] Failed to present sheet: $e');
    }
  }

  Map<String, Object> _releaseAnalyticsParams(ChangelogRelease release) {
    return <String, Object>{
      AnalyticsParams.releaseId: release.id,
      AnalyticsParams.appVersion: release.version,
      AnalyticsParams.buildNumber: release.buildNumber,
    };
  }

  /// Returns null while the router has no matches yet — reading
  /// [GoRouter.state] before the first route resolves throws a StateError.
  String? _currentRoutePath() {
    if (AppRouter.router.routerDelegate.currentConfiguration.isEmpty) {
      return null;
    }
    final String path = AppRouter.router.state.uri.path;
    if (path.isNotEmpty) {
      return path;
    }
    return AppRouter.router.state.matchedLocation;
  }

  Future<void> _logSkipped(WhatsNewSkipReason reason) async {
    await _logEvent(
      AnalyticsEvents.whatsNewSkipped,
      <String, Object>{
        AnalyticsParams.reason: reason.name,
      },
    );
  }

  Future<void> _logLoadFailed(String reason) async {
    await _logEvent(
      AnalyticsEvents.whatsNewLoadFailed,
      <String, Object>{
        AnalyticsParams.reason: reason,
      },
    );
  }

  Future<void> _logEvent(String name, Map<String, Object> parameters) async {
    try {
      await _analytics.logEvent(name, parameters: parameters);
    } catch (e) {
      logger.d('[WhatsNewCoordinator] Analytics error: $e');
    }
  }
}
