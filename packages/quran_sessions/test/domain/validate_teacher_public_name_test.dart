import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/src/domain/failures/quran_sessions_failure.dart';
import 'package:quran_sessions/src/domain/value_objects/teacher_public_name.dart';

void main() {
  group('ValidateTeacherPublicName', () {
    test('requires a non-empty public teacher name', () {
      final missing = ValidateTeacherPublicName.failureFor(null);
      check(missing).isA<ValidationFailure>();
      check(missing!.code).equals('required');

      final empty = ValidateTeacherPublicName.failureFor('');
      check(empty).isA<ValidationFailure>();
      check(empty!.code).equals('required');
    });

    test('rejects whitespace-only names', () {
      final failure = ValidateTeacherPublicName.failureFor('   ');
      check(failure).isA<ValidationFailure>();
      check(failure!.code).equals('required');
    });

    test('rejects placeholder names such as Quran Teacher', () {
      for (final placeholder in [
        'Quran Teacher',
        'quran teacher',
        'محفظ قرآن',
      ]) {
        final failure = ValidateTeacherPublicName.failureFor(placeholder);
        check(failure).isA<ValidationFailure>();
        check(failure!.code).equals('placeholder');
      }
    });

    test('accepts real teacher names', () {
      check(ValidateTeacherPublicName.failureFor('Ustad Ahmad Ali')).isNull();
      check(
        ValidateTeacherPublicName.normalize('  Sheikh Omar  '),
      ).equals('Sheikh Omar');
    });
  });
}
