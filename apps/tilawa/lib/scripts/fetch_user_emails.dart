import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tilawa_core/logger.dart';

import '../firebase_options.dart';

Future<void> main() async {
  logger.i('🚀 Initializing Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  logger.i('📧 Fetching user emails from Firestore...\n');
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
        .collection('users')
        .get();

    final List<String> emails = snapshot.docs
        .map((doc) {
          final Map<String, dynamic> data = doc.data();
          return data['email'] as String?;
        })
        .where((email) => email != null && email.isNotEmpty)
        .cast<String>()
        .toList();

    logger.i('✅ Found ${emails.length} user email(s):\n');
    if (emails.isEmpty) {
      logger.i('   No users found in the database.\n');
    } else {
      for (var i = 0; i < emails.length; i++) {
        logger.i('   ${i + 1}. ${emails[i]}');
      }
    }
  } catch (e, stackTrace) {
    logger.e('❌ Error fetching emails: $e');
    logger.e('Stack trace: $stackTrace\n');
  }
}
