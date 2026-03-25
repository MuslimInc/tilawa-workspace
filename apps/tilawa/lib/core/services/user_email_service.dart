import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa/core/logging/app_logger.dart';

abstract class UserEmailService {
  Future<List<String>> getUserEmails();
}

@LazySingleton(as: UserEmailService)
class UserEmailServiceImpl implements UserEmailService {
  UserEmailServiceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<String>> getUserEmails() async {
    try {
      logger.d('📧 Fetching user emails from Firestore...');

      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
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

      logger.d('✅ Successfully fetched ${emails.length} user emails');
      return emails;
    } catch (e) {
      logger.d('❌ Error fetching user emails: $e');
      rethrow;
    }
  }
}
