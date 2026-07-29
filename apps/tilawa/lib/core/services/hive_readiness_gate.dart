import '../bootstrap/app_startup.dart';
import 'hive_readiness.dart';

/// Ensures [Hive.init] completed before local Hive boxes are opened.
class HiveReadinessGate implements HiveReadiness {
  @override
  Future<void> ensureReady() => ensureHiveInitialized();
}
