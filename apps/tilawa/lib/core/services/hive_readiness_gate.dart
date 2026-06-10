import 'package:injectable/injectable.dart';

import '../bootstrap/app_startup.dart';
import 'hive_readiness.dart';

/// Ensures [Hive.init] completed before local Hive boxes are opened.
@LazySingleton(as: HiveReadiness)
class HiveReadinessGate implements HiveReadiness {
  @override
  Future<void> ensureReady() => ensureHiveInitialized();
}
