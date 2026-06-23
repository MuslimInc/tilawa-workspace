import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tilawa_core/logger.dart';

import '../features/quran_sessions/data/firebase/firestore_market_config_repository.dart';
import '../firebase_options.dart';

/// Seeds curated MVP market configs (EG, SA, AE) into Firestore.
///
/// Run from `apps/tilawa`:
/// `dart run lib/scripts/seed_market_configs.dart`
///
/// **Important:** Production Firestore rules deny client writes to
/// `quran_session_market_configs`. For production/dev, seed via Admin SDK:
/// `cd functions && npm run seed:market-configs:apply` (see
/// `docs/quran_sessions_market_config_sources.md`). This Dart script works
/// against the emulator or when rules allow admin writes.
Future<void> main() async {
  logger.i('Initializing Firebase…');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  logger.i('Seeding quran_session_market_configs…');
  final seeder = FirestoreMarketConfigSeeder(FirebaseFirestore.instance);
  try {
    await seeder.seedDefaultCatalog();
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      logger.e(
        'Permission denied: client SDK cannot write market configs '
        '(firestore.rules: allow write: if false). '
        'Use Firebase Console import, Admin SDK, or the Firestore emulator.',
      );
      exit(64);
    }
    logger.e('Firestore seed failed: ${e.code} — ${e.message}');
    exit(1);
  }

  logger.i('Done. Enabled countries: EG, SA, AE.');
}
