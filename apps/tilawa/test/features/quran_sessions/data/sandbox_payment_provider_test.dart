import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/quran_sessions/data/disabled_payment_provider.dart';
import 'package:tilawa/features/quran_sessions/data/sandbox_payment_provider.dart';

void main() {
  test('DisabledPaymentProvider blocks charge', () async {
    const provider = DisabledPaymentProvider();
    final result = await provider.charge(
      amountUsd: 10,
      currency: 'EGP',
      description: 'test',
      studentId: 'student_1',
    );
    expect(result.isLeft(), isTrue);
  });

  test('SandboxPaymentProvider type exists', () {
    expect(SandboxPaymentProvider, isA<Type>());
  });
}
