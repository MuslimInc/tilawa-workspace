import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../logging/app_logger.dart';

/// Writes structured startup events to Firestore for backend-style querying.
///
/// Collection: [collectionName] (`app_startup_logs`). Deploy rules from
/// [docs/observability/startup_health_logs.md](../../../../docs/observability/startup_health_logs.md).
abstract class StartupHealthLogSink {
  Future<void> write(Map<String, Object?> entry);
}

/// Production sink: one document per startup milestone or failure.
class FirestoreStartupHealthLogSink implements StartupHealthLogSink {
  FirestoreStartupHealthLogSink({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'app_startup_logs';

  final FirebaseFirestore _firestore;

  @override
  Future<void> write(Map<String, Object?> entry) async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    try {
      final Map<String, Object?> payload = Map<String, Object?>.from(entry);
      payload['server_ingested_at'] = FieldValue.serverTimestamp();
      await _firestore.collection(collectionName).add(payload);
    } catch (e, st) {
      logger.d('Startup health log write failed: $e', stackTrace: st);
    }
  }
}

/// No-op sink for tests and when Firestore logging is disabled.
class NoopStartupHealthLogSink implements StartupHealthLogSink {
  const NoopStartupHealthLogSink();

  @override
  Future<void> write(Map<String, Object?> entry) async {}
}

/// In-memory sink for unit tests.
class InMemoryStartupHealthLogSink implements StartupHealthLogSink {
  final List<Map<String, Object?>> entries = <Map<String, Object?>>[];

  @override
  Future<void> write(Map<String, Object?> entry) async {
    entries.add(Map<String, Object?>.from(entry));
  }
}
