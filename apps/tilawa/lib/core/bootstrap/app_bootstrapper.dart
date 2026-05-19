import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tilawa/core/bootstrap/app_startup.dart';
import 'package:tilawa/core/bootstrap/app_startup_tasks.dart';
import 'package:tilawa/core/bootstrap/launch_timeline.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/logging/app_logger.dart';

class AppBootstrapper {
  const AppBootstrapper({required this._startupTasks});

  final AppStartupTasks _startupTasks;

  Future<void> bootstrap({
    AppRunner? runner,
    DiConfigurator? diConfigurator,
  }) async {
    logger.d(
      '[AppLaunch] source=AppBootstrapper.bootstrap: Start in (${DateTime.now()})',
    );
    final AppRunner run = runner ?? runApp;
    final DiConfigurator configureDI = diConfigurator ?? configureDependencies;
    final LaunchTimeline timeline = LaunchTimeline();

    try {
      await runBootstrapPhases(
        run: run,
        configureDI: configureDI,
        timeline: timeline,
      );
    } catch (e, stackTrace) {
      logger.f('CATASTROPHIC ERROR in bootstrap(): $e', stackTrace: stackTrace);
      run(_startupTasks.buildFatalErrorApp());
    }
  }
}
