import 'package:checks/checks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa/features/quran_sessions/data/firebase/firestore_exception_mapper.dart';

void main() {
  group('mapFirebaseException', () {
    test('maps permission-denied to PermissionDeniedException', () {
      final mapped = mapFirebaseException(
        FirebaseException(plugin: 'firestore', code: 'permission-denied'),
      );
      check(mapped).isA<PermissionDeniedException>();
    });

    test('maps unavailable to NetworkException', () {
      final mapped = mapFirebaseException(
        FirebaseException(plugin: 'firestore', code: 'unavailable'),
      );
      check(mapped).isA<NetworkException>();
    });

    test('reads Timestamp as DateTime', () {
      final value = readDateTime(Timestamp.fromDate(DateTime.utc(2024, 6, 1)));
      check(value!.toUtc()).equals(DateTime.utc(2024, 6, 1));
    });
  });
}
