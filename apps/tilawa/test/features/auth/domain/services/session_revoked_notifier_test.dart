import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/auth/domain/services/session_revoked_notifier.dart';

void main() {
  late SessionRevokedNotifier notifier;

  setUp(() {
    notifier = SessionRevokedNotifier();
  });

  test('dedupes repeated session_revoked notifications', () async {
    var count = 0;
    final sub = notifier.onSessionRevoked.listen((_) => count++);

    notifier.notifySessionRevoked();
    notifier.notifySessionRevoked();
    await Future<void>.delayed(Duration.zero);

    expect(count, 1);
    await sub.cancel();
  });
}
