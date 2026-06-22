import 'package:dartz_plus/dartz_plus.dart';
import 'package:quran_sessions/quran_sessions.dart';

class FakeSessionNotificationGateway implements SessionNotificationGateway {
  QuranSessionsFailure? failWith;
  final List<SessionNotificationCommand> commands = [];

  @override
  Future<Either<QuranSessionsFailure, void>> enqueue(
    SessionNotificationCommand command,
  ) async {
    if (failWith != null) return Left(failWith!);
    commands.add(command);
    return const Right(null);
  }
}
