/// Gate for [Hive.init] completion before local boxes are opened.
abstract class HiveReadiness {
  Future<void> ensureReady();
}
