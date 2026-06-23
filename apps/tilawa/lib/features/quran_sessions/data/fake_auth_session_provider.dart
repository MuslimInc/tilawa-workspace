import 'package:quran_sessions/quran_sessions.dart';

/// Fixed UID for fake/local Quran Sessions backend mode.
class FakeAuthSessionProvider implements AuthSessionProvider {
  const FakeAuthSessionProvider({required this.userId});

  final String userId;

  @override
  String? get currentUserId => userId;

  @override
  Stream<String?> watchUserId() => Stream.value(userId);
}
