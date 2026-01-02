import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tilawa/core/services/user_email_service.dart';
import 'package:tilawa/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  testWidgets('Fetch all user emails from Firestore', (tester) async {
    print('\n📧 Fetching user emails from Firestore...\n');

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final userEmailService = UserEmailServiceImpl(firestore);

    final List<String> emails = await userEmailService.getUserEmails();

    print('✅ Found ${emails.length} user email(s):\n');
    if (emails.isEmpty) {
      print('   No users found in the database.\n');
    } else {
      for (var i = 0; i < emails.length; i++) {
        print('   ${i + 1}. ${emails[i]}');
      }
      print('');
    }

    // Test passes regardless of result count
    expect(emails, isA<List<String>>());
  });
}
