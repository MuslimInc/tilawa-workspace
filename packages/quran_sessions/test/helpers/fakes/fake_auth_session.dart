import 'package:quran_sessions/quran_sessions.dart';

/// Fixed-user [AuthSessionProvider] for seeded test blocs.
class FakeAuthSession implements AuthSessionProvider {
  const FakeAuthSession(this.userId);

  final String userId;

  @override
  String? get currentUserId => userId;

  @override
  Stream<String?> watchUserId() => Stream.value(userId);
}
