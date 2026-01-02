import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

Future<void> main() async {
  print('🚀 Initializing Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('📧 Fetching user emails from Firestore...\n');
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

    print('✅ Found ${emails.length} user email(s):\n');
    if (emails.isEmpty) {
      print('   No users found in the database.\n');
    } else {
      for (var i = 0; i < emails.length; i++) {
        print('   ${i + 1}. ${emails[i]}');
      }
    }
    print('');
  } catch (e, stackTrace) {
    print('❌ Error fetching emails: $e');
    print('Stack trace: $stackTrace\n');
  }
}
