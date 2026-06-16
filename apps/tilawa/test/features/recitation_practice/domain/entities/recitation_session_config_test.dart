import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/recitation_practice/domain/entities/recitation_session_config.dart';

void main() {
  group('RecitationSessionConfig', () {
    test('defaults include ASR catch-up tuning for fast recitation', () {
      const RecitationSessionConfig config = RecitationSessionConfig.defaults;

      expect(config.asrCatchUpDelay, const Duration(milliseconds: 900));
      expect(config.asrIdleBeforeFail, const Duration(milliseconds: 2800));
      expect(
        config.shortAyahIdleBeforeFail,
        const Duration(milliseconds: 4500),
      );
      expect(config.catchUpScoreFloor, 0.65);
      expect(config.allowSkipAhead, isFalse);
    });
  });
}
